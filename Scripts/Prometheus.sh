#Declaring variables
URL="https://github.com/prometheus/prometheus/releases/download/v2.54.1/prometheus-2.54.1.linux-amd64.tar.gz"
VERSION="prometheus-2.54.1.linux-amd64"

#Update packages
sudo apt update && apt upgrade -y

#Download and extract prometheus
wget $URL
tar -xvzf $VERSION.tar.gz

#Moving executable files to /usr/local/bin/
sudo mv $VERSION/prometheus /usr/local/bin
sudo mv $VERSION/promtool /usr/local/bin

#Creating directories
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

#Create a prometheus user
useradd --no-create-home --shell /bin/false prometheus

#Move prometheus.yml file
sudo mv $VERSION/prometheus.yml /etc/prometheus

#Give permissions
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus/prometheus.yml


#Creating file in systemd
cat <<EOT>> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.console.templates=/usr/local/bin/consoles \
  --web.console.libraries=/usr/local/bin/console_libraries

[Install]
WantedBy=multi-user.target
EOT

#Reload daemon and start prometheus
sudo systemctl daemon-reload
sudo systemctl start prometheus.service
sudo systemctl enable prometheus.service