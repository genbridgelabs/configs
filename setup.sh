#!/bin/bash
set -e

echo "🔄 Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing system packages: Maven, Java 17, Redis, RabbitMQ, Python3, pip, venv, dos2unix..."
sudo apt install -y openjdk-17-jdk maven redis-server rabbitmq-server python3 python3-pip python3-venv dos2unix nginx certbot python3-certbot-nginx

echo "🔐 Configuring Redis password and port..."
sudo sed -i "s/^# requirepass .*$/requirepass Ui4WLMq0M8EDhfmt1Vts414jsArlkt1S/" /etc/redis/redis.conf
sudo sed -i "s/^port .*$/port 12803/" /etc/redis/redis.conf
sudo systemctl restart redis-server

echo "🐇 Creating RabbitMQ user: ennomart"
sudo rabbitmqctl add_user ennomart ennomart || echo "User may already exist"
sudo rabbitmqctl set_user_tags ennomart administrator
sudo rabbitmqctl set_permissions -p / ennomart ".*" ".*" ".*"

echo "🐍 Setting up Python virtual environment for Flask app..."
sudo mkdir -p /home/runner
sudo chown "$USER":"$USER" /home/runner

python3 -m venv /home/runner/venv
/home/runner/venv/bin/pip install --upgrade pip
/home/runner/venv/bin/pip install flask flask-mail

echo "📁 Creating script directory..."
sudo mkdir -p /home/script
sudo mkdir -p /home/script/approval_server
sudo chown "$USER":"$USER" /home/script

echo "⬇️ Downloading files into /home/script..."
BASE_URL="https://configs.gblinfra.in"

curl -L -o /tmp/deploy_all.sh "$BASE_URL/deploy_all.sh"
curl -L -o /tmp/deploy_project.sh "$BASE_URL/deploy_project.sh"
curl -L -o /tmp/start_jars.sh "$BASE_URL/start_jars.sh"
curl -L -o /home/script/approval_server/app.py "$BASE_URL/approval_server/app.py"

echo "🧹 Converting line endings to Unix format..."
dos2unix /tmp/deploy_all.sh
dos2unix /tmp/deploy_project.sh
dos2unix /tmp/start_jars.sh

echo "🚚 Moving scripts to /home/script..."
sudo mv /tmp/deploy_all.sh /home/script/
sudo mv /tmp/deploy_project.sh /home/script/
sudo mv /tmp/start_jars.sh /home/script/

echo "🔓 Making scripts executable..."
sudo chmod +x /home/script/deploy_all.sh
sudo chmod +x /home/script/deploy_project.sh
sudo chmod +x /home/script/start_jars.sh
sudo chmod +x /home/script/approval_server/app.py

echo "🛠️ Creating systemd service for Flask server..."
sudo tee /etc/systemd/system/flask_build_server.service > /dev/null <<EOF
[Unit]
Description=Flask Build Approval Server
After=network.target

[Service]
User=$USER
WorkingDirectory=/home/script/approval_server
ExecStart=/home/runner/venv/bin/python3 /home/script/approval_server/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "🛠️ Creating systemd service for JAR auto-start..."
sudo tee /etc/systemd/system/start_jars.service > /dev/null <<EOF
[Unit]
Description=Start All Java JARs
After=network.target

[Service]
Type=oneshot
User=$USER
ExecStart=/home/script/start_jars.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

echo "🌐 Configuring Nginx reverse proxy for Flask server (console.gblinfra.in)..."
sudo tee /etc/nginx/sites-available/console.gblinfra.in > /dev/null <<EOF
server {
    listen 80;
    server_name console.gblinfra.in;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "🔗 Enabling Nginx site and reloading..."
sudo ln -sf /etc/nginx/sites-available/console.gblinfra.in /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

echo "🔌 Enabling and starting services..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable flask_build_server.service
sudo systemctl enable start_jars.service
sudo systemctl start flask_build_server.service
sudo systemctl start start_jars.service

echo "🚀 Triggering deploy_all.sh..."
/home/script/deploy_all.sh || echo "⚠️ Failed to run deploy_all.sh manually. Please run it after verifying all files."

echo "✅ Setup complete."
echo "📌 Flask venv: /home/runner/venv"
echo "📬 Flask server service: flask_build_server"
echo "☕ JAR runner service: start_jars"
echo "🌐 Nginx config: /etc/nginx/sites-available/console.gblinfra.in"
echo "🔐 RabbitMQ user: ennomart / ennomart"
echo "🗝️ Redis password: Ui4WLMq0M8EDhfmt1Vts414jsArlkt1S"
echo "🟢 Redis port: 12803"

echo "🔐 To enable HTTPS with Certbot, run:"
echo "    sudo certbot --nginx -d console.gblinfra.in"
