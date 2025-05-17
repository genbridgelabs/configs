#!/bin/bash

echo "=== Setup started ==="

# Install required system packages
echo "Installing Python3 venv and dependencies..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip

# Create Python virtual environment and install Flask
APP_DIR="/home/application"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

if [ ! -d "venv" ]; then
  echo "Creating python virtual environment..."
  python3 -m venv venv
fi

echo "Installing required python packages in virtualenv..."
source venv/bin/activate
pip install --upgrade pip
pip install flask flask-mail
deactivate

# Create systemd service for Flask server
echo "Creating systemd service for Flask server..."
sudo tee /etc/systemd/system/flask_build_server.service > /dev/null <<EOF
[Unit]
Description=Flask Build Server
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python3 $APP_DIR/server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for starting JARs
echo "Creating systemd service for starting JARs..."
sudo tee /etc/systemd/system/start_jars.service > /dev/null <<EOF
[Unit]
Description=Start All JARs
After=network.target

[Service]
Type=simple
ExecStart=/home/script/start_jars.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the services
echo "Enabling and starting services..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable flask_build_server.service
sudo systemctl enable start_jars.service
sudo systemctl restart flask_build_server.service
sudo systemctl restart start_jars.service

# Optional: run deploy_all.sh if present
if [ -f /home/script/deploy_all.sh ]; then
    echo "Triggering deploy_all.sh..."
    chmod +x /home/script/deploy_all.sh
    /home/script/deploy_all.sh
else
    echo "WARNING: /home/script/deploy_all.sh not found. Skipping auto-deploy trigger."
fi

echo "=== Setup completed ==="
