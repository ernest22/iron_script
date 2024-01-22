#!/bin/bash

# Directory for Node Exporter's Textfile Collector Test
TEXTFILE_COLLECTOR_DIR="/var/lib/node_exporter/textfile_collector"

# Extract the latest relevant log entries
LATEST_APP_STATE_LOG=$(journalctl -u quil.service | grep "current application state" | tail -1)
LATEST_PEERS_LOG=$(journalctl -u quil.service | grep "peers in store" | tail -1)
LATEST_FRAME_LOG=$(journalctl -u quil.service | grep "got clock frame" | tail -1)
LATEST_ROUND_LOG=$(journalctl -u quil.service | grep "\"round in progress\"" | tail -1)

# Parse values from the log entries
MY_BALANCE=$(echo "$LATEST_APP_STATE_LOG" | grep -oP 'my_balance":\K\d+')
LOBBY_STATE=$(echo "$LATEST_APP_STATE_LOG" | grep -oP 'lobby_state":"\K[^"]+')
NETWORK_PEER_COUNT=$(echo "$LATEST_PEERS_LOG" | grep -oP 'network_peer_count":\K\d+')
FRAME_NUMBER=$(echo "$LATEST_FRAME_LOG" | grep -oP 'frame_number":\K\d+')
IN_ROUND=$(echo "$LATEST_ROUND_LOG" | grep -oP 'in_round":\K(true|false)')

# Convert IN_ROUND to a numerical value (1 for true, 0 for false)
IN_ROUND_NUM=$( [ "$IN_ROUND" == "true" ] && echo 1 || echo 0 )

# Write the metrics to a Prometheus textfile
echo "quil_my_balance $MY_BALANCE" > $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
echo "quil_lobby_state{state=\"$LOBBY_STATE\"} 1" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
echo "quil_network_peer_count $NETWORK_PEER_COUNT" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
echo "quil_frame_number $FRAME_NUMBER" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
echo "quil_in_round $IN_ROUND_NUM" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
