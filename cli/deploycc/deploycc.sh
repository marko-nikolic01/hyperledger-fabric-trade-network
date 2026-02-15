#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

printColor "$BLUE" "Complete Chaincode Deployment Pipeline"
printColor "$BLUE" "Deploying to ALL channels"
echo ""

CHANNELS=("tradechannel1" "tradechannel2")

for CHANNEL in "${CHANNELS[@]}"; do
    printColor "$CYAN" "Channel: $CHANNEL"
    echo ""
    
    # Step 1: Deploy chaincode
    printColor "$YELLOW" "Phase 1: Deploying chaincode..."
    echo ""
    bash "$SCRIPT_DIR/packageChaincode.sh" "$CHANNEL"
    
    if [ $? -ne 0 ]; then
        printColor "$RED" "Deployment failed for $CHANNEL"
        exit 1
    fi
    
    echo ""
    echo ""
    
    # Step 2: Initialize chaincode
    printColor "$YELLOW" "Phase 2: Initializing chaincode with sample data..."
    echo ""
    bash "$SCRIPT_DIR/initChaincode.sh" "$CHANNEL"
    
    if [ $? -ne 0 ]; then
        printColor "$RED" "Initialization failed for $CHANNEL"
        exit 1
    fi

    echo ""
    printColor "$YELLOW" "Phase 3: Updating channel MSPs with Fabric CA root certs..."
    echo ""
    bash "$PROJECT_ROOT/cli/deploycc/update-channel-msp.sh" "$CHANNEL"

    if [ $? -ne 0 ]; then
        printColor "$RED" "Channel MSP update failed for $CHANNEL"
        exit 1
    fi
    
    echo ""
    printColor "$GREEN" "Deployment completed for $CHANNEL"
    echo ""
    echo ""
done

printColor "$GREEN" "All deployments successful"
printColor "$BLUE" "Chaincode: trading v1.0"
printColor "$BLUE" "Channels: tradechannel1, tradechannel2"
echo ""
