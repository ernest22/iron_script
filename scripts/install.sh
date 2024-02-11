#!/bin/bash

# Get the first argument and set it as job variable, if no argument is passed, quit the script
if [ -z "$1" ]; then
    echo "No argument supplied"
    exit 1
fi

# Print what job is being executed
echo "Installing job: $1"

cd ~

# Update all packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Tools
sudo apt-get install vim -y
sudo apt-get install git -y

# Install s3cmd
sudo apt-get install s3cmd -y

# Check if node_exporter is installed
if [ ! -f "/usr/local/bin/node_exporter" ]; then
    echo "Node Exporter not installed"
    # Download Node Exporter
    wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
    # Extract Node Exporter
    tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz
    # Move Node Exporter binary
    sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
else
    echo "Node Exporter already installed"
fi

# Create Node Exporter service file
sudo cp /root/iron_script/services/node_exporter.service /etc/systemd/system/
# Reload systemd daemon
sudo systemctl daemon-reload
# Enable Node Exporter service
sudo systemctl enable node_exporter.service

# Create directories if they don't exist
sudo mkdir -p /var/lib/node_exporter
sudo mkdir -p /var/lib/node_exporter/textfile_collector

# Install Quil Node if job is quil-node
if [ "$1" = "quil-node" ]; then
    # Install Go
    wget https://go.dev/dl/go1.20.13.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.20.13.linux-amd64.tar.gz
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile

    # Reload the profile
    source ~/.profile

    # Install Quil Client
    if [ ! -d "ceremonyclient" ]; then
        git clone https://github.com/QuilibriumNetwork/ceremonyclient.git
    else
        echo "Directory ceremonyclient already exists"
    fi
    sudo cp /root/iron_script/services/quil.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable quil.service  
    sudo systemctl restart quil.service
fi 

if [ "$1" = "zora-node" ]; then
    # Check if arguement 2 is passed
    if [ -z "$2" ]; then
        echo "No ETH RPC supplied"
        exit 1
    fi
    sudo apt-get install curl build-essential git screen jq pkg-config libssl-dev libclang-dev ca-certificates gnupg lsb-release -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose -y

    # Set up environment variable for every restart and for the current session
    echo "export CONDUIT_NETWORK=zora-mainnet-0" >> ~/.bashrc
    export CONDUIT_NETWORK=zora-mainnet-0
    # Install Zora Node
    git clone https://github.com/conduitxyz/node.git
    ./node/download-config.py $CONDUIT_NETWORK
    #if .env file does not exist, create it, else remove it and create a new one
    if [ ! -f "./node/.env" ]; then
        touch ./node/.env
    else
        rm ./node/.env
        touch ./node/.env
    fi
    # Create .env file and create a line "OP_NODE_L1_ETH_RPC=https://eth-mainnet.g.alchemy.com/v2/alchemey_key"
    echo "OP_NODE_L1_ETH_RPC=$2" >> ./node/.env
    # copy zora service to system
    sudo cp /root/iron_script/services/zora.service /etc/systemd/system/
    # prune docker
    docker system prune -a
    # reload daemon
    sudo systemctl daemon-reload
    # enable then restart zora
    sudo systemctl enable zora.service
    sudo systemctl restart zora.service
fi

if [ "$1" = "avail-node" ]; then
    # Download Avail Node
    wget https://github.com/availproject/avail/releases/download/v1.10.0.0/x86_64-ubuntu-2204-data-avail.tar.gz
    # Extract Avail Node
    tar -xvf x86_64-ubuntu-2204-data-avail.tar.gz
    # Move Avail Node into new directory avail-node
    mkdir -p avail-node
    mv data-avail avail-node/
    # Copy Avail Node service file
    sudo cp /root/iron_script/services/avail-node.service /etc/systemd/system/
    # Reload systemd daemon
    sudo systemctl daemon-reload
    # Enable Avail Node service
    sudo systemctl enable avail-node.service
    # Start Avail Node service
    sudo systemctl restart avail-node.service
fi

if [ "$1" = "ar-io-node" ]; then
    # Update and download packages
    sudo apt update -y && sudo apt upgrade -y && sudo apt install -y curl openssh-server docker-compose git certbot nginx sqlite3 build-essential && sudo systemctl enable ssh && curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && sudo apt-get update -y && sudo apt-get install -y yarn && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && source ~/.bashrc && sudo ufw allow 22 80 443 && sudo ufw enable
    # Install Node.js
    nvm install 18.8.0 && nvm use 18.8.0
    # Clone node repository
    git clone -b main https://github.com/ar-io/ar-io-node
    cd ar-io-node
    # Create .env file if it does not exist
    if [ ! -f ".env" ]; then
        touch .env
    else
        rm .env
        touch .env
    fi
    # Add environment variables to .env file 
    echo "GRAPHQL_HOST=arweave.net" >> .env
    echo "GRAPHQL_PORT=443" >> .env
    echo "START_HEIGHT=0" >> .env
    echo "RUN_OBSERVER=true" >> .env
    
    # Copy ar-io-node service file
    sudo cp /root/iron_script/services/ar-io-node.service /etc/systemd/system/
    # Reload systemd daemon
    sudo systemctl daemon-reload
    # Enable ar-io-node service
    sudo systemctl enable ar-io-node.service
    # Start ar-io-node service
    sudo systemctl restart ar-io-node.service


# Run setup_cron.sh
./iron_script/scripts/setup_cron.sh $1

# Run setup_logrotate.sh
# ./iron_script/scripts/setup_logrotate.sh

# Start Node
sudo systemctl restart node_exporter.service


