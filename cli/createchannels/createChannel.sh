#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/scripts/utils/print-colored.sh"

CHANNEL_NAME=$1
ORDERER_CA="$NETWORK_DIR/crypto-config/ordererOrganizations/trade.com/orderers/orderer0.trade.com/msp/tlscacerts/tlsca.trade.com-cert.pem"

if [ -z "$CHANNEL_NAME" ]; then
    printColor "$RED" "Error: Channel name not provided"
    echo "Usage: $0 <channel-name>"
    exit 1
fi

printColor "$GREEN" "Creating channel: $CHANNEL_NAME"

if [ "$CHANNEL_NAME" = "tradechannel1" ]; then
    PROFILE="TradeChannel1"
elif [ "$CHANNEL_NAME" = "tradechannel2" ]; then
    PROFILE="TradeChannel2"
else
    printColor "$RED" "Unknown channel: $CHANNEL_NAME"
    exit 1
fi

printColor "$YELLOW" "Generating channel configuration block..."
docker run --rm \
    -v "$NETWORK_DIR":/work \
    -w /work \
    -e FABRIC_CFG_PATH=/work \
    hyperledger/fabric-tools:2.5 \
    configtxgen -profile $PROFILE \
    -outputBlock /work/channel-artifacts/${CHANNEL_NAME}.block \
    -channelID $CHANNEL_NAME

if [ $? -ne 0 ]; then
    printColor "$RED" "Failed to generate channel configuration"
    exit 1
fi

printColor "$GREEN" "Channel configuration block generated"

printColor "$YELLOW" "Joining peers to channel..."

joinPeer() {
    local ORG=$1
    local PEER=$2
    local MSP=$3
    local PORT=$4
    
    printColor "$BLUE" "  → Joining ${PEER}.${ORG}.trade.com"
    
    docker exec \
        -e CORE_PEER_LOCALMSPID=${MSP} \
        -e CORE_PEER_ADDRESS=${PEER}.${ORG}.trade.com:${PORT} \
        -e CORE_PEER_TLS_ENABLED=true \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORG}.trade.com/peers/${PEER}.${ORG}.trade.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORG}.trade.com/users/Admin@${ORG}.trade.com/msp \
        cli peer channel join \
        -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block
    
    if [ $? -eq 0 ]; then
        printColor "$GREEN" "    ${PEER}.${ORG}.trade.com joined"
    else
        printColor "$RED" "    Failed to join ${PEER}.${ORG}.trade.com"
    fi
}

joinPeer "org1" "peer0" "Org1MSP" 7051
joinPeer "org1" "peer1" "Org1MSP" 8051
joinPeer "org1" "peer2" "Org1MSP" 10051

joinPeer "org2" "peer0" "Org2MSP" 9051
joinPeer "org2" "peer1" "Org2MSP" 11051
joinPeer "org2" "peer2" "Org2MSP" 12051

joinPeer "org3" "peer0" "Org3MSP" 13051
joinPeer "org3" "peer1" "Org3MSP" 14051
joinPeer "org3" "peer2" "Org3MSP" 15051

printColor "$GREEN" "All peers joined channel $CHANNEL_NAME"
printColor "$YELLOW" "Note: Anchor peers are defined in configtx.yaml and set during channel creation"

printColor "$GREEN" "Channel $CHANNEL_NAME setup complete"
