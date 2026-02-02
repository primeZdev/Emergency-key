#!/bin/bash

# Clone the repository from GitHub
cd /opt/
if [ -d "Emergency-key" ]; then
    cd Emergency-key
else
    git clone https://github.com/primeZdev/Emergency-key.git
    cd Emergency-key
fi

# Create keys.txt file for user configs
touch keys.txt
cp .env.example .env

read -p "Enter PORT (default 3000): " PORT
PORT=${PORT:-3000}
read -p "Enter API_KEY: " API_KEY
read -p "Enter DOMAIN (for HTTPS certificate, leave empty for self-signed): " DOMAIN

echo "PORT=$PORT" > .env
echo "API_KEY=$API_KEY" >> .env
echo "DOMAIN=$DOMAIN" >> .env
# Install certbot if not installed
if ! command -v certbot &> /dev/null; then
    apt update && apt install -y certbot
fi
# Get certificate
certbot certonly --standalone -d $DOMAIN --agree-tos --email admin@gmail.com -n


# Create systemd service
cat <<EOL > /etc/systemd/system/em-key.service
[Unit]
Description=Emergency Key Service
After=network.target

[Service]
WorkingDirectory=/opt/Emergency-key
ExecStart=/opt/Emergency-key/main
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Create a service for managing the application
cat <<'EOL' > /usr/local/bin/em-keys
#!/bin/bash

SERVICE="em-key"
APP_DIR="/opt/Emergency-key"

case "$1" in
    restart)
        systemctl restart $SERVICE
        ;;
    update)
        cd $APP_DIR && git pull && systemctl restart $SERVICE
        ;;
    edit-keys)
        nano $APP_DIR/keys.txt
        systemctl restart $SERVICE
        ;;
    stop)
        systemctl stop $SERVICE
        ;;
    uninstall)
        systemctl stop $SERVICE
        systemctl disable $SERVICE
        rm -f /etc/systemd/system/${SERVICE}.service
        systemctl daemon-reload
        rm -rf $APP_DIR
        rm -f /usr/local/bin/em-keys
        ;;
    *)
        echo "Usage: em-keys {restart|update|edit-keys|stop|uninstall}"
        exit 1
        ;;
esac
EOL

chmod +x /usr/local/bin/em-keys

# Run
systemctl daemon-reload
systemctl enable em-key.service
systemctl start em-key.service

echo "Installation complete. Use 'em-keys edit-keys' to edit your v2ray keys."
