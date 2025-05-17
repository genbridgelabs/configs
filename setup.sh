#!/bin/bash

set -e

echo "=== Setup started ==="

# Variables
APP_DIR="/home/application"        # Adjust if your app.py is elsewhere
SCRIPT_DIR="/home/script"          # Your scripts location
RUNNER_DIR="/home/runner"          # For start_jars.sh
VENV_DIR="$APP_DIR/venv"
PYTHON_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip"

# 1. Update and install python3-venv if not present
echo "Installing Python3 venv and dependencies..."
sudo apt-get update
sudo apt-get install -y python3 python3-venv python3-pip

# 2. Create virtual environment (if not exists)
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating python virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# 3. Activate venv and install python packages
echo "Installing required python packages in virtualenv..."
"$PIP_BIN" install --upgrade pip
"$PIP_BIN" install flask flask-mail

# 4. Create systemd service for Flask server
echo "Creating systemd service for Flask server..."

sudo tee /etc/systemd/system/flask_build_server.service > /dev/null <<EOF
[Unit]
Description=Flask Build Server
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$APP_DIR
Environment=PATH=$VENV_DIR/bin
ExecStart=$PYTHON_BIN $APP_DIR/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 5. Create systemd service for start_jars.sh
echo "Creating systemd service for starting JARs..."

sudo tee /etc/systemd/system/start_jars.service > /dev/null <<EOF
[Unit]
Description=Start JARs Service
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/start_jars.sh
Restart=no

[Install]
WantedBy=multi-user.target
EOF

# 6. Make sure start_jars.sh is executable
chmod +x "$SCRIPT_DIR/start_jars.sh"

# 7. Reload systemd daemon and enable services
echo "Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable flask_build_server.service
sudo systemctl start flask_build_server.service

sudo systemctl enable start_jars.service
sudo systemctl start start_jars.service

echo "=== Setup completed ==="

# 8. Trigger deploy_all.sh now
echo "Triggering deploy_all.sh..."
chmod +x "$SCRIPT_DIR/deploy_all.sh"
"$SCRIPT_DIR/deploy_all.sh"

echo "Deploy_all.sh execution finished."
echo "Use 'sudo systemctl status flask_build_server.service' to check Flask server status."
echo "Use 'sudo systemctl status start_jars.service' to check JARs starter status."
