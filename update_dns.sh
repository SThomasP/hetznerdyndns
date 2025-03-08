#!/bin/bash
# load the .env file
. $1
# Set the API Authorization Header
AUTORIZATION="Auth-API-Token: $API_KEY"


# Set the log file path
LOG_FILE="./log/update_dns.log"
# set the ip version based on the record in the env file
if [ "$RECORD" == "A" ]; then IPVER="4"
elif [ "$RECORD" == "AAAA" ]; then IPVER="6"
else
 # Log an error if the DNS record doesn't exist
 echo "$(date): Error: Record set incorrectly value, should be A or AAAA was $RECORD" >> "$LOG_FILE"
 exit 1
fi
