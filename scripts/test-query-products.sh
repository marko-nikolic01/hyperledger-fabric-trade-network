#!/bin/bash

echo -e "Test: Query Products"

echo -e "Searching all products"

cd console-application
RESULT=$(npm run cli query-products "" "" "" "-1" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "Query successful"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    
    # Verify by checking if result is array
    if [[ $RESULT == *"["* ]]; then
        echo -e "Test PASSED"
        exit 0
    else
        echo -e "Test FAILED"
        exit 1
    fi
else
    echo -e "Failed to query products"
    echo "$RESULT"
    exit 1
fi