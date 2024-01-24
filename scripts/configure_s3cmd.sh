#!/bin/bash

# Check if the correct number of arguments are passed
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <access_key> <secret_key> <endpoint> <encryption_password>"
    exit 1
fi

# Get the access key, secret key, endpoint and encryption password from the arguments
ACCESS_KEY=$1
SECRET_KEY=$2
ENDPOINT=$3
ENCRYPTION_PASSWORD=$4

# Create the .s3cfg file with the access key, secret key, endpoint and encryption password
cat > ~/.s3cfg << EOF
[default]
access_key = $ACCESS_KEY
secret_key = $SECRET_KEY
host_base = $ENDPOINT
host_bucket = %(bucket)s.$ENDPOINT
gpg_command = /usr/bin/gpg
gpg_passphrase = $ENCRYPTION_PASSWORD
bucket_location = US
EOF

# Check if the file was created successfully
if [ $? -eq 0 ]; then
    echo ".s3cfg file successfully created"
else
    echo "Failed to create .s3cfg file"
fi

