#Installing jenkins debian package
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

#Adding jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

#Updating packages and installing Jenkins
sudo apt-get update -y
sudo apt-get install fontconfig openjdk-21-jdk -y
sudo apt-get install jenkins -y