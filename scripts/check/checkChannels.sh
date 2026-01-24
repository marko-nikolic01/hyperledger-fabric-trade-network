#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/scripts/utils/print-colored.sh"

printColor "$BLUE" "Checking channels..."
echo ""

PEERS=("peer0.org1.trade.com" "peer1.org1.trade.com" "peer2.org1.trade.com" 
       "peer0.org2.trade.com" "peer1.org2.trade.com" "peer2.org2.trade.com"
       "peer0.org3.trade.com" "peer1.org3.trade.com" "peer2.org3.trade.com")

CHANNELS=("tradechannel1" "tradechannel2")
CHANNEL_CHECK_PASSED=true

for channel in "${CHANNELS[@]}"; do
    printColor "$YELLOW" "Channel: $channel"
    
    JOINED_COUNT=0
    FAILED_PEERS=()
    
    for peer in "${PEERS[@]}"; do
        if [[ $peer == peer*.org1.* ]]; then
            ORG="org1"
            MSP_ID="Org1MSP"
        elif [[ $peer == peer*.org2.* ]]; then
            ORG="org2"
            MSP_ID="Org2MSP"
        elif [[ $peer == peer*.org3.* ]]; then
            ORG="org3"
            MSP_ID="Org3MSP"
        fi
        
        case $peer in
            peer0.org1.trade.com) PORT=7051 ;;
            peer1.org1.trade.com) PORT=8051 ;;
            peer2.org1.trade.com) PORT=10051 ;;
            peer0.org2.trade.com) PORT=9051 ;;
            peer1.org2.trade.com) PORT=11051 ;;
            peer2.org2.trade.com) PORT=12051 ;;
            peer0.org3.trade.com) PORT=13051 ;;
            peer1.org3.trade.com) PORT=14051 ;;
            peer2.org3.trade.com) PORT=15051 ;;
        esac
        
        RESULT=$(docker exec \
            -e CORE_PEER_ADDRESS=${peer}:${PORT} \
            -e CORE_PEER_LOCALMSPID=${MSP_ID} \
            -e CORE_PEER_TLS_ENABLED=true \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORG}.trade.com/peers/${peer}/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORG}.trade.com/users/Admin@${ORG}.trade.com/msp \
            cli peer channel list 2>&1)
        
        if echo "$RESULT" | grep -q "$channel"; then
            ((JOINED_COUNT++))
        else
            FAILED_PEERS+=("$peer")
        fi
    done
    
    if [ $JOINED_COUNT -eq 9 ]; then
        printColor "$GREEN" "  All 9 peers joined $channel"
    else
        printColor "$RED" "  Only $JOINED_COUNT/9 peers joined $channel"
        for failed_peer in "${FAILED_PEERS[@]}"; do
            printColor "$RED" "    - $failed_peer NOT joined"
        done
        CHANNEL_CHECK_PASSED=false
    fi
    echo ""
done

if [ "$CHANNEL_CHECK_PASSED" = true ]; then
    printColor "$GREEN" "All channel checks passed"
    exit 0
else
    printColor "$RED" "Some channel checks failed"
    exit 1
fi
