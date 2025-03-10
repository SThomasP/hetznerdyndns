#!/bin/bash
# load the .env file
. $1

# Set the API Authorization Header
AUTORIZATION="Auth-API-Token: $API_KEY"

## Get Record
# Returns information about a single record.
DNS_INFO=$(curl "https://dns.hetzner.com/api/v1/records/$RECORD_ID" -H "$AUTORIZATION" -s)
# Extract the DNS IP address and TTL value from the API response
DNS_IP=$(echo "$DNS_INFO" | jq -r '.record.value')
RECORD=$(echo "$DNS_INFO" | jq -r '.record.type')
ZONE_ID=$(echo "$DNS_INFO" | jq -r '.record.zone_id')
TTL=$(echo "$DNS_INFO" | jq -r '.record.ttl // 7200')
SUBDOMAIN=$(echo "$DNS_INFO" | jq -r '.record.name')

# set the ip version based on the record in the env file
if [ "$RECORD" == "A" ]; then IPVER="4"
elif [ "$RECORD" == "AAAA" ]; then IPVER="6"
else
 # Log an error if the DNS record doesn't exist
 echo "$(date): Error: Record not a know type should be A or AAAA was '$RECORD'" >> "$LOG_FILE"
 exit 1
fi

# Get the current external IP address
CURRENT_IP=$(curl -$IPVER -s $IPLOOKUP)

if [ "$CURRENT_IP" == $DNS_IP ]; then
  # Log when the script is run without any IP change
  echo "$(date): IP address unchanged at $CURRENT_IP" >> "$LOG_FILE"
  exit 1
fi
# Log when there is an IP change
echo "$(date): IP address changed from $DNS_IP to $CURRENT_IP" >> "$LOG_FILE"

# Update the record via the API
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "https://dns.hetzner.com/api/v1/records/$RECORD_ID" \
    -H "Content-Type: application/json" -H "$AUTORIZATION" \
    -d '{
          "value": "'$CURRENT_IP'",
          "ttl": '$TTL',
          "type": "'$RECORD'",
          "name": "'$SUBDOMAIN'",
          "zone_id": "'$ZONE_ID'"
          }')

if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "201" ]; then
  # Log when the DNS record is updated
  echo "$(date): DNS $RECORD record updated to $CURRENT_IP with TTL $TTL seconds" >> "$LOG_FILE"
else
  # Log an error if the API request fails
  echo "$(date): API request failed with status code $RESPONSE" >> "$LOG_FILE"
fi
