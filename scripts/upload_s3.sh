#!/bin/bash

# Define the path to the private key and the bucket name
PRIVATE_KEY_PATH="/root/ceremonyclient/node/.config/keys.yml"
CONFIG_KEY_PATH="/root/ceremonyclient/node/.config/config.yml"
BUCKET_NAME="iron-node"

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

# Check if the private key file exists
if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo "Private key file not found at $PRIVATE_KEY_PATH"
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
fi

# Check if the private key file and config file already exist on the S3 bucket
count=`s3cmd ls "s3://$BUCKET_NAME/$PEER_ID/config.yml" | wc -l`
if [[ $count -gt 0 ]]; then
        echo "Config file already exists on s3://$BUCKET_NAME/$PEER_ID"
        exit
fi

# Upload the private key to the S3 bucket under the peer ID directory with encryption
s3cmd put "$PRIVATE_KEY_PATH" "s3://$BUCKET_NAME/$PEER_ID/" --encrypt
# Check if the upload was successful
if [ $? -eq 0 ]; then
    echo "Private key successfully uploaded to $BUCKET_NAME"
else
    echo "Failed to upload private key to $BUCKET_NAME"
fi

# Upload the config file to the S3 bucket under the peer ID directory with encryption
s3cmd put "$CONFIG_KEY_PATH" "s3://$BUCKET_NAME/$PEER_ID/"  --encrypt   
# Check if the upload was successful
if [ $? -eq 0 ]; then
    echo "Config file successfully uploaded to $BUCKET_NAME"
else
    echo "Failed to upload config file to $BUCKET_NAME"
fi