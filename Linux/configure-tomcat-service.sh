#!/bin/bash

#######################################
# Script Name: configure-tomcat-service.sh
# Description: This script sets up Apache Tomcat as a systemd service.
# It creates the tomcat.service file, reloads the systemd daemon,
# enables the Tomcat service, and checks its status.
# Finally, it self-deletes the script file.
#######################################

# Create the file /etc/systemd/system/tomcat.service
sudo tee /etc/systemd/system/tomcat.service >/dev/null <<EOF
# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
Environment=CATALINA_PID=/home/ubuntu/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/home/ubuntu/tomcat
Environment=CATALINA_BASE=/home/ubuntu/tomcat
ExecStart=/home/ubuntu/tomcat/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID
User=ytuhkqt
Group=ytuhkqt
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable tomcat service
sudo systemctl enable tomcat.service

# Check the status of the tomcat service
systemctl status tomcat.service

# Self-delete the script
SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_NAME=$(basename "$0")
rm "$SCRIPT_PATH/$SCRIPT_NAME"