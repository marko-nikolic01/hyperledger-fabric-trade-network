#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

CHAINCODE_NAME="trading"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE="1"
CHAINCODE_PATH="/opt/gopath/src/github.com/chaincode/trading"
CHANNEL_NAME=$1

printColor "$BLUE" "Deploying chaincode '$CHAINCODE_NAME' to channel '$CHANNEL_NAME'..."
echo ""

printColor "$YELLOW" "Step 1: Preparing chaincode dependencies..."
docker exec cli sh -c "cd ${CHAINCODE_PATH} && go mod tidy"

if [ $? -ne 0 ]; then
    printColor "$RED" "Failed to prepare chaincode dependencies"
    exit 1
fi
printColor "$GREEN" "Dependencies prepared successfully"
echo ""

printColor "$YELLOW" "Step 2: Packaging chaincode..."
docker exec cli peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz \
    --path ${CHAINCODE_PATH} \
    --lang golang \
    --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}

if [ $? -ne 0 ]; then
    printColor "$RED" "Failed to package chaincode"
    exit 1
fi
printColor "$GREEN" "Chaincode packaged successfully"
echo ""

printColor "$YELLOW" "Step 3: Installing chaincode on all peers..."

for ORG in 1 2 3; do
    for PEER in 0 1 2; do
        printColor "$BLUE" "  Installing on peer${PEER}.org${ORG}..."
        
        if [ $ORG -eq 1 ]; then
            case $PEER in
                0) PORT=7051 ;;
                1) PORT=8051 ;;
                2) PORT=10051 ;;
            esac
        elif [ $ORG -eq 2 ]; then
            case $PEER in
                0) PORT=9051 ;;
                1) PORT=11051 ;;
                2) PORT=12051 ;;
            esac
        else
            case $PEER in
                0) PORT=13051 ;;
                1) PORT=14051 ;;
                2) PORT=15051 ;;
            esac
        fi
        
        docker exec -e CORE_PEER_ADDRESS=peer${PEER}.org${ORG}.trade.com:${PORT} \
            -e CORE_PEER_LOCALMSPID=Org${ORG}MSP \
            -e CORE_PEER_TLS_ENABLED=true \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${ORG}.trade.com/peers/peer${PEER}.org${ORG}.trade.com/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${ORG}.trade.com/users/Admin@org${ORG}.trade.com/msp \
            cli peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz 2>&1 | grep -v "chaincode already successfully installed" || true
        
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            INSTALL_OUTPUT=$(docker exec -e CORE_PEER_ADDRESS=peer${PEER}.org${ORG}.trade.com:${PORT} \
                -e CORE_PEER_LOCALMSPID=Org${ORG}MSP \
                -e CORE_PEER_TLS_ENABLED=true \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${ORG}.trade.com/peers/peer${PEER}.org${ORG}.trade.com/tls/ca.crt \
                -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${ORG}.trade.com/users/Admin@org${ORG}.trade.com/msp \
                cli peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz 2>&1)
            
            if [[ "$INSTALL_OUTPUT" != *"already successfully installed"* ]]; then
                printColor "$RED" "Failed to install on peer${PEER}.org${ORG}"
                echo "$INSTALL_OUTPUT"
                exit 1
            fi
        fi
    done
done

printColor "$GREEN" "Chaincode installed on all peers"
echo ""

printColor "$YELLOW" "Step 4: Getting package ID..."
PACKAGE_ID=$(docker exec \
    -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
    cli peer lifecycle chaincode queryinstalled | grep ${CHAINCODE_NAME}_${CHAINCODE_VERSION} | awk '{print $3}' | sed 's/,$//')

if [ -z "$PACKAGE_ID" ]; then
    printColor "$RED" "Failed to get package ID"
    exit 1
fi

printColor "$GREEN" "Package ID: $PACKAGE_ID"
echo ""

printColor "$YELLOW" "Step 5: Approving chaincode for all organizations..."

for ORG in 1 2 3; do
    printColor "$BLUE" "  Approving for Org${ORG}..."
    
    PORT=$((7051 + (ORG - 1) * 2))
    if [ $ORG -eq 2 ]; then
        PORT=9051
    elif [ $ORG -eq 3 ]; then
        PORT=13051
    fi
    
    docker exec -e CORE_PEER_ADDRESS=peer0.org${ORG}.trade.com:${PORT} \
        -e CORE_PEER_LOCALMSPID=Org${ORG}MSP \
        -e CORE_PEER_TLS_ENABLED=true \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${ORG}.trade.com/peers/peer0.org${ORG}.trade.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${ORG}.trade.com/users/Admin@org${ORG}.trade.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer0.trade.com:7050 \
        --channelID ${CHANNEL_NAME} \
        --name ${CHAINCODE_NAME} \
        --version ${CHAINCODE_VERSION} \
        --package-id ${PACKAGE_ID} \
        --sequence ${CHAINCODE_SEQUENCE} \
        --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/trade.com/orderers/orderer0.trade.com/msp/tlscacerts/tlsca.trade.com-cert.pem \
        --peerAddresses peer0.org${ORG}.trade.com:${PORT} \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org${ORG}.trade.com/peers/peer0.org${ORG}.trade.com/tls/ca.crt
    
    if [ $? -ne 0 ]; then
        printColor "$RED" "Failed to approve for Org${ORG}"
        exit 1
    fi
done

printColor "$GREEN" "Chaincode approved by all organizations"
echo ""

printColor "$YELLOW" "Step 6: Checking commit readiness..."
docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
    cli peer lifecycle chaincode checkcommitreadiness \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --sequence ${CHAINCODE_SEQUENCE} \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/trade.com/orderers/orderer0.trade.com/msp/tlscacerts/tlsca.trade.com-cert.pem

echo ""

printColor "$YELLOW" "Step 7: Committing chaincode definition..."
docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
    cli peer lifecycle chaincode commit \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --sequence ${CHAINCODE_SEQUENCE} \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/trade.com/orderers/orderer0.trade.com/msp/tlscacerts/tlsca.trade.com-cert.pem \
    -o orderer0.trade.com:7050 \
    --peerAddresses peer0.org1.trade.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
    --peerAddresses peer0.org2.trade.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.trade.com/peers/peer0.org2.trade.com/tls/ca.crt \
    --peerAddresses peer0.org3.trade.com:13051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.trade.com/peers/peer0.org3.trade.com/tls/ca.crt

if [ $? -ne 0 ]; then
    printColor "$RED" "Failed to commit chaincode"
    exit 1
fi

printColor "$GREEN" "Chaincode committed successfully"
echo ""

printColor "$YELLOW" "Step 8: Verifying chaincode deployment..."
docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
    cli peer lifecycle chaincode querycommitted \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME}

echo ""
printColor "$GREEN" "Chaincode deployment completed successfully"
printColor "$BLUE" "Chaincode is now deployed and ready to be initialized"
