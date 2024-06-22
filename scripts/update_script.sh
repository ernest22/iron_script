#!/bin/bash

# Set job variable
job=$1

# Get the first argument and set it as job variable, if no argument is passed, print an error message 
if [ -z "$1" ]; then
    echo "No argument supplied"
    # Set job as "quil-node" to avoid errors
    job="quil-node"
fi

# Change directory to the repository location
cd /root/iron_script

# Perform git pull to update the repository
git pull

# Run setup_cron.sh to update the cron jobs
/root/iron_script/scripts/setup_cron.sh $job

if [ "$job" == "quil-node" ]; then
    # Check if the disk usage is above 95%, if yes stop the Quil Node service, and wipe the store directory rm -rf /root/ceremonyclient/node/.config/store
    DISK_USAGE=$(df / | awk 'END{print $5}' | cut -d'%' -f1)
    if [ $DISK_USAGE -gt 95 ]; then
        echo "Disk usage is above 95%, stopping Quil Node service and wiping store directory"
        sudo systemctl stop quil.service
        rm -rf /root/ceremonyclient/node/.config/store
        sudo systemctl start quil.service
        echo "Quil Node service restarted"
    fi

    # Change directory to the Quil Node repository location
    cd /root/ceremonyclient

    # Check if cpulimit is installed, if not install cpulimit
    if ! command -v cpulimit &> /dev/null; then
        echo "cpulimit is not installed, installing cpulimit"
        sudo apt-get install cpulimit -y    
    fi

    # Check if git remote set-url origin https://source.quilibrium.com/quilibrium/ceremonyclient.git is set, if not set the remote URL
    if git remote -v | grep -q 'https://source.quilibrium.com/quilibrium/ceremonyclient.git'; then
        echo "Remote URL is set"
    else
        echo "Setting remote URL"
        git remote set-url origin https://source.quilibrium.com/quilibrium/ceremonyclient.git
    fi

    # Run git pull and if new changes are available, restart the Quil Node service
    if git pull | grep -q 'Already up to date.'; then
        echo "No new changes"
    else
        echo "New changes found, restarting Quil Node service"
        sudo systemctl restart quil.service
    fi
    
    # Run git checkout release to switch to the release branch, if not already on the release branch, and restart the Quil Node service
    if git branch | grep -q '* release-cdn'; then
        echo "Already on release branch"
    else
        echo "Switching to release branch"
        git checkout release-cdn
        sudo systemctl restart quil.service
    fi
    # Check if quil.service is updated by comparing /etc/systemd/system/quil.service and services/quil.service files
    if diff /etc/systemd/system/quil.service /root/iron_script/services/quil.service; then
        echo "quil.service is up to date"
    else
        echo "quil.service is not up to date, updating quil.service"
        sudo cp /root/iron_script/services/quil.service /etc/systemd/system/quil.service
        sudo systemctl daemon-reload
        sudo systemctl restart quil.service
    fi
    # Check config.yml and see if the settings are set as 
    # sed -i 's/listenMultiaddr: \/ip4\/0.0.0.0\/udp\/8336\/quic/listenMultiaddr: \/ip4\/0.0.0.0\/tcp\/8336/g' ~/ceremonyclient/node/.config/config.yml
    # sed -i 's/listenGrpcMultiaddr: ""/listenGrpcMultiaddr: \/ip4\/127.0.0.1\/tcp\/8337/g' ~/ceremonyclient/node/.config/config.yml
    # sed -i 's/listenRESTMultiaddr: ""/listenRESTMultiaddr: \/ip4\/127.0.0.1\/tcp\/8338/g' ~/ceremonyclient/node/.config/config.yml
    # then restart the Quil Node service
    # config.yml file is located at /root/ceremonyclient/node/.config/config.yml
    CONFIG_FILE="/root/ceremonyclient/node/.config/config.yml"
    if [ -f "$CONFIG_FILE" ]; then
        cp $CONFIG_FILE ${CONFIG_FILE}.bak

        # Change the listenMultiaddr, listenGrpcMultiaddr, and listenRESTMultiaddr settings in the config.yml file
        sed -i 's/listenMultiaddr: \/ip4\/0.0.0.0\/udp\/8336\/quic/listenMultiaddr: \/ip4\/0.0.0.0\/tcp\/8336/g' $CONFIG_FILE
        sed -i 's/listenGrpcMultiaddr: ""/listenGrpcMultiaddr: \/ip4\/127.0.0.1\/tcp\/8337/g' $CONFIG_FILE
        sed -i 's/listenRESTMultiaddr: ""/listenRESTMultiaddr: \/ip4\/127.0.0.1\/tcp\/8338/g' $CONFIG_FILE

        # If any updated, restart the Quil Node service
        if ! cmp -s $CONFIG_FILE ${CONFIG_FILE}.bak ; then
            echo "Config file updated, restarting Quil Node service"
            sudo systemctl restart quil.service
        fi

        # Remove the backup file
        rm ${CONFIG_FILE}.bak
    else
        echo "Error: $CONFIG_FILE not found."
    fi
    
fi

if [ "$job" == "zora-node" ]; then
    # Change directory to the Zora Node repository location
    cd /root/node
    # Run git log -1 and check if the latest commit is d92c13d42e4d5d0f2a0ffbe1293d7af58a3f0c5c, if not git checkout and restart the Zora Node service
    if git log -1 | grep -q 'd92c13d42e4d5d0f2a0ffbe1293d7af58a3f0c5c'; then
        echo "No new changes"
    else
        echo "New changes found, restarting Zora Node service"
        git pull
        git checkout d92c13d42e4d5d0f2a0ffbe1293d7af58a3f0c5c
        sudo systemctl restart zora.service
    fi
fi