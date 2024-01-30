#!/bin/bash

# Remove existing cron
if crontab -l > /dev/null; then
    crontab -r
fi

# Write out current crontab
crontab -l > mycron

# Echo new cron into cron file
echo "@reboot /root/scripts/check_and_restart_journald.sh" >> mycron
echo "*/10 * * * * /root/iron_script/scripts/check_and_restart_journald.sh" >> mycron
echo "*/10 * * * * /root/iron_script/scripts/export_peer_id.sh" >> mycron
echo "*/10 * * * * /root/iron_script/scripts/update_script.sh" >> mycron
echo "* * * * * /root/iron_script/scripts/export_quil_metrics.sh" >> mycron
# Run upload_s3.sh every hour
echo "0 * * * * /root/iron_script/scripts/upload_s3.sh" >> mycron
# Restart node_exporter every day
echo "0 0 * * * /usr/bin/systemctl restart node_exporter.service > /dev/null" >> mycron
# Resart node_exporter every 10 minutes
# echo "*/10 * * * * /usr/bin/systemctl restart node_exporter.service > /dev/null" >> mycron

# Install new cron file
crontab mycron

# Remove temporary cron file
rm mycron