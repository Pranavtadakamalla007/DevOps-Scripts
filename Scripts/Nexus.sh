#!/bin/bash

#Update packages and install java and wget
sudo apt update -y
sudo apt install wget -y 
sudo apt install openjdk-17-jdk -y

#Creating directories
mkdir -p /tmp/nexus/
cd /tmp/nexus

#Downloading nexus
NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"
wget $NEXUSURL -O nexus.tar.gz

sleep 10

#Extarct nexus
EXTOUT=$(tar xzvf nexus.tar.gz)
NEXUSDIR=$(echo "$EXTOUT" | head -n 1 | cut -d '/' -f1)

sleep 5

#Clean and move nexus
rm -rf /tmp/nexus/nexus.tar.gz
cp -r /tmp/nexus* /opt/

sleep 5

#Create user
useradd nexus
chown -R nexus:nexus /opt/nexus

#Creating a systemd file
cat <<EOT>>/etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

# Configure nexus user in nexus.rc
echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc

#Reload daemon
systemctl daemon-reload

#Enable and start nexus
systemctl enable nexus
systemctl start nexus

