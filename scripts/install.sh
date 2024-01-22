#!/bin/bash

cd ~

# Update all packages
sudo apt update
sudo apt upgrade -y

# Install Tools
sudo apt install vim -y
sudo apt install git -y

# Install Go
wget https://go.dev/dl/go1.20.13.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.20.13.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile

# Reload the profile
source ~/.profile

# Download Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
# Extract Node Exporter
tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz
# Move Node Exporter binary
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
# Create Node Exporter service file
sudo cp /root/iron_script/services/node_exporter.service /etc/systemd/system/
# Reload systemd daemon
sudo systemctl daemon-reload
# Enable Node Exporter service
sudo systemctl enable node_exporter.service

# Create directories if they don't exist
sudo mkdir -p /var/lib/node_exporter
sudo mkdir -p /var/lib/node_exporter/textfile_collector

# Install quilt Client
if [ ! -d "ceremonyclient" ]; then
    git clone https://github.com/QuilibriumNetwork/ceremonyclient.git
else
    echo "Directory ceremonyclient already exists"
fi
sudo cp /root/iron_script/services/quil.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable quil.service

# Run setup_cron.tabß
./iron_script/scripts/setup_cron.sh

# Start Node
sudo systemctl start node_exporter.service
sudo systemctl start quil.service

