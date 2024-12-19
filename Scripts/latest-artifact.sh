#This script is for selecting the latest artifact for the application daemon 

#!/bin/bash

ARTIFACT_DIR="/home/ec2-user"

LATEST_JAR=$(ls -t $ARTIFACT_DIR/*.jar | head -n 1)

ln -sf "$LATEST_JAR" "$ARTIFACT_DIR/latest_artifact.sh"


#Daemon configuration

[Unit]
Description=Java Application

[Service]
ExecStart=/usr/bin/java -jar /home/ec2-user/latest_artifact.sh
WorkingDirectory=/home/ec2-user
StandardOutput=append:/home/ec2-user/output.log
StandardError=append:/home/ec2-user/output.log
Restart=always
User=ec2-user
Group=ec2-user

[Install]
WantedBy=multi-user.target


add a cronjob:
crontab -e
add this 
@reboot /home/ec2-user/latest_artifact.sh
