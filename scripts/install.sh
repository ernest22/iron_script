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
# Install crontab
sudo apt-get install cron -y

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
    if [ ! -d "node" ]; then
        git clone https://github.com/conduitxyz/node.git
    else
        echo "Directory node already exists"
    fi
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
    docker system prune -a -f
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
    sudo apt install -y curl openssh-server docker-compose git certbot nginx sqlite3 build-essential && sudo systemctl enable ssh && curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && sudo apt-get update -y && sudo apt-get install -y yarn && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && source ~/.bashrc && sudo ufw allow 22 80 443 && sudo ufw enable
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
fi

if [ "$1" = "lava-node" ]; then
    # Update and download packages
    sudo apt install -y unzip logrotate git jq sed wget curl coreutils systemd
    # Create the temp dir for the installation
    temp_folder=$(mktemp -d) && cd $temp_folder
    ### Configurations
    go_package_url="https://go.dev/dl/go1.20.5.linux-amd64.tar.gz"
    go_package_file_name=${go_package_url##*\/}
    # Download GO
    wget -q $go_package_url
    # Unpack the GO installation file
    sudo tar -C /usr/local -xzf $go_package_file_name
    # Environment adjustments
    echo "export PATH=\$PATH:/usr/local/go/bin" >>~/.profile
    echo "export PATH=\$PATH:\$(go env GOPATH)/bin" >>~/.profile
    source ~/.profile

    cd
    # Download the installation setup configuration
    git clone https://github.com/lavanet/lava-config.git
    cd lava-config/testnet-2
    # Read the configuration from the file
    # Note: you can take a look at the config file and verify configurations
    source setup_config/setup_config.sh

    echo "Lava config file path: $lava_config_folder"
    mkdir -p $lavad_home_folder
    mkdir -p $lava_config_folder
    cp default_lavad_config_files/* $lava_config_folder

    # Copy the genesis.json file to the Lava config folder
    cp genesis_json/genesis.json $lava_config_folder/genesis.json

    go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0
    # Create the Cosmovisor folder and copy config files to it
    mkdir -p $lavad_home_folder/cosmovisor/genesis/bin/
    # Download the genesis binary
    wget -O  $lavad_home_folder/cosmovisor/genesis/bin/lavad "https://github.com/lavanet/lava/releases/download/v0.21.1.2/lavad-v0.21.1.2-linux-amd64"
    chmod +x $lavad_home_folder/cosmovisor/genesis/bin/lavad

    # Set the environment variables
    echo "# Setup Cosmovisor" >> ~/.profile
    echo "export DAEMON_NAME=lavad" >> ~/.profile
    echo "export CHAIN_ID=lava-testnet-2" >> ~/.profile
    echo "export DAEMON_HOME=$HOME/.lava" >> ~/.profile
    echo "export DAEMON_ALLOW_DOWNLOAD_BINARIES=true" >> ~/.profile
    echo "export DAEMON_LOG_BUFFER_SIZE=512" >> ~/.profile
    echo "export DAEMON_RESTART_AFTER_UPGRADE=true" >> ~/.profile
    echo "export UNSAFE_SKIP_BACKUP=true" >> ~/.profile
    source ~/.profile

    # Initialize the chain
    $lavad_home_folder/cosmovisor/genesis/bin/lavad init \
    my-node \
    --chain-id lava-testnet-2 \
    --home $lavad_home_folder \
    --overwrite
    cp genesis_json/genesis.json $lava_config_folder/genesis.json

    # Create Cosmovisor unit file
    echo "[Unit]
    Description=Cosmovisor daemon
    After=network-online.target
    [Service]
    Environment="DAEMON_NAME=lavad"
    Environment="DAEMON_HOME=${HOME}/.lava"
    Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
    Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
    Environment="DAEMON_LOG_BUFFER_SIZE=512"
    Environment="UNSAFE_SKIP_BACKUP=true"
    User=$USER
    ExecStart=${HOME}/go/bin/cosmovisor start --home=$lavad_home_folder --p2p.seeds $seed_node
    Restart=always
    RestartSec=3
    LimitNOFILE=infinity
    LimitNPROC=infinity
    [Install]
    WantedBy=multi-user.target
    " >cosmovisor.service
    sudo mv cosmovisor.service /lib/systemd/system/cosmovisor.service

    # Enable the cosmovisor service so that it will start automatically when the system boots
    sudo systemctl daemon-reload
    sudo systemctl enable cosmovisor.service
    sudo systemctl restart systemd-journald
    sudo systemctl restart cosmovisor.service
fi



cd

# Run setup_cron.sh
./iron_script/scripts/setup_cron.sh $1

# Run setup_logrotate.sh
# ./iron_script/scripts/setup_logrotate.sh

# Start Node
sudo systemctl restart node_exporter.service


