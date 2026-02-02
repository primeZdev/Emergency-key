#!/bin/bash

# Clone the repository from GitHub
cd /opt/
git clone https://github.com/yourusername/Emergency-key.git

cd Emergency-key

# Create keys.txt file for user configs
touch keys.txt
echo "Please paste your configs into keys.txt file."

cp .env.example .env

read -p "Enter PORT (default 3000): " PORT
PORT=${PORT:-3000}
read -p "Enter API_KEY: " API_KEY

echo "PORT=$PORT" > .env
echo "API_KEY=$API_KEY" >> .env

# Run the main file
./main &

# Create a service for managing the application
cat <<EOL > /etc/systemd/system/em-key.service
[Unit]
Description=Emergency Key Service

[Service]
ExecStart=/opt/Emergency-key/main
Restart=always

[Install]
WantedBy=multi-user.target
EOL

systemctl enable em-key

echo "Service installed. To start the service, run: systemctl start em-key"

cat <<EOL > /usr/local/bin/em-key
#!/bin/bash

case "$1" in
    restart)
        systemctl restart em-key
        ;;  
    update)
        cd /opt/Emergency-key && git pull
        ;;  
    stop)
        systemctl stop em-key
        ;;  
    uninstall)
        systemctl stop em-key
        systemctl disable em-key
        rm -rf /opt/Emergency-key
        rm /usr/local/bin/em-key
        ;;  
    *)
        echo "Usage: em-key {restart|update|stop|uninstall}"
        exit 1
        ;;
esac
EOL

chmod +x /usr/local/bin/em-key
