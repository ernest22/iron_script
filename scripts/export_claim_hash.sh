#!/bin/bash

# Get the first argument and set it as job variable, if no argument is passed, quit the script
if [ -z "$1" ]; then
    echo "No argument supplied"
    exit 1
fi

# Get the second arguemt as address
if [ -z "$2" ]; then
    echo "No argument supplied"
    exit 1
fi

# Directory for Node Exporter's Textfile Collector
TEXTFILE_COLLECTOR_DIR="/var/lib/node_exporter/textfile_collector"

# Check if the job is quil-node
if [ "$1" == "quil-node" ]; then
    # Check if claim_hash.prom already exists and skip the command if it does
    ADDRESS=$2
    # Check if address is empty or "NA"
    if [ -z "$ADDRESS" ] || [ "$ADDRESS" == "NA" ]; then
        echo "SKIP Address not found"
        exit 1
    fi
    # Run your command and capture the output
    OUTPUT=$(cd /root/ceremonyclient/client/ && GOEXPERIMENT=arenas go build -o qclient main.go && ./qclient cross-mint $ADDRESS)
    
    # Extract Claim Hash
    HASH=$(echo "$OUTPUT")

    # Check if PEER_ID is empty and handle it
    if [ -z "$HASH" ]; then
        echo "SKIP Claim Hash not found"
    else
        # Export the output as a Prometheus metric
        echo "quil_claim_hash{claim_hash=\"$HASH\"} 1" > $TEXTFILE_COLLECTOR_DIR/claim_hash.prom
        echo "$HASH"
    fi
fi