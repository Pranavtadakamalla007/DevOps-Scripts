#!/bin/bash

# Declaring variables
URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.6.92038.zip
sonar_version=sonarqube-9.9.6.92038
sonar=sonarqube

# Back up sysctl.conf and limits.conf
cp /etc/sysctl.conf /root/sysctl.conf_backup
cp /etc/security/limits.conf /root/limits.conf_backup

# Configure sysctl with required settings
cat <<EOT > /etc/sysctl.conf
vm.max_map_count=524288
fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
EOT

cat <<EOT > /etc/security/limits.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    409
EOT

# Updating packages and installing required Java JDK
sudo apt-get update -y
sudo apt-get install openjdk-17-jdk -y
sudo update-alternatives --config java
java -version

# Installing PostgreSQL
sudo apt update -y
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

# Starting PostgreSQL
sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service

# Set password for postgres user
echo "postgres:admin123" | sudo chpasswd

# Create user and database in PostgreSQL for SonarQube
runuser -l postgres -c "createuser sonar"
sudo -i -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'admin123';"
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

# Restart PostgreSQL service
sudo systemctl restart postgresql.service

# Install net-tools
sudo apt install net-tools -y
netstat -tulpena | grep postgres

# Installing SonarQube
sudo curl -O $URL
sudo apt install zip -y
sudo unzip -o $sonar_version.zip -d /opt/
sudo mv /opt/$sonar_version /opt/$sonar

# Create sonarqube user and group
sudo groupadd sonar
sudo useradd -c "SonarQube - User" -d /opt/$sonar/ -g sonar sonar
sudo chown sonar:sonar /opt/$sonar/ -R
cp /opt/$sonar/conf/sonar.properties /root/sonar.properties_backup

# Configuring sonar properties 
cat <<EOT > /opt/$sonar/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOT

# Configure SonarQube service in systemd as a daemon
cat <<EOT > /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/$sonar/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/$sonar/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOT

# Reload daemon and enable SonarQube service
sudo systemctl daemon-reload
sudo systemctl enable sonarqube.service
sudo systemctl start sonarqube.service

# Installing Nginx and configure SonarQube proxy
sudo apt-get install nginx -y
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default
cat <<EOT > /etc/nginx/sites-available/sonarqube
server {
    listen      80;
    server_name sonarqube.groophy.in;

    access_log  /var/log/nginx/sonar.access.log;
    error_log   /var/log/nginx/sonar.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass  http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;

        proxy_set_header    Host            \$host;
        proxy_set_header    X-Real-IP       \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto http;
    }
}
EOT

# Create symbolic link for SonarQube site and enable Nginx
sudo ln -sf /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
sudo systemctl enable nginx.service
sudo systemctl start nginx.service

# Open ports in firewall
sudo ufw allow 80,9000,9001/tcp

# Reboot system
echo "System reboot in 30 seconds"
sleep 30
reboot
