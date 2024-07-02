#!/bin/bash

# Get the first argument and set it as job variable, if no argument is passed, quit the script
if [ -z "$1" ]; then
    echo "No argument supplied"
    exit 1
fi

# if the job is not quil-node quit the script
if [ "$1" != "quil-node" ]; then
    echo "Job is not quil-node"
    exit 1
fi

# Define the path to the private key and the bucket name
PRIVATE_KEY_PATH="/root/ceremonyclient/node/.config/keys.yml"
CONFIG_KEY_PATH="/root/ceremonyclient/node/.config/config.yml"
CONFIG_FOLDER_PATH="/root/ceremonyclient/node/.config"
BUCKET_NAME="iron-node/quil-node"

# Check if config folder exists
if [ ! -d "$CONFIG_FOLDER_PATH" ]; then
    echo "Config folder not found at $CONFIG_FOLDER_PATH"
    exit
fi

# Check if private key file exists
if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo "Private key file not found at $PRIVATE_KEY_PATH"
    exit
fi
# Check if config file exists
if [ ! -f "$CONFIG_KEY_PATH" ]; then
    echo "Config file not found at $CONFIG_KEY_PATH"
    exit
fi

# Check if s3cmd is installed
if ! command -v s3cmd &> /dev/null
then
    echo "s3cmd could not be found, please install it first."
    exit
fi

# Run your command and capture the output
OUTPUT=$(cd /root/ceremonyclient/node/ && GOEXPERIMENT=arenas /usr/local/go/bin/go run ./... --peer-id)
# Extract Peer ID
PEER_ID=$(echo "$OUTPUT" | grep "Peer ID:" | awk '{print $3}')
# Check if PEER_ID is empty
if [ -z "$PEER_ID" ]; then
    echo "Peer ID not found"
    exit
fi

# Check if the private key file and config file already exist on the S3 bucket
count=`s3cmd ls "s3://$BUCKET_NAME/$PEER_ID/keys.yml" | wc -l`
if [[ $count -gt 0 ]]; then
        echo "Private key already exists on s3://$BUCKET_NAME/$PEER_ID"
        exit
else
    # Upload the private key to the S3 bucket under the peer ID directory with encryption
    s3cmd put "$PRIVATE_KEY_PATH" "s3://$BUCKET_NAME/$PEER_ID/" --encrypt
    # Check if the upload was successful
    if [ $? -eq 0 ]; then
        echo "Private key successfully uploaded to $BUCKET_NAME"
    else
        echo "Failed to upload private key to $BUCKET_NAME"
    fi
fi

# Check if the private key file and config file already exist on the S3 bucket
count=`s3cmd ls "s3://$BUCKET_NAME/$PEER_ID/config.yml" | wc -l`
if [[ $count -gt 0 ]]; then
        echo "Config file already exists on s3://$BUCKET_NAME/$PEER_ID"
        exit
else
    # Upload the config file to the S3 bucket under the peer ID directory with encryption
    s3cmd put "$CONFIG_KEY_PATH" "s3://$BUCKET_NAME/$PEER_ID/" --encrypt
    # Check if the upload was successful
    if [ $? -eq 0 ]; then
        echo "Config file successfully uploaded to $BUCKET_NAME"
    else
        echo "Failed to upload config file to $BUCKET_NAME"
    fi
fi

# Check if the config folder already exists on the S3 bucket
count=`s3cmd ls "s3://$BUCKET_NAME/$PEER_ID/config" | wc -l`
if [[ $count -gt 0 ]]; then
        echo "Config folder already exists on s3://$BUCKET_NAME/$PEER_ID"
        exit
else
    # Upload the config folder to the S3 bucket under the peer ID directory with encryption
    s3cmd put "$CONFIG_FOLDER_PATH" "s3://$BUCKET_NAME/$PEER_ID/config/" --recursive --encrypt
    # Check if the upload was successful
    if [ $? -eq 0 ]; then
        echo "Config folder successfully uploaded to $BUCKET_NAME"
    else
        echo "Failed to upload config folder to $BUCKET_NAME"
    fi
fi 
