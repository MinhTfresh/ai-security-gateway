#!/bin/bash
CONTAINER_NAME="ai-security-gateway_redis-broker_1"
REDIS_DATA_DIR="./redis_data"
BACKUP_DEST="./gateway_logs/redis_backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MAX_BACKUP_AGE_DAYS=7

mkdir -p "${BACKUP_DEST}"
docker exec "${CONTAINER_NAME}" redis-cli BGSAVE
sleep 3

if [ -f "${REDIS_DATA_DIR}/dump.rdb" ]; then
    cp "${REDIS_DATA_DIR}/dump.rdb" "${BACKUP_DEST}/redis_state_${TIMESTAMP}.rdb"
    find "${BACKUP_DEST}" -name "redis_state_*.rdb" -type f -mtime +${MAX_BACKUP_AGE_DAYS} -delete
else
    exit 1
fi
