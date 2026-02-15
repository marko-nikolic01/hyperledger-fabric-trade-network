#!/bin/bash

echo -e "Test: Buy Product"

CUSTOMER_ID="C_TEST_1"
PRODUCT_ID="P_TEST_1"

echo -e "Customer $CUSTOMER_ID buying product $PRODUCT_ID"

cd console-application
RESULT=$(npm run cli buy-product "$CUSTOMER_ID" "$PRODUCT_ID" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "Product purchased successfully"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    
    # Verify by checking if result contains invoice ID
    if [[ $RESULT == *"INV-"* ]]; then
        echo -e "Test PASSED - Invoice generated"
        exit 0
    else
        echo -e "Test FAILED - No invoice found"
        exit 1
    fi
else
    echo -e "Failed to buy product"
    echo "$RESULT"
    exit 1
fi