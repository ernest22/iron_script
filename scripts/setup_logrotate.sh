#!/bin/bash

# Define the logrotate configuration
logrotate_config="/etc/logrotate.d/node_exporter"
config_content="
/var/log/node_exporter/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root root
    postrotate
        /usr/bin/systemctl restart node_exporter.service > /dev/null
    endscript
}"

# Write the configuration to the logrotate file
echo "$config_content" | sudo tee $logrotate_config

# Ensure logrotate is set to run daily
if [ ! -f /etc/cron.daily/logrotate ]; then
    sudo ln -s /usr/sbin/logrotate /etc/cron.daily/
fi