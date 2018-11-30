#!/usr/bin/env bash

function isRoot () {
	if [ "$EUID" -ne 0 ]; then
		echo "Sorry, you need to run this as root"
		exit 1
	fi
}

function checkOS () {
	if [[ -e /etc/debian_version ]]; then
		source /etc/os-release

		if [[ "$ID" == "ubuntu" ]];then
			OS="ubuntu"
			if [[ ! $VERSION_ID =~ (16.04|18.04) ]]; then
				echo "⚠️ Your version of Ubuntu is not supported."
				echo ""
				echo "However, if you're using Ubuntu > 17 or beta, then you can continue."
				echo "Keep in mind they are not supported, though."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ "$CONTINUE" = "n" ]]; then
					exit 1
				fi
			fi
		fi
	else
		echo "Looks like you aren't running this installer on a Ubuntu Linux system"
		exit 1
	fi
}

isRoot
checkOS

# Install Elasticsearch locally
echo ""
echo "Would you like Elasticsearch installed locally?"
echo "   1) Yes"
echo "   2) No"

until [[ "$INSTALL_ELASTICSEARCH" =~ ^[1-2]$ ]]; do
  read -rp "Select an option [1-2]: " -e -i 1 INSTALL_ELASTICSEARCH
done

# Install MongoDB locally
echo ""
echo "Would you like MongoDB installed locally?"
echo "   1) Yes"
echo "   2) No"

until [[ "$INSTALL_MONGODB" =~ ^[1-2]$ ]]; do
  read -rp "Select an option [1-2]: " -e -i 1 INSTALL_MONGODB
done

echo ""
echo "Okay, that was all I needed. We are ready to setup your Graylog server now."
read -n1 -r -p "Press any key to continue..."

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

if [[ $INSTALL_ELASTICSEARCH = "1" ]]; then
  echo ""
  echo "*** Installing Elasticsearch ***"
  echo ""

  sudo dpkg -i elasticsearch-5.3.3.deb
  sudo /etc/init.d/elasticsearch start

  systemctl daemon-reload
  systemctl enable elasticsearch.service
  systemctl restart elasticsearch.service
fi

if [[ $INSTALL_MONGODB = "1" ]]; then
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
# rm "elasticsearch-5.3.3.deb"

# Start Elasticsearch & Graylog Server
echo ""
echo "*** Starting Elasticsearch ***"
echo ""
systemctl start elasticsearch.service

echo ""
echo "*** Starting Graylog ***"
echo ""
systemctl start graylog-server.service

echo ""
echo "OS: $ID $VERSION_ID"
echo ""
if [[ $INSTALL_ELASTICSEARCH = "1" ]]; then
  echo "[*] Elasticsearch installed"
fi

if [[ $INSTALL_MONGODB = "1" ]]; then
  echo "[*] MongoDB installed"
fi

echo "[*] Graylog installed"
