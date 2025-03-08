#!/bin/bash
# load the .env file
. $1
# Set the API Authorization Header
AUTORIZATION="Auth-API-Token: $API_KEY"

## Get Record
# Returns information about a single record.
DNS_INFO=$(curl "https://dns.hetzner.com/api/v1/records/$RECORD_ID" -H "$AUTORIZATION" -s)
# Extract the DNS IP address and TTL value from the API response
DNS_IP=$(echo "$DNS_INFO" | jq  '.record.value')
RECORD=$(echo "$DNS_INFO" | jq -r '.record.type')
TTL=$(echo "$DNS_INFO" | jq -r '.record.ttl // 7200')
SUBDOMAIN=$(echo "$DNS_INFO" | jq -r '.record.name')

# Set the log file path
LOG_FILE="./logs/update_dns.log"
# set the ip version based on the record in the env file
if [ "$RECORD" == "A" ]; then IPVER="4"
elif [ "$RECORD" == "AAAA" ]; then IPVER="6"
else
 # Log an error if the DNS record doesn't exist
 echo "$(date): Error: Record not a know type should be A or AAAA was $RECORD" >> "$LOG_FILE"
 exit 1
fi

# Get the current external IP address
CURRENT_IP=$(curl -$IPVER -s $IPLOOKUP)

if [ "$CURRENT_IP" == $DNS_IP ]; then
  # Log when the script is run without any IP change
  echo "$(date): IP address unchanged at $CURRENT_IP" >> "$LOG_FILE"
  exit 1
fi
