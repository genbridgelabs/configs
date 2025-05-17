#!/bin/bash

RUNNER_DIR="/home/runner"

# Loop through all .jar files in /home/runner
for JAR_FILE in "$RUNNER_DIR"/*.jar; do
  if [[ -f "$JAR_FILE" ]]; then
    PROJECT_NAME=$(basename "$JAR_FILE" .jar)
    LOG_FILE="$RUNNER_DIR/${PROJECT_NAME}_deploy.log"

    echo "Starting $PROJECT_NAME..." | tee -a "$LOG_FILE"
    nohup java -jar "$JAR_FILE" >> "$LOG_FILE" 2>&1 &

    echo "$PROJECT_NAME started. Logs: $LOG_FILE" | tee -a "$LOG_FILE"
  fi
done

echo "All JARs started."
