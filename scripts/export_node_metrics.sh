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
    LOG_OUTPUT=$(journalctl -u quil.service --since "1 week ago")
    LOG_OUTPUT_LAST_HOUR=$(journalctl -u quil.service --since "1 hour ago")
    # Extract the latest relevant log entries
    LATEST_APP_STATE_LOG=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "current application state" | tail -1)
    LATEST_PEERS_LOG=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "peers in store" | tail -1)
    LATEST_FRAME_LOG=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "got clock frame" | tail -1)
    LATEST_ROUND_LOG=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "\"round in progress\"" | tail -1)
    LATEST_VERSION_LOG=$(echo "$LOG_OUTPUT" | grep "Quilibrium Node - v" | tail -1)
    LATEST_CHECKPEER_LOG=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "checking peer list" | tail -1)
    LATEST_MASTER_FRAME_LOG=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "master frame synchronization" | tail -1)
    #{"level":"info","ts":1716869763.748067,"caller":"master/master_clock_consensus_engine.go:270","msg":"recalibrating difficulty metric","previous_difficulty_metric":149947,"next_difficulty_metric":148453}
    #{"level":"info","ts":1716869763.7481942,"caller":"master/master_clock_consensus_engine.go:283","msg":"broadcasting self-test info","current_frame":1661386}
    LATEST_DIFFICULTY_LOG=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "recalibrating difficulty metric" | tail -1)
    LATEST_SELF_TEST_LOG=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "broadcasting self-test info" | tail -1)
    # Get leader frame from "returning leader frame" log
    LEADER_FRAME=$(echo "$LOG_OUTPUT_LAST_HOUR" | grep "returning leader frame" | tail -1)

    # Parse values from the log entries
    MY_BALANCE=$(echo "$LATEST_APP_STATE_LOG" | grep -oP 'my_balance":\K\d+')
    LOBBY_STATE=$(echo "$LATEST_APP_STATE_LOG" | grep -oP 'lobby_state":"\K[^"]+')
    NETWORK_PEER_COUNT=$(echo "$LATEST_PEERS_LOG" | grep -oP 'network_peer_count":\K\d+')
    LATEST_FRAME_NUMBER=$(echo "$LATEST_FRAME_LOG" | grep -oP 'frame_number":\K\d+')
    LEADER_FRAME_NUMBER=$(echo "$LEADER_FRAME" | grep -oP 'frame_number":\K\d+')
    HEAD_FRAME_NUMBER=$(echo "$LATEST_CHECKPEER_LOG" | grep -oP 'current_head_frame":\K\d+')
    MASTER_FRAME_HEAD=$(echo "$LATEST_MASTER_FRAME_LOG" | grep -oP 'master_frame_head":\K\d+')
    MAX_DATA_FRAME_TARGET=$(echo "$LATEST_MASTER_FRAME_LOG" | grep -oP 'max_data_frame_target":\K\d+')
    PREVIOUS_DIFFICULTY=$(echo "$LATEST_DIFFICULTY_LOG" | grep -oP 'previous_difficulty_metric":\K\d+')
    NEXT_DIFFICULTY=$(echo "$LATEST_DIFFICULTY_LOG" | grep -oP 'next_difficulty_metric":\K\d+')
    CURRENT_FRAME=$(echo "$LATEST_SELF_TEST_LOG" | grep -oP 'current_frame":\K\d+')
    # Get version from log like Quilibrium Node - v1.4.13 – Sunset, only get the version number, i.e. 1.4.13
    NODE_VERSION=$(echo "$LATEST_VERSION_LOG" | grep -oP 'Quilibrium Node - v\K\d+\.\d+\.\d+')
    # If Latest Frame Number has no value, set it to the frame number from the leader frame log
    # if [ -z "$LATEST_FRAME_NUMBER" ]; then
    #     # IF leader frame is not equal to 0, set the frame number to the leader frame number, else don't set it
    #     if [ -n "$LEADER_FRAME_NUMBER" ]; then
    #         FRAME_NUMBER=$LEADER_FRAME_NUMBER
    #     fi
    # else
    #     FRAME_NUMBER=$LATEST_FRAME_NUMBER
    # fi
    FRAME_NUMBER=$LATEST_FRAME_NUMBER
    # Get another frame number from round log and if there is multiple frame numbers, get the first one
    ROUND_FRAME_NUMBER=$(echo "$LATEST_ROUND_LOG" | grep -oP 'frame_number":\K\d+' | head -1)
    IN_ROUND=$(echo "$LATEST_ROUND_LOG" | grep -oP 'in_round":\K(true|false)')

    # Convert IN_ROUND to a numerical value (1 for true, 0 for false)
    IN_ROUND_NUM=$( [ "$IN_ROUND" == "true" ] && echo 1 || echo 0 )

    # Clear the file before writing new metrics
    > $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom

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
    if [ -n "$NODE_VERSION" ]; then
        echo "node_version{version=\"$NODE_VERSION\"} 1" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
    if [ -n "$HEAD_FRAME_NUMBER" ]; then
        echo "quil_head_frame_number $HEAD_FRAME_NUMBER" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
    if [ -n "$MASTER_FRAME_HEAD" ]; then
        echo "quil_master_frame_head $MASTER_FRAME_HEAD" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
    if [ -n "$MAX_DATA_FRAME_TARGET" ]; then
        echo "quil_max_data_frame_target $MAX_DATA_FRAME_TARGET" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
    if [ -n "$PREVIOUS_DIFFICULTY" ]; then
        echo "quil_previous_difficulty $PREVIOUS_DIFFICULTY" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
    if [ -n "$NEXT_DIFFICULTY" ]; then
        echo "quil_next_difficulty $NEXT_DIFFICULTY" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
    fi
    if [ -n "$CURRENT_FRAME" ]; then
        echo "quil_current_frame $CURRENT_FRAME" >> $TEXTFILE_COLLECTOR_DIR/quil_metrics.prom
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
    