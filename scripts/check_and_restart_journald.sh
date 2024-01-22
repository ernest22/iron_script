#!/bin/bash

# Check the output of journalctl for a specific unit
OUTPUT=$(journalctl -u quil.service --no-pager | tail -n 10)

# Search for the "No journal files were found." or "-- No entries --" messages
if echo "$OUTPUT" | grep -qE "No journal files were found.|-- No entries --"; then
  echo "No journal files or no entries found. Restarting systemd-journald..."
  sudo systemctl restart systemd-journald
else
  echo "Journal files are available."
fi

