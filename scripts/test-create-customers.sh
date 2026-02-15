#!/bin/bash

echo -e "Test: Create Customers"

CUSTOMER_ID_1="C_TEST_$(date +%s)"
CUSTOMER_ID_2="C_TEST_$(($(date +%s) + 1))"

CUSTOMERS_JSON='[
  {
    "id": "'$CUSTOMER_ID_1'",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@test.com",
    "accountBalance": 50000,
    "invoices": []
  },
  {
    "id": "'$CUSTOMER_ID_2'",
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane.smith@test.com",
    "accountBalance": 75000,
    "invoices": []
  }
]'

echo -e "Creating 2 customers: $CUSTOMER_ID_1, $CUSTOMER_ID_2"

cd console-application
RESULT=$(npm run cli create-customers "$CUSTOMERS_JSON" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "Customers created"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    
    # Verify - check first customer
    echo -e "Verifying first customer..."
    VERIFY1=$(npm run cli get-customer "$CUSTOMER_ID_1" 2>&1)
    
    # Verify - check second customer
    echo -e "Verifying second customer..."
    VERIFY2=$(npm run cli get-customer "$CUSTOMER_ID_2" 2>&1)
    
    if [[ $VERIFY1 == *"$CUSTOMER_ID_1"* ]] && [[ $VERIFY2 == *"$CUSTOMER_ID_2"* ]]; then
        echo -e "Test PASSED"
        exit 0
    else
        echo -e "Test FAILED - Customers not found"
        exit 1
    fi
else
    echo -e "Failed to create customers"
    echo "$RESULT"
    exit 1
fi