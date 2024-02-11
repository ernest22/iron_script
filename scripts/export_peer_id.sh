#!/bin/bash

# Get the first argument and set it as job variable, if no argument is passed, quit the script
if [ -z "$1" ]; then
    echo "No argument supplied"
    exit 1
fi

# Directory for Node Exporter's Textfile Collector
TEXTFILE_COLLECTOR_DIR="/var/lib/node_exporter/textfile_collector"

# Check if the job is quil-node
if [ "$1" == "quil-node" ]; then
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
fi

if [ "$1" == "zora-node" ]; then
    # Get self info from zora-node using method "opp2p_self"
    SELF_INFO=$(curl -s -d '{"id":0,"jsonrpc":"2.0","method":"opp2p_self","params":[]}' \
        -H "Content-Type: application/json" http://localhost:7545 | jq -r '.result')
    # Get the peer ID from the result
    PEER_ID=$(echo "$SELF_INFO" | jq -r '.peerID')
    # Get the node ID from the result
    NODE_ID=$(echo "$SELF_INFO" | jq -r '.nodeID')

    # Check if PEER_ID or NODE_ID is empty and handle it
    if [ -z "$PEER_ID" ] || [ -z "$NODE_ID" ]; then
        echo "Peer ID or Node ID not found, not updating Prometheus metric."
    else
        # Export the output as a Prometheus metric
        echo "node_peer_id{peer_id=\"$PEER_ID\", node_id=\"$NODE_ID\"} 1" > $TEXTFILE_COLLECTOR_DIR/node_peer_id.prom
    fi
fi