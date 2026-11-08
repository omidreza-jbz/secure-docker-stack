#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/var/log/cluster-audit.log"

EXIT_CODE=0

Log() {

	local PROCESS_STAT=$1
	local RAW_MSG=$2
	local TIMASTEMP
	TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
	
	echo -e "[$TIMESTAMP] [$PROCESS_STAT] [$RAW_MSG]"
	
	local CLEAN_MSG
	CLEAN_MSG=$(echo -e "$RAW_MSG" | sed 's/\x1b\[[0-9;]*m//g')
	echo "[$TIMESTAMP] [$PROCESS_STAT] $CLEAN_MSG" >> "$LOG_FILE"

}

echo -e "${YELLOW}\n=== Cluster Health & Network Audit ==="


while read -r NAME STAT AVAIL ;do
	if [[ "$STAT" == "Ready" && "$AVAIL" == "Active" ]];then
		Log "OK" "${GREEN}The Node $NAME is: $STAT (Availability:$AVAIL) ${NC}"
	else
		Log "ALERT" "${RED}The Node $NAME is: $STAT (Availability:$AVAIL) ${NC}"
		EXIT_CODE=1
	fi
done < <(docker node ls --format '{{.Hostname}} {{.Status}} {{.Availability}}')

echo -e "\n${YELLOW}[2/3] Validating Service Replicas...${NC}"

while read -r SERVICE_NAME REPLICAS; do
	CURRENT=$(echo "$REPLICAS" | cut -d'/' -f1)

	DESIRED=$(echo "$REPLICAS" | cut -d'/' -f2)

	if [[ $CURRENT -eq $DESIRED ]];then
	
		Log "OK" "${GREEN}Service: $SERVICE_NAME Running Perfectly; Replicas: $REPLICAS ${NC}"

	else
		Log "ALERT" "${RED}Service: $SERVICE_NAME Running Badly; Replicas: $REPLICAS ${NC}"
		EXIT_CODE=1
	fi
done < <(docker service ls --format '{{.Name}} {{.Replicas}}')

echo -e "\n${YELLOW}[3/3] Probing Application Ingress (HTTPS)...${NC}"

HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://localhost || echo "000")

if [[ "$HTTP_CODE" =~ ^(200|301|302)$ ]];then
	Log "OK" "${GREEN}Nginx Ingress is Responding (HTTP $HTTP_CODE) ${NC}"
else
	Log "ALERT" "${RED}Ingress failed or unreachable! (HTTP $HTTP_CODE) ${NC}"
	EXIT_CODE=1
fi

echo -e "\n=== Audit Finished (Exit Code: $EXIT_CODE) ===\n"
exit "$EXIT_CODE"
