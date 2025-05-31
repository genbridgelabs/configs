#!/bin/bash

APP_DIR="/home/application/gbsap-backend"
APP_NAME="gbsap-backend"

echo "📁 Navigating to app directory..."
cd "$APP_DIR" || { echo "❌ App directory not found!"; exit 1; }

echo "🔄 Pulling latest code from GitHub..."
git pull origin main || { echo "❌ Git pull failed."; exit 1; }

echo "📦 Installing updated dependencies..."
npm install

echo "🔁 Restarting app with PM2..."
pm2 restart "$APP_NAME"

echo "✅ Update complete!"
