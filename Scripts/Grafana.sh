#Install pre-required packages
sudo apt-get install -y apt-transport-https software-properties-common wget

#Import GPG key
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

#Adding repository
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Updates the list of available packages
sudo apt-get update -y

# Installs the latest OSS release:
sudo apt-get install grafana -y

#Start and enable grafana
sudo /bin/systemctl start grafana-server
sudo /bin/systemctl enable grafana-server
sudo /bin/systemctl status grafana-server --no-pager