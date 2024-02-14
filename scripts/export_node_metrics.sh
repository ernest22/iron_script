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
    # Get leader frame from "returning leader frame" log
    LEADER_FRAME=$(journalctl -u quil.service | grep "returning leader frame" | tail -1)

    # Parse values from the log entries
    MY_BALANCE=$(echo "$LATEST_APP_STATE_LOG" | grep -oP 'my_balance":\K\d+')
    LOBBY_STATE=$(echo "$LATEST_APP_STATE_LOG" | grep -oP 'lobby_state":"\K[^"]+')
    NETWORK_PEER_COUNT=$(echo "$LATEST_PEERS_LOG" | grep -oP 'network_peer_count":\K\d+')
    LATEST_FRAME_NUMBER=$(echo "$LATEST_FRAME_LOG" | grep -oP 'frame_number":\K\d+')
    LEADER_FRAME_NUMBER=$(echo "$LEADER_FRAME" | grep -oP 'frame_number":\K\d+')
    # If Latest Frame Number has no value, set it to the frame number from the leader frame log
    if [ -z "$LATEST_FRAME_NUMBER" ]; then
        # IF leader frame is not equal to 0, set the frame number to the leader frame number, else don't set it
        if [ -n "$LEADER_FRAME_NUMBER" ]; then
            FRAME_NUMBER=$LEADER_FRAME_NUMBER
        fi
    else
        FRAME_NUMBER=$LATEST_FRAME_NUMBER
    fi
    # Get another frame number from round log and if there is multiple frame numbers, get the first one
    ROUND_FRAME_NUMBER=$(echo "$LATEST_ROUND_LOG" | grep -oP 'frame_number":\K\d+' | head -1)
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
    if [ -n "$LEADER_FRAME_NUMBER" ]; then
        echo "quil_leader_frame_number $LEADER_FRAME_NUMBER" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
    if [ -n "$LATEST_FRAME_NUMBER" ]; then
        echo "quil_latest_frame_number $LATEST_FRAME_NUMBER" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
    if [ -n "$ROUND_FRAME_NUMBER" ]; then
        echo "quil_round_frame_number $ROUND_FRAME_NUMBER" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
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

if [ "$1" == "lava-node" ]; then
    # Get status
    STATUS=$(/root/.lava/cosmovisor/current/bin/lavad status) 

    # Extract the desired metrics from the STATUS
    NETWORK=$(echo "$STATUS" | jq -r '.NodeInfo.network')
    VERSION=$(echo "$STATUS" | jq -r '.NodeInfo.version')
    LATEST_BLOCK_HEIGHT=$(echo "$STATUS" | jq -r '.SyncInfo.latest_block_height')
    LATEST_BLOCK_TIME=$(echo "$STATUS" | jq -r '.SyncInfo.latest_block_time')
    ADDRESS=$(echo "$STATUS" | jq -r '.ValidatorInfo.Address')
    VOTING_POWER=$(echo "$STATUS" | jq -r '.ValidatorInfo.VotingPower')

    # Export the metrics to the prometheus metrics file if they are set
    if [ -n "$NETWORK" ]; then
        echo "lava_network{network=\"$NETWORK\"} 1" > $TEXTFILE_COLLECTOR_DIR/lava_metrics.prom
    fi
    if [ -n "$VERSION" ]; then
        echo "lava_version{version=\"$VERSION\"} 1" >> $TEXTFILE_COLLECTOR_DIR/lava_metrics.prom
    fi
    if [ -n "$LATEST_BLOCK_HEIGHT" ]; then
        echo "lava_latest_block_height $LATEST_BLOCK_HEIGHT" >> $TEXTFILE_COLLECTOR_DIR/lava_metrics.prom
    fi
    if [ -n "$LATEST_BLOCK_TIME" ]; then
        # Convert the time (e.g. 2023-08-23T15:37:18.057334561Z) to unix timestamp
        LATEST_BLOCK_TIME=$(date -d "$LATEST_BLOCK_TIME" +%s)
        echo "lava_latest_block_time $LATEST_BLOCK_TIME" >> $TEXTFILE_COLLECTOR_DIR/lava_metrics.prom
    fi
    if [ -n "$ADDRESS" ]; then
        echo "lava_address{address=\"$ADDRESS\"} 1" >> $TEXTFILE_COLLECTOR_DIR/lava_metrics.prom
    fi
    if [ -n "$VOTING_POWER" ]; then
        echo "lava_voting_power $VOTING_POWER" >> $TEXTFILE_COLLECTOR_DIR/lava_metrics.prom
    fi

fi
    