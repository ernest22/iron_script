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
    # Run git pull and if new changes are available, restart the Quil Node service
    if git pull | grep -q 'Already up to date.'; then
        echo "No new changes"
    else
        echo "New changes found, restarting Quil Node service"
        sudo systemctl restart quil.service
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