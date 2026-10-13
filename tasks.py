# Copyright 2026 MinhTFresh. All Rights Reserved.
# Licensed under the Apache License, Version 2.0.

import json
import logging
import os
import re
import time
from logging.handlers import RotatingFileHandler

import docker
from celery import Celery

from alerts import dispatch_incident_alarm

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
celery_app = Celery("tasks", broker=REDIS_URL, backend=REDIS_URL)

# More robust detection: block common dangerous patterns
DENIED_PATTERNS = (
    r"(?i)\b(os\.system|subprocess|shutil|eval\s*\(|exec\s*\(|open\s*\(|io\.)\b",
    r"(?i)\b(__import__|globals\s*\(|locals\s*\(|getattr\s*\(|setattr\s*\()\b",
)

worker_logger = logging.getLogger("AI_Worker_Audit")
worker_logger.setLevel(logging.INFO)
os.makedirs("logs", exist_ok=True)
handler = RotatingFileHandler(
    "logs/ai_gateway_security.log",
    maxBytes=10 * 1024 * 1024,
    backupCount=5,
)
handler.setFormatter(logging.Formatter("%(message)s"))
worker_logger.addHandler(handler)


def _contains_dangerous_code(code: str) -> bool:
    return any(re.search(pattern, code) for pattern in DENIED_PATTERNS)


@celery_app.task(name="tasks.execute_tool_sandbox_async")
def execute_tool_sandbox_async(code: str, user_id: str) -> str:
    start_time = time.time()
    user_id = str(user_id or "unknown")

    if not isinstance(code, str) or not code.strip():
        return "Invalid input: code must be a non-empty string."

    if _contains_dangerous_code(code):
        payload = {
            "timestamp": time.time(),
            "event_type": "SANDBOX_VIOLATION",
            "user_id": user_id,
            "status": "BLOCKED",
        }
        worker_logger.info(json.dumps(payload))
        dispatch_incident_alarm(
            "SANDBOX_ESCAPE_VIOLATION",
            user_id,
            "HIGH",
            {"blocked_payload_preview": code[:256]},
        )
        return "Security Violation: Prohibited code patterns detected."

    container = None
    try:
        client = docker.from_env()
        container = client.containers.run(
            image="python:3.11-slim",
            command=["python", "-I", "-c", code],
            network_disabled=True,
            mem_limit=os.getenv("SANDBOX_MEM_LIMIT", "256m"),
            nano_cpus=250_000_000,
            read_only=True,
            user="nobody",
            detach=True,
            remove=False,
            cap_drop=["ALL"],
            security_opt=["no-new-privileges"],
            pids_limit=64,
        )

        status = container.wait(timeout=4)
        logs = container.logs(stdout=True, stderr=True).decode("utf-8", errors="replace")

        worker_logger.info(
            json.dumps(
                {
                    "timestamp": time.time(),
                    "event_type": "SANDBOX_EXECUTION_COMPLETED",
                    "user_id": user_id,
                    "status": "SUCCESS",
                    "metrics": {
                        "duration": time.time() - start_time,
                        "exit_code": status.get("StatusCode", -1),
                    },
                }
            )
        )

        if status.get("StatusCode") == 0:
            return logs
        return f"Execution Error:\n{logs}"

    except Exception as exc:
        worker_logger.info(
            json.dumps(
                {
                    "timestamp": time.time(),
                    "event_type": "SANDBOX_EXCEPTION",
                    "user_id": user_id,
                    "status": "CRASHED",
                    "error": str(exc),
                }
            )
        )
        return f"Sandbox Intercept Action: Task terminated or resource limit hit. ({exc})"

    finally:
        if container is not None:
            try:
                container.remove(force=True)
            except Exception:
                pass
