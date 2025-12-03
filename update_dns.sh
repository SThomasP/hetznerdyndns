#!/bin/bash
# load the .env file
. $1

#This script assumes the record exists already and just needs to be updated, please be sure to create it

# Set the API Authorization Header
AUTORIZATION="Authorization: Bearer $API_KEY"

## Get Record
# Returns information about a single record.
DNS_INFO=$(curl "https://api.hetzner.cloud/v1/zones/$RR_ZONE/rrsets/$RR_NAME/$RR_TYPE" -H "$AUTORIZATION" -s)

# Extract the DNS IP address and TTL value from the API response
DNS_IP=$(echo "$DNS_INFO" | jq -r '.rrset.records[0].value')

# set the ip version based on the record in the env file
if [ "$RR_TYPE" == "A" ]; then IPVER="4"
elif [ "$RR_TYPE" == "AAAA" ]; then IPVER="6"
else
 # Log an error if the DNS record doesn't exist
 echo "$(date): Error: Record not a know type should be A or AAAA was '$RR_TYPE'" >> "$LOG_FILE"
 exit 1
fi



# Get the current external IP address
CURRENT_IP=$(curl -$IPVER -s $IPLOOKUP)

if [ "$CURRENT_IP" == $DNS_IP ]; then
  # Log when the script is run without any IP change
  echo "$(date): IP address unchanged at $CURRENT_IP" >> "$LOG_FILE"
  exit 0
fi
# Log when there is an IP change
echo "$(date): IP address changed from $DNS_IP to $CURRENT_IP" >> "$LOG_FILE"


# Update the record via the API
RESPONSE=$(curl -s -o $LOG_FILE -w "%{http_code}" \
    -X POST "https://api.hetzner.cloud/v1/zones/$RR_ZONE/rrsets/$RR_NAME/$RR_TYPE/actions/set_records" \
    -H "Content-Type: application/json" -H "$AUTORIZATION" \
    -d '{
          "records" : [{
            "value": "'$CURRENT_IP'",
            "comment": "updated to the current domain"
           }]
          }')

if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "201" ]; then
  # Log when the DNS record is updated
  echo "$(date): DNS $RR_NAME.$RR_ZONE record updated to $CURRENT_IP with TTL $TTL seconds"  >> "$LOG_FILE"
else
  # Log an error if the API request fails
  echo "$(date): API request failed with status code $RESPONSE"  >> "$LOG_FILE"
fi
