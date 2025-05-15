#!/bin/bash


# Update system
sudo apt-get update -y
sudo apt-get install -y default-mysql-client

#remove old node version
sudo apt remove nodejs -y

# Install NodeSource Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js (replace if you're using another runtime)
sudo apt-get install -y nodejs
sudo apt-get install -y git

# Create app directory
sudo mkdir -p /opt/gallery-app
cd /opt/gallery-app

# Clone the application from GitHub (replace with your repository URL)
sudo git clone https://github.com/afeeney9/photogallery.git .

# Install app dependencies
sudo npm install 

# Install @google-cloud/sql-connector (if necessary)
sudo npm install @google-cloud/cloud-sql-connector

# Set environment variables for DB connection (use your Cloud SQL configuration)
export DB_HOST=(terraform output -raw db_private_ip)
export DB_USER=root
export DB_NAME=gallerydb

# Optional: Initialize database (skip if app auto-connects)
mysql -h "${db_private_ip}" -u root -p gallerydb < schema.sql

# Create systemd service to auto-start app
sudo tee /etc/systemd/system/gallery-app.service > /dev/null <<EOF
[Unit]
Description=Gallery Web App
After=network.target

[Service]
Environment=NODE_ENV=production
WorkingDirectory=/opt/gallery-app
ExecStart=/usr/bin/node /opt/gallery-app/serverv5.js
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF


# Enable and start the service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable gallery-app
sudo systemctl start gallery-app
