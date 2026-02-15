#!/bin/bash

echo -e "Test: Create Merchant"

MERCHANT_ID="M_TEST_$(date +%s)"
MERCHANT_TYPE="SUPERMARKET"
TAX_ID="999888777"
BALANCE="100000"

echo -e "Creating merchant: $MERCHANT_ID"

cd console-application
RESULT=$(npm run cli create-merchant "$MERCHANT_ID" "$MERCHANT_TYPE" "$TAX_ID" "$BALANCE" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "Merchant created"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    
    # Verify
    echo -e "  Verifying..."
    VERIFY=$(npm run cli get-merchant "$MERCHANT_ID" 2>&1)
    
    if [[ $VERIFY == *"$MERCHANT_ID"* ]]; then
        echo -e "Test PASSED"
        exit 0
    else
        echo -e "Test FAILED"
        exit 1
    fi
else
    echo -e "Failed to create merchant"
    echo "$RESULT"
    exit 1
fi