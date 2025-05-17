#!/bin/bash
set -e

echo "🔄 Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing system packages: Maven, Java 17, Redis, RabbitMQ, Python3, pip, venv..."
sudo apt install -y openjdk-17-jdk maven redis-server rabbitmq-server python3 python3-pip python3-venv curl

echo "🐍 Setting up Python virtual environment for Flask app..."
sudo mkdir -p /home/runner
sudo chown "$USER":"$USER" /home/runner

python3 -m venv /home/runner/venv
/home/runner/venv/bin/pip install --upgrade pip
/home/runner/venv/bin/pip install flask flask-mail

echo "📁 Creating script directory..."
sudo mkdir -p /home/script
sudo chown "$USER":"$USER" /home/script

echo "⬇️ Downloading files into /home/script..."
BASE_URL="https://configs.gblinfra.in"

curl -L -o /tmp/deploy_all.sh "$BASE_URL/deploy_all.sh"
curl -L -o /tmp/deploy_project.sh "$BASE_URL/deploy_project.sh"
curl -L -o /tmp/start_jars.sh "$BASE_URL/start_jars.sh"
mkdir -p /tmp/approval_server
curl -L -o /tmp/approval_server/app.py "$BASE_URL/approval_server/app.py"

sudo mv /tmp/deploy_all.sh /home/script/
sudo mv /tmp/deploy_project.sh /home/script/
sudo mv /tmp/start_jars.sh /home/script/
sudo mkdir -p /home/script/approval_server
sudo mv /tmp/approval_server/app.py /home/script/approval_server/

echo "🔓 Making scripts executable..."
sudo chmod +x /home/script/deploy_all.sh
sudo chmod +x /home/script/deploy_project.sh
sudo chmod +x /home/script/start_jars.sh
sudo chmod +x /home/script/approval_server/app.py

echo "🛠️ Creating systemd service for Flask server..."
sudo tee /etc/systemd/system/flask_build_server.service > /dev/null <<EOF
[Unit]
Description=Flask Build Server
After=network.target

[Service]
User=root
WorkingDirectory=/home/script/approval_server
ExecStart=/home/runner/venv/bin/python3 /home/script/approval_server/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "🛠️ Creating systemd service for starting JARs..."
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

echo "🚀 Enabling and starting services..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable flask_build_server.service
sudo systemctl enable start_jars.service
sudo systemctl restart flask_build_server.service
sudo systemctl restart start_jars.service

# Optional: run deploy_all.sh if present
if [ -f /home/script/deploy_all.sh ]; then
    echo "🚀 Triggering deploy_all.sh..."
    chmod +x /home/script/deploy_all.sh
    /home/script/deploy_all.sh
else
    echo "⚠️ WARNING: /home/script/deploy_all.sh not found. Skipping auto-deploy trigger."
fi

echo "✅ Setup complete."
echo "📌 Python venv created at: /home/runner/venv"
echo "👉 To activate: source /home/runner/venv/bin/activate"
echo "📬 Flask-Mail and Flask installed inside venv."
