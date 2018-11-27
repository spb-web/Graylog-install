#!/usr/bin/env bash

# Update repository
echo ""
echo "*** Running apt update command ***"
echo ""

apt update

# Upgrade packages
echo ""
echo "*** Running apt upgrade command ***"
echo ""
apt upgrade -y

# Install necessary packages for complete graylog setup
echo ""
echo "*** Installing necessary packages ***"
echo ""
apt -y install apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen net-tools

# Install Elasticsearch locally
echo ""
echo "Would you like Elasticsearch installed locally?"
echo "   1) Yes"
echo "   2) No"

until [[ "$INSTALL_ELASTICSEARCH" =~ ^[1-2]$ ]]; do
  read -rp "Select an option [1-2]: " -e -i 1 INSTALL_ELASTICSEARCH
done

if [[ $INSTALL_ELASTICSEARCH = "1" ]]; then
  echo ""
  echo "*** Installing Elasticsearch ***"
  echo ""

  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.5.1.deb
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.5.1.deb.sha512
  shasum -a 512 -c elasticsearch-6.5.1.deb.sha512
  dpkg -i elasticsearch-6.5.1.deb

  sed -i 's|cluster.name: elasticsearch$|cluster.name: graylog|' /etc/elasticsearch/elasticsearch.yml

  systemctl daemon-reload
  systemctl enable elasticsearch.service
  systemctl restart elasticsearch.service
fi

# Install MongoDB locally
echo ""
echo "Would you like MongoDB installed locally?"
echo "   1) Yes"
echo "   2) No"

until [[ "$INSTALL_MONGODB" =~ ^[1-2]$ ]]; do
  read -rp "Select an option [1-2]: " -e -i 1 INSTALL_MONGODB
done

if [[ $INSTALL_ELASTICSEARCH = "1" ]]; then
  echo ""
  echo "*** Installing MongoDB ***"
  echo ""

  apt -y install mongodb-server
fi

# Download graylog package

echo ""
echo "*** Downloading and Installing Graylog package ***"
echo ""
wget https://packages.graylog2.org/repo/packages/graylog-2.4-repository_latest.deb
# Install graylog package
dpkg -i graylog-2.4-repository_latest.deb
apt -y update && apt install graylog-server

# Update repository and install graylog
apt update
apt -y install graylog-server
systemctl daemon-reload
systemctl enable graylog-server.service

# Configure graylog configuration file
echo ""
echo "*** Configuring Graylog ***"
echo ""

# Run shell script to configure server.conf
sh graylog-conf.sh

# Remove unnecessary files created during script
rm "graylog-2.4-repository_latest.deb"
rm "elasticsearch-6.5.1.deb"
rm "elasticsearch-6.5.1.deb.sha512"

# Start Elasticsearch & Graylog Server
echo ""
echo "*** Starting Elasticsearch ***"
echo ""
systemctl start elasticsearch.service

echo ""
echo "*** Starting Graylog ***"
echo ""
systemctl start graylog-server.service
