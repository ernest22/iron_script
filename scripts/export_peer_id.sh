#!/bin/bash

# Directory for Node Exporter's Textfile Collector
TEXTFILE_COLLECTOR_DIR="/var/lib/node_exporter/textfile_collector"

# Run your command and capture the output
OUTPUT=$(cd /root/ceremonyclient/node/ && GOEXPERIMENT=arenas /usr/local/go/bin/go run ./... --peer-id)

# Extract Peer ID
PEER_ID=$(echo "$OUTPUT" | grep "Peer ID:" | awk '{print $3}')

# Check if PEER_ID is empty and handle it
if [ -z "$PEER_ID" ]; then
    echo "Peer ID not found, not updating Prometheus metric."
else
    # Export the output as a Prometheus metric
    echo "node_peer_id{peer_id=\"$PEER_ID\"} 1" > $TEXTFILE_COLLECTOR_DIR/node_peer_id.prom
fi

