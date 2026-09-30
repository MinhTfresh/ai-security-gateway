# Copyright 2026 MinhTfresh. All Rights Reserved.
# Licensed under the Apache License, Version 2.0.

import os
import re
import time
import json
import logging
from logging.handlers import RotatingFileHandler
import docker
from celery import Celery
from alerts import dispatch_incident_alarm

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
celery_app = Celery("tasks", broker=REDIS_URL, backend=REDIS_URL)

DENIED_KEYWORDS = re.compile(r"(os\.system|subprocess|shutil|eval\s*\(|open\s*\(|io\.)", re.IGNORECASE)

worker_logger = logging.getLogger("AI_Worker_Audit")
worker_logger.setLevel(logging.INFO)
os.makedirs("logs", exist_ok=True)
worker_logger.addHandler(RotatingFileHandler("logs/ai_gateway_security.log", maxBytes=10*1024*1024, backupCount=5))

@celery_app.task(name="tasks.execute_tool_sandbox_async")
def execute_tool_sandbox_async(code: str, user_id: str) -> str:
    start_time = time.time()
    
    if DENIED_KEYWORDS.search(code):
        log_payload = {"timestamp": time.time(), "event_type": "SANDBOX_VIOLATION", "user_id": user_id, "status": "BLOCKED"}
        worker_logger.info(json.dumps(log_payload))
        dispatch_incident_alarm("SANDBOX_ESCAPE_VIOLATION", user_id, "HIGH", {"blocked_payload": code})
        return "Security Violation: Prohibited code patterns detected at worker validation layer."

    try:
        client = docker.from_env()
        container = client.containers.run(
            image="python:3.11-slim",
            command=["python", "-c", code],
            network_mode="none",
            mem_limit="64m",
            nano_cpus=250000000,
            read_only=True,
            user="nobody",
            detach=True
        )

        status = container.wait(timeout=4.0)
        logs = container.logs(stdout=True, stderr=True).decode("utf-8")
        container.remove(force=True)
        
        worker_logger.info(json.dumps({
            "timestamp": time.time(),
            "event_type": "SANDBOX_EXECUTION_COMPLETED",
            "user_id": user_id,
            "status": "SUCCESS",
            "metrics": {"duration": time.time() - start_time, "exit_code": status["StatusCode"]}
        }))
        return logs if status["StatusCode"] == 0 else f"Execution Error:\n{logs}"

    except Exception as e:
        worker_logger.info(json.dumps({"timestamp": time.time(), "event_type": "SANDBOX_EXCEPTION", "user_id": user_id, "status": "CRASHED"}))
        return f"Sandbox Intercept Action: Task terminated or resource limit hit. ({str(e)})"
