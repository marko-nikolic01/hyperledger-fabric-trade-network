#!/bin/bash

echo -e "Test: Deposit to Customer"

CUSTOMER_ID="C_TEST_1"
AMOUNT="10000"

echo -e "Depositing $AMOUNT to customer $CUSTOMER_ID"

cd console-application
RESULT=$(npm run cli deposit-customer "$CUSTOMER_ID" "$AMOUNT" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "Deposit successful"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    
    # Verify by checking if result contains newBalance
    if [[ $RESULT == *"newBalance"* ]]; then
        echo -e "Test PASSED"
        exit 0
    else
        echo -e "Test FAILED"
        exit 1
    fi
else
    echo -e "Failed to deposit to customer"
    echo "$RESULT"
    exit 1
fi