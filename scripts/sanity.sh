#!/bin/bash

# Get the first argument and set it as job variable, if no argument is passed, quit the script
if [ -z "$1" ]; then
    echo "No argument supplied"
    exit 1
fi

# Check if the job is quil-node
if [ "$1" == "quil-node" ]; then
    # Define the service name
    SERVICE_NAME="quil.service"

    # Define the log message to check for
    LOG_MESSAGE="waiting for minimum peers"

    # Get the number of occurrences of the log message in the last min of the service logs and store it in OCCURRENCES
    OCCURRENCES=$(journalctl -u $SERVICE_NAME --since "1 min ago" | grep -c "$LOG_MESSAGE" | wc -l)

    # If the log message appears more than once in the last 5 lines, restart the service
    if [ $OCCURRENCES -gt 1 ]
    then
        echo "Restarting $SERVICE_NAME because '$LOG_MESSAGE' appeared $OCCURRENCES times in the last 5 lines of logs"
        systemctl restart $SERVICE_NAME
        # Exit the script
        exit 0
    else
        echo "'$LOG_MESSAGE' did not appear multiple times in the last 5 lines of $SERVICE_NAME logs"
    fi

    # Check if the peer is below 20 from LATEST_PEERS_LOG
    LATEST_PEERS_LOG=$(journalctl -u $SERVICE_NAME | grep "peers in store" | tail -1)
    NETWORK_PEER_COUNT=$(echo "$LATEST_PEERS_LOG" | grep -oP 'network_peer_count":\K\d+')
    if [ $NETWORK_PEER_COUNT -lt 20 ]
    then
        echo "Restarting $SERVICE_NAME because network_peer_count is $NETWORK_PEER_COUNT"
        systemctl restart $SERVICE_NAME
        # Exit the script
        exit 0
    else
        echo "Network peer count is $NETWORK_PEER_COUNT"
    fi

    # Check "no peers available, skipping sync" in the last 1 min of logs
    NO_PEERS_LOG=$(journalctl -u $SERVICE_NAME --since "1 min ago" | grep "no peers available, skipping sync")
    if [ -n "$NO_PEERS_LOG" ]
    then
        echo "Restarting $SERVICE_NAME because 'no peers available, skipping sync' appeared in the last 1 min of logs"
        systemctl restart $SERVICE_NAME
        # Exit the script
        exit 0
    else
        echo "'no peers available, skipping sync' did not appear in the last 1 min of $SERVICE_NAME logs"
    fi
fi