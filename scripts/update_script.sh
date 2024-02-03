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

cd /root/ceremonyclient
git pull