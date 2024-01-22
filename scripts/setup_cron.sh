#!/bin/bash

# Write out current crontab
crontab -l > mycron

# Echo new cron into cron file
echo "@reboot /root/scripts/check_and_restart_journald.sh" >> mycron
echo "*/10 * * * * /root/iron_script/scripts/check_and_restart_journald.sh" >> mycron
echo "*/10 * * * * /root/iron_script/scripts/export_peer_id.sh" >> mycron
echo "*/10 * * * * /root/iron_script/scripts/update_script.sh" >> mycron
echo "* * * * * /root/iron_script/scripts/export_quil_metrics.sh" >> mycron


# Install new cron file
crontab mycron
rm mycron