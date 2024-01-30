#!/bin/bash

# Change directory to the repository location
cd /root/iron_script

# Perform git pull to update the repository
git pull

# Run setup_logrotate.sh
./scripts/setup_logrotate.sh

cd /root/ceremonyclient
git pull