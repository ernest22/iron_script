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

    # Get the number of occurrences of the log message in the last 5 lines of the service's logs
    OCCURRENCES=$(journalctl -u $SERVICE_NAME | grep "$LOG_MESSAGE" | tail -5 | wc -l)

    # If the log message appears more than once in the last 5 lines, restart the service
    if [ $OCCURRENCES -gt 1 ]
    then
        echo "Restarting $SERVICE_NAME because '$LOG_MESSAGE' appeared $OCCURRENCES times in the last 5 lines of logs"
        systemctl restart $SERVICE_NAME
    else
        echo "'$LOG_MESSAGE' did not appear multiple times in the last 5 lines of $SERVICE_NAME logs"
    fi
fi