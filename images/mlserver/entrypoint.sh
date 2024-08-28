#!/usr/bin/env bash 

set -eux

LOGSHIPPER_ENABLED=${LOGSHIPPER_ENABLED:-false}
LOGS_REDIRECT=${LOGS_REDIRECT:-all}
SERVICE_ID=${SERVICE_ID:-kserve-container}
LOG_FORMAT=${LOG_FORMAT:-json}
LOG_FILE=${LOG_FILE:-/logs/model.log}
LOG_ROTATE=${LOG_ROTATE:-10}
LOG_SIZE=${LOG_SIZE:-10}

start_mlserver(){
    mlserver start "$MLSERVER_MODELS_DIR"
}


if [ "$LOGSHIPPER_ENABLED" = "true" ]; then
    start_mlserver 2>&1 | /opt/stdout-redirect -redirect "$LOGS_REDIRECT" -service-id "$SERVICE_ID" -format "$LOG_FORMAT" -logfile "$LOG_FILE" -rotate "$LOG_ROTATE" -size "$LOG_SIZE"
else
    start_mlserver 
fi