#!/bin/bash

PROJECT_NAME=$1
GIT_URL=$2

GIT_USERNAME="chandanpradhan092"
GIT_PASSWORD="8144094480"

if [ -z "$PROJECT_NAME" ] || [ -z "$GIT_URL" ]; then
  echo "Error: Project name or Git URL not provided."
  echo "Usage: ./deploy_project.sh <project_name> <git_url>"
  exit 1
fi

AUTHENTICATED_URL=$(echo "$GIT_URL" | sed "s#https://#https://$GIT_USERNAME:$GIT_PASSWORD@#")

BASE_DIR="/home/application"
RUNNER_DIR="/home/runner"
LOG_FILE="$RUNNER_DIR/${PROJECT_NAME}_deploy.log"

# Function to log messages with date and time in IST format
log_message() {
  local MESSAGE="$1"
  echo "$(TZ='Asia/Kolkata' date +"%Y-%m-%d %H:%M:%S %Z") | $PROJECT_NAME | $MESSAGE" | tee -a "$LOG_FILE"
}

log_message "Starting deployment for $PROJECT_NAME on branch dev."

if [ ! -d "$BASE_DIR/$PROJECT_NAME" ]; then
  log_message "Project directory not found. Cloning repository from branch dev..."
  git clone -b main "$AUTHENTICATED_URL" "$BASE_DIR/$PROJECT_NAME" || { log_message "Error: Failed to clone repository for $PROJECT_NAME"; exit 1; }
  cd "$BASE_DIR/$PROJECT_NAME" || { log_message "Error: Failed to navigate to project directory for $PROJECT_NAME"; exit 1; }
else
  cd "$BASE_DIR/$PROJECT_NAME" || { log_message "Error: Failed to navigate to project directory for $PROJECT_NAME"; exit 1; }
  log_message "Project directory found. Pulling latest changes from branch dev..."

  # Use the authenticated URL for git pull
  if ! git pull "$AUTHENTICATED_URL" main; then
    log_message "Normal git pull failed. Retrying with --allow-unrelated-histories..."
    if ! git pull "$AUTHENTICATED_URL" main --allow-unrelated-histories; then
      log_message "Error: Git pull failed for $PROJECT_NAME. Removing the directory and re-cloning..."
      cd "$BASE_DIR" || exit 1
      rm -rf "$PROJECT_NAME"
      git clone -b main "$AUTHENTICATED_URL" "$BASE_DIR/$PROJECT_NAME" || { log_message "Error: Failed to re-clone repository for $PROJECT_NAME"; exit 1; }
      cd "$BASE_DIR/$PROJECT_NAME" || { log_message "Error: Failed to navigate to project directory for $PROJECT_NAME"; exit 1; }
    fi
  fi
fi

if [ -f "pom.xml" ]; then
  log_message "Building Java project: $PROJECT_NAME..."
  mvn clean install || { log_message "Error: Maven build failed for $PROJECT_NAME"; exit 1; }

  cd target || { log_message "Error: Target folder not found for $PROJECT_NAME"; exit 1; }
  JAR_FILE=$(ls "$PROJECT_NAME"*.jar 2>/dev/null | head -n 1)

  if [ -z "$JAR_FILE" ]; then
    log_message "Error: JAR file not found for $PROJECT_NAME."
    exit 1
  fi

  log_message "Deploying JAR: $JAR_FILE..."
  cp "$JAR_FILE" "$RUNNER_DIR/$PROJECT_NAME.jar"

  log_message "Checking for running processes for $PROJECT_NAME..."
  PID=$(ps aux | grep "[j]ava -jar $RUNNER_DIR/$PROJECT_NAME.jar" | awk '{print $2}')
  if [ -n "$PID" ]; then
    log_message "Killing running process with PID $PID..."
    kill -9 "$PID" || { log_message "Error: Failed to kill process for $PROJECT_NAME"; exit 1; }
  else
    log_message "No running process found for $PROJECT_NAME."
  fi

  nohup java -jar "$RUNNER_DIR/$PROJECT_NAME.jar" > "$LOG_FILE" 2>&1 &
else
  log_message "Error: Unrecognized project type for $PROJECT_NAME."
  exit 1
fi

log_message "Deployment completed for $PROJECT_NAME."
