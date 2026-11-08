#!/bin/bash

set -euo pipefail

BACKUP_DIR="/root/backup/postgres"
TIMESTEMP=$(date +"%Y%m%d_%H%M%S")
CONTAINER_ID=$(docker ps | grep postgres | awk '{print $1}')
DB_USER=omid
DB_NAME=mydatabase
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTEMP}.sql.gz"
BACKUP_CYCLE_DAYS=7

echo "=== STARTING ==="

if [[ ! -d "$BACKUP_DIR" ]]; then
	echo "[INFO] Creating backup directory"
	mkdir -p "$BACKUP_DIR"
fi

if [[ -z "$CONTAINER_ID" ]]; then
	echo "[ERROR] this container does not exist">&2
	exit 1
else
	echo "[INFO] container found!"
	echo "[INFO] starting backup proccess"
	docker exec -i $CONTAINER_ID pg-dump -U $DB_USER -d $DB_NAME | gzip > "$BACKUP_FILE"
fi

if [[ -s "$BACKUP_FILE" ]];then
	FILE_SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')
	echo "[SUCCESS] backup proccess was SUCCESSFUL, backup file size: $FILE_SIZE"
else
	echo "[ERROR] backup proccess has failed, backup file is empty"
	rm -f "$BACKUP_FILE"
	exit 1
fi

echo "[INFO] Cleaning Backup files older than $BACKUP_CYCLE_DAYS"
find "BACKUP_DIR" -f -name "{$DB_NAME}_*.sql.gz" -mtime +"$BACKUP_CYCLE_DAYS" -exec rm -f {} /;

echo "=== FINISHED ==="


