#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

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
    
    docker run --rm -v "$(pwd)":/work -w /work -e FABRIC_CFG_PATH=/work $FABRIC_TOOLS_IMAGE configtxgen -profile ThreeOrgsOrdererGenesis -channelID syschannel -outputBlock ./system-genesis-block/genesis.block
    if [ $? -ne 0 ]; then
        printColor "$RED" "Failed to generate genesis block"
        return 1
    fi
    
    printColor "$GREEN" "Genesis block generated"
    printColor "$YELLOW" "Note: Channel creation will be done using peer channel create command"
}

generateCrypto || exit 1
generateChannelArtifacts || exit 1

# crypto-config permissions setup
echo "Changing ownership of crypto-config to current user..."
sudo chown -R $USER:$USER ./network/crypto-config/
sudo chmod -R a+rwx ./network/crypto-config/
echo "Crypto material generated and ownership adjusted"
