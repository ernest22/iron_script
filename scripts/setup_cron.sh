#!/bin/bash

# Get the first argument and set it as job variable, if no argument is passed, quit the script
if [ -z "$1" ]; then
    echo "No argument supplied"
    exit 1
fi

# Remove existing cron
if crontab -l > /dev/null; then
    crontab -r
fi

# Write out current crontab
crontab -l > mycron

# Echo new cron into cron file
# echo "@reboot /root/scripts/check_and_restart_journald.sh" >> mycron
# echo "*/10 * * * * /root/iron_script/scripts/check_and_restart_journald.sh" >> mycron
echo "*/10 * * * * /root/iron_script/scripts/update_script.sh $1" >> mycron
# Restart node_exporter every day
echo "0 0 * * * /usr/bin/systemctl restart node_exporter.service > /dev/null" >> mycron
# Run sanity check every 1 hour
echo "0 * * * * /root/iron_script/scripts/sanity.sh $1" >> mycron
# Export peer id and metrics according to the job
echo "*/10 * * * * /root/iron_script/scripts/export_peer_id.sh $1" >> mycron
echo "* * * * * /root/iron_script/scripts/export_node_metrics.sh $1" >> mycron

echo "0 * * * * /root/iron_script/scripts/upload_s3.sh $1" >> mycron


# Install new cron file
crontab mycron

# Remove temporary cron file
rm mycron