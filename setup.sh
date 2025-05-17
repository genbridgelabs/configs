#!/bin/bash

set -e

echo "🔄 Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing required packages: Maven, Java 17, Redis, RabbitMQ, Python3, pip..."
sudo apt install -y openjdk-17-jdk maven redis-server rabbitmq-server python3 python3-pip

echo "🐍 Installing Flask..."
sudo pip3 install flask

echo "📁 Creating required directories: /home/script and /home/runner..."
sudo mkdir -p /home/script /home/runner
sudo chown "$USER":"$USER" /home/script /home/runner

echo "⬇️ Downloading files into /home/script..."

BASE_URL="https://configs.gblinfra.in"

# Downloading files as the current user (to owned dirs), then moving them with sudo if needed
curl -L -o /tmp/deploy_all.sh "$BASE_URL/deploy_all.sh"
curl -L -o /tmp/deploy_project.sh "$BASE_URL/deploy_project.sh"
curl -L -o /tmp/start_jars.sh "$BASE_URL/start_jars.sh"
mkdir -p /tmp/approval_server
curl -L -o /tmp/approval_server/app.py "$BASE_URL/approval_server/app.py"

# Move everything to /home/script with sudo
sudo mv /tmp/deploy_all.sh /home/script/
sudo mv /tmp/deploy_project.sh /home/script/
sudo mv /tmp/start_jars.sh /home/script/
sudo mkdir -p /home/script/approval_server
sudo mv /tmp/approval_server/app.py /home/script/approval_server/

echo "🔓 Making all scripts executable..."
sudo chmod +x /home/script/deploy_all.sh
sudo chmod +x /home/script/deploy_project.sh
sudo chmod +x /home/script/start_jars.sh
sudo chmod +x /home/script/approval_server/app.py

echo "✅ Setup complete with sudo privileges."
