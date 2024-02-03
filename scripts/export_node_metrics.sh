#!/bin/bash

# Get the first argument and set it as job variable, if no argument is passed, quit the script
if [ -z "$1" ]; then
    echo "No argument supplied"
    exit 1
fi

# Directory for Node Exporter's Textfile Collector Test
TEXTFILE_COLLECTOR_DIR="/var/lib/node_exporter/textfile_collector"

# Check if the job is quil-node
if [ "$1" == "quil-node" ]; then
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

    # Check if each value is set, and if yes, export the data
    if [ -n "$MY_BALANCE" ]; then
        echo "quil_my_balance $MY_BALANCE" > $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi

    if [ -n "$LOBBY_STATE" ]; then
        echo "quil_lobby_state{state=\"$LOBBY_STATE\"} 1" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi

    if [ -n "$NETWORK_PEER_COUNT" ]; then
        echo "quil_network_peer_count $NETWORK_PEER_COUNT" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi

    if [ -n "$FRAME_NUMBER" ]; then
        echo "quil_frame_number $FRAME_NUMBER" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi

    if [ -n "$IN_ROUND_NUM" ]; then
        echo "quil_in_round $IN_ROUND_NUM" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
fi

# Check if the job is zora-node
if [ "$1" == "zora-node" ]; then
    # Get PEER_COUNT from zora-node
    PEER_COUNT=$(curl -s -d '{"id":0,"jsonrpc":"2.0","method":"opp2p_peerStats","params":[]}' \
        -H "Content-Type: application/json" http://localhost:7545 | jq -r '.result.connected')
    # Get block number from zora-node using method "optimism_syncStatus"
    SYNC_STATS=$(curl -s -d '{"id":0,"jsonrpc":"2.0","method":"optimism_syncStatus","params":[]}' \
        -H "Content-Type: application/json" http://localhost:7545 | jq -r '.result')
    # Get the L1 block number from the result
    L1_BLOCK_NUMBER=$(echo "$SYNC_STATS" | jq -r '.head_l1.number')
    # Get the L1 block timestamp from the result
    L1_BLOCK_TIMESTAMP=$(echo "$SYNC_STATS" | jq -r '.head_l1.timestamp')
    # Get the L2 block number from the result
    L2_BLOCK_NUMBER=$(echo "$SYNC_STATS" | jq -r '.unsafe_l2.number')
    # Get the L2 block timestamp from the result
    L2_BLOCK_TIMESTAMP=$(echo "$SYNC_STATS" | jq -r '.unsafe_l2.timestamp')

    # Check if each value is set, and if yes, export the data
    if [ -n "$PEER_COUNT" ]; then
        echo "zora_peer_count $PEER_COUNT" > $TEXTFILE_COLLECTOR_DIR/zora_metrics.prom
    fi
    if [ -n "$L1_BLOCK_NUMBER" ]; then
        echo "zora_l1_block_number $L1_BLOCK_NUMBER" >> $TEXTFILE_COLLECTOR_DIR/zora_metrics.prom
    fi
    if [ -n "$L1_BLOCK_TIMESTAMP" ]; then
        echo "zora_l1_block_timestamp $L1_BLOCK_TIMESTAMP" >> $TEXTFILE_COLLECTOR_DIR/zora_metrics.prom
    fi
    if [ -n "$L2_BLOCK_NUMBER" ]; then
        echo "zora_l2_block_number $L2_BLOCK_NUMBER" >> $TEXTFILE_COLLECTOR_DIR/zora_metrics.prom
    fi
    if [ -n "$L2_BLOCK_TIMESTAMP" ]; then
        echo "zora_l2_block_timestamp $L2_BLOCK_TIMESTAMP" >> $TEXTFILE_COLLECTOR_DIR/zora_metrics.prom
    fi

fi
