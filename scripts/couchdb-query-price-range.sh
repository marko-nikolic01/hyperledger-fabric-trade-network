#!/bin/bash

COUCHDB_URL="http://localhost:5984"
COUCHDB_USER="admin"
COUCHDB_PASS="admin"
DB_NAME="tradechannel1_trading"

echo "Creating index..."
curl -s -X POST "$COUCHDB_URL/$DB_NAME/_index" \
  -H "Content-Type: application/json" \
  -u "$COUCHDB_USER:$COUCHDB_PASS" \
  -d '{
    "index": {
      "fields": ["price", "quantity"]
    },
    "name": "price-quantity-index",
    "type": "json"
  }'

echo -e "\nRunning query..."
RESULT=$(curl -s -X POST "$COUCHDB_URL/$DB_NAME/_find" \
  -H "Content-Type: application/json" \
  -u "$COUCHDB_USER:$COUCHDB_PASS" \
  -d '{
    "selector": {
      "price": {
        "$gte": 100,
        "$lte": 500
      },
      "quantity": {
        "$gt": 0
      }
    },
    "sort": [{"price": "asc"}],
    "fields": ["id", "name", "price", "quantity", "merchantId"]
  }')

echo "$RESULT" | jq .