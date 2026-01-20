#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/scripts/utils/print-colored.sh"

FABRIC_TOOLS_IMAGE="hyperledger/fabric-tools:2.5"

generateCrypto() {
    printColor "$GREEN" "Generating crypto material..."
    
    cd "$NETWORK_DIR"
    
    if [ -d "crypto-config" ]; then
        printColor "$YELLOW" "Crypto material already exists. Skipping."
        return 0
    fi
    
    docker run --rm -v "$(pwd)":/work -w /work $FABRIC_TOOLS_IMAGE cryptogen generate --config=./crypto-config.yaml --output="crypto-config"
    
    if [ $? -ne 0 ]; then
        printColor "$RED" "Failed to generate crypto material"
        return 1
    fi
    
    printColor "$GREEN" "Crypto material generated"
}

generateChannelArtifacts() {
    printColor "$GREEN" "Generating channel artifacts..."
    
    cd "$NETWORK_DIR"
    
    mkdir -p channel-artifacts
    mkdir -p system-genesis-block
    
    # Genesis block
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile ThreeOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
    if [ $? -ne 0 ]; then
        printColor "$RED" "Failed to generate genesis block"
        return 1
    fi
    
    # Channel 1
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile TradeChannel1 -outputCreateChannelTx ./channel-artifacts/tradechannel1.tx -channelID tradechannel1
    if [ $? -ne 0 ]; then
        printColor "$RED" "Failed to generate tradechannel1"
        return 1
    fi
    
    # Channel 2
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile TradeChannel2 -outputCreateChannelTx ./channel-artifacts/tradechannel2.tx -channelID tradechannel2
    if [ $? -ne 0 ]; then
        printColor "$RED" "Failed to generate tradechannel2"
        return 1
    fi
    
    # Anchor peers for channel 1
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile TradeChannel1 -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors_tradechannel1.tx -channelID tradechannel1 -asOrg Org1MSP
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile TradeChannel1 -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors_tradechannel1.tx -channelID tradechannel1 -asOrg Org2MSP
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile TradeChannel1 -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors_tradechannel1.tx -channelID tradechannel1 -asOrg Org3MSP
    
    # Anchor peers for channel 2
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile TradeChannel2 -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors_tradechannel2.tx -channelID tradechannel2 -asOrg Org1MSP
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile TradeChannel2 -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors_tradechannel2.tx -channelID tradechannel2 -asOrg Org2MSP
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile TradeChannel2 -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors_tradechannel2.tx -channelID tradechannel2 -asOrg Org3MSP
    
    printColor "$GREEN" "Channel artifacts generated"
}

generateCrypto || exit 1
generateChannelArtifacts || exit 1
