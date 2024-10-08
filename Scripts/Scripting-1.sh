#!/bin/bash

#Declaring variables
URL="https://www.tooplate.com/zip-templates/2137_barista_cafe.zip"
FILE_NAME="2137_barista_cafe"
FILE_TYPE="zip"
TEMP_DIR="/tmp/websitefiles"
APACHE_DIR="/var/www/html"

#Installing wget and unzip
echo "Install wget and unzip"
sudo apt install -y wget unzip > /dev/null
echo
echo "######################################################"

#Installing apache
echo
echo"Installing apache"
sudo apt update -y >/dev/null
sudo apt install apache2 -y > /dev/null
systemctl start apache2
echo
echo "#####################################################"

#Getting website link and unzipping it
echo
mkdir -p $TEMP_DIR
cd $TEMP_DIR
wget $URL >/dev/null
unzip $FILE_NAME.$FILE_TYPE > /dev/null
echo
echo "######################################################"

#Copying files 
echo
echo "Copying files"
sudo cp -r $FILE_NAME/* $APACHE_DIR > /dev/null
echo
echo "##########################################################"

#Restarting apache
echo
echo "Restarting apache"
systemctl restart apache2
echo
echo "###########################################################"

#Cleaning files
echo
echo "Cleaing files"
rm -rf $TEMP_DIR
echo
echo "Deployement completed!"
