#!/bin/bash

# Change directory to the repository location
cd /root/iron_script

# Perform git pull to update the repository
git pull

# Run setup_cron.sh to update the cron jobs
/root/iron_script/scripts/setup_cron.sh

cd /root/ceremonyclient
git pull