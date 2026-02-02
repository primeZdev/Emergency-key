#!/bin/bash

# Clone the repository
cd /opt/
if [ -d "Emergency-key" ]; then
    cd Emergency-key
else
    git clone https://github.com/primeZdev/Emergency-key.git
    cd Emergency-key
fi

# Config files
touch keys.txt
cp .env.example .env

read -p "Enter PORT for app (default 3000): " PORT
PORT=${PORT:-3000}
read -p "Enter API_KEY: " API_KEY
read -p "Enter DOMAIN: " DOMAIN

echo "PORT=$PORT" > .env
echo "API_KEY=$API_KEY" >> .env
echo "DOMAIN=$DOMAIN" >> .env

# Install Caddy if not installed
if ! command -v caddy &> /dev/null; then
    apt update && apt install -y debian-archive-keyring apt-transport-https curl gnupg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    tee /etc/apt/sources.list.d/caddy-stable.list <<EOF
deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main
deb-src [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main
EOF
    apt update
    apt install -y caddy

fi

# Create systemd service for app
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

# Create CLI em-keys
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

systemctl daemon-reload
systemctl enable em-key.service
systemctl start em-key.service

# Create Caddyfile
cat <<EOL > /etc/caddy/Caddyfile
$DOMAIN {
    reverse_proxy localhost:$PORT
}
EOL

# Restart Caddy to apply configuration
systemctl enable --now caddy
systemctl reload caddy
echo "Installation complete."

echo "Caddy is handling HTTPS on https://$DOMAIN/$API_KEY"


echo "Installation complete. Use 'em-keys edit-keys' to edit your v2ray keys."
