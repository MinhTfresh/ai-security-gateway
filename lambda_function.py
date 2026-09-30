import os
import time
import json
import boto3

waf_client = boto3.client("wafv2", region_name="us-east-1")
logs_client = boto3.client("logs", region_name="us-east-1")

def lambda_handler(event, context):
    log_group = os.environ["LOG_GROUP_NAME"]
    ip_set_id = os.environ["WAF_IP_SET_ID"]
    ip_set_name = os.environ["WAF_IP_SET_NAME"]
    ip_set_arn = os.environ["WAF_IP_SET_ARN"]
    
    print("🚨 Security Alarm Triggered! Scanning API CloudWatch Logs for malicious IPs...")
    
    # 1. Search logs from the past 3 minutes looking for structural injection blocks
    now_ms = int(time.time() * 1000)
    three_min_ago_ms = now_ms - (3 * 60 * 1000)
    
    response = logs_client.filter_log_events(
        logGroupName=log_group,
        startTime=three_min_ago_ms,
        filterPattern='{ $.event_type = "PROMPT_INJECTION_DETECTED" }'
    )
    
    malicious_ips = set()
    for event in response.get("events", []):
        try:
            log_payload = json.loads(event["message"])
            ip_address = log_payload.get("ip_address")
            if ip_address:
                # AWS WAF expects valid CIDR format notation
                malicious_ips.add(f"{ip_address}/32")
        except json.JSONDecodeError:
            continue
            
    if not malicious_ips:
        print("ℹ️  No specific attacker IP found within the evaluation window log blocks.")
        return {"status": "no_action"}
        
    print(f"🎯 Target Attacker IPs identified for perimeter eviction: {malicious_ips}")
    
    # 2. Fetch the existing live IP Set from AWS WAF to avoid overwriting current locks
    ip_set_data = waf_client.get_ip_set(
        Name=ip_set_name,
        Scope="REGIONAL",
        Id=ip_set_id
    )
    
    current_addresses = set(ip_set_data["IPSet"].get("Addresses", []))
    lock_token = ip_set_data["LockToken"] # Required by AWS to prevent concurrent transaction corruption
    
    # Merge existing list with the newly discovered attacker targets
    updated_addresses = list(current_addresses.union(malicious_ips))
    
    # 3. Commit the updated list back to the AWS WAF edge firewall
    waf_client.update_ip_set(
        Name=ip_set_name,
        Scope="REGIONAL",
        Id=ip_set_id,
        Addresses=updated_addresses,
        LockToken=lock_token
    )
    
    print(f"🔒 Perimeter Shield Updated! Successfully blocked {len(malicious_ips)} attacker IPs globally.")
    return {"status": "success", "blocked_ips": updated_addresses