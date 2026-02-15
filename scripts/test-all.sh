#!/bin/bash

echo -e "  Running All Chaincode Tests"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
TEST_DATA_FILE="$PROJECT_ROOT/.test-data"

rm -f "$TEST_DATA_FILE"
touch "$TEST_DATA_FILE"

TOTAL=0
PASSED=0
FAILED=0

run_test() {
    TEST_NAME=$1
    TEST_SCRIPT=$2
    
    echo -e "\n--- Running: $TEST_NAME ---"
    TOTAL=$((TOTAL + 1))
    
    if bash "$TEST_SCRIPT"; then
        PASSED=$((PASSED + 1))
        echo -e "$TEST_NAME PASSED\n"
    else
        FAILED=$((FAILED + 1))
        echo -e "$TEST_NAME FAILED\n"
    fi
}

# Run all tests in order
run_test "Create Merchant" "./scripts/test-create-merchant.sh"
run_test "Add Products" "./scripts/test-add-products.sh"
run_test "Create Customers" "./scripts/test-create-customers.sh"
run_test "Buy Product" "./scripts/test-buy-product.sh"
run_test "Deposit to Merchant" "./scripts/test-deposit-merchant.sh"
run_test "Deposit to Customer" "./scripts/test-deposit-customer.sh"
run_test "Query Products" "./scripts/test-query-products.sh"

# Summary
echo -e "  Test Summary"
echo -e "Total:  $TOTAL"
echo -e "Passed: $PASSED"
echo -e "Failed: $FAILED\n"

if [ $FAILED -eq 0 ]; then
    echo -e "All tests passed!\n"
    exit 0
else
    echo -e "Some tests failed!\n"
    exit 1
fi