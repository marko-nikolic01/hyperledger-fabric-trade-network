#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

printColor "$YELLOW" "Checking chaincode deployment..."

CHAINCODE_NAME="trading"
CHANNELS=("tradechannel1" "tradechannel2")
ALL_OK=0

for CHANNEL in "${CHANNELS[@]}"; do
    printColor "$BLUE" "Checking $CHANNEL..."
    
    COMMITTED=$(docker exec \
        -e CORE_PEER_LOCALMSPID=Org1MSP \
        -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
        -e CORE_PEER_TLS_ENABLED=true \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
        cli peer lifecycle chaincode querycommitted \
        --channelID $CHANNEL \
        --name $CHAINCODE_NAME 2>&1)
    
    if [[ "$COMMITTED" == *"Version: 1.0"* ]]; then
        printColor "$GREEN" "  Chaincode committed (version 1.0)"
    else
        printColor "$RED" "  Chaincode not committed on $CHANNEL"
        ALL_OK=1
    fi
done

exit $ALL_OK
