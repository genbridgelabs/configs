#!/bin/bash

# === CONFIGURATION ===
GITHUB_TOKEN="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"  # 🔐 Replace this with your GitHub token
GITHUB_REPO="https://$GITHUB_TOKEN@github.com/GenBridge-Labs/gbsap-backend.git"
APP_NAME="gbsap-backend"
APP_DIR="/home/application/gbsap-backend"  # Change path if needed 
DOMAIN="gbsap.gblinfra.in"
NODE_PORT=3000                       # Change if your app uses a different port
ENTRY_POINT="app.js"                 # Change if your app has a different entry point

# === SYSTEM SETUP ===
echo "🔧 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "🔧 Installing Node.js, PM2, and Nginx..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs nginx git
sudo npm install -g pm2

# === CLONE PRIVATE REPO ===
if [ -d "$APP_DIR" ]; then
  echo "📁 Directory already exists: $APP_DIR"
else
  echo "🔄 Cloning private repository..."
  git clone "$GITHUB_REPO" "$APP_DIR" || { echo "❌ Git clone failed."; exit 1; }
fi

cd "$APP_DIR" || { echo "❌ Cannot access $APP_DIR"; exit 1; }

# === INSTALL DEPENDENCIES ===
echo "📦 Installing dependencies..."
npm install

# === START APP WITH PM2 ===
echo "🚀 Starting Node.js app with PM2..."
pm2 start "$ENTRY_POINT" --name "$APP_NAME"
pm2 save
pm2 startup --silent

# === SETUP NGINX ===
echo "🌐 Configuring Nginx for $DOMAIN..."
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
sudo tee "$NGINX_CONF" > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$NODE_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# === OPTIONAL SSL SETUP ===
echo "🔒 Do you want to enable SSL with Let's Encrypt for $DOMAIN? [y/N]"
read -r enable_ssl
if [[ "$enable_ssl" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  sudo apt install certbot python3-certbot-nginx -y
  sudo certbot --nginx -d "$DOMAIN"
fi

echo "✅ Setup complete! App should be running at http://$DOMAIN"
