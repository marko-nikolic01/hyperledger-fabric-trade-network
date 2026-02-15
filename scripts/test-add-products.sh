#!/bin/bash

echo -e "Test: Add Products to Merchant"

MERCHANT_ID="M002"
PRODUCT_ID_1="P_TEST_$(date +%s)"
PRODUCT_ID_2="P_TEST_$(($(date +%s) + 1))"

PRODUCTS_JSON='[
  {
    "id": "'$PRODUCT_ID_1'",
    "name": "Test Product 1",
    "price": 150.50,
    "quantity": 100,
    "expirationDate": "2026-12-31",
    "merchantId": "'$MERCHANT_ID'"
  },
  {
    "id": "'$PRODUCT_ID_2'",
    "name": "Test Product 2",
    "price": 299.99,
    "quantity": 50,
    "expirationDate": "",
    "merchantId": "'$MERCHANT_ID'"
  }
]'

echo -e "Adding 2 products to merchant: $MERCHANT_ID"

cd console-application
RESULT=$(npm run cli add-products "$MERCHANT_ID" "$PRODUCTS_JSON" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "Products added"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    
    # Verify - check first product
    echo -e "Verifying first product..."
    VERIFY1=$(npm run cli get-product "$PRODUCT_ID_1" 2>&1)
    
    # Verify - check second product
    echo -e "Verifying second product..."
    VERIFY2=$(npm run cli get-product "$PRODUCT_ID_2" 2>&1)
    
    if [[ $VERIFY1 == *"$PRODUCT_ID_1"* ]] && [[ $VERIFY2 == *"$PRODUCT_ID_2"* ]]; then
        echo -e "Test PASSED"
        exit 0
    else
        echo -e "Test FAILED - Products not found"
        exit 1
    fi
else
    echo -e "Failed to add products"
    echo "$RESULT"
    exit 1
fi