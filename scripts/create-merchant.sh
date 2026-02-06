#!/bin/bash

CHANNEL_NAME=tradechannel1
CHAINCODE_NAME=trading

docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
    cli peer chaincode invoke \
    -o orderer0.trade.com:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/trade.com/orderers/orderer0.trade.com/msp/tlscacerts/tlsca.trade.com-cert.pem \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    --peerAddresses peer0.org1.trade.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
    --peerAddresses peer0.org2.trade.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.trade.com/peers/peer0.org2.trade.com/tls/ca.crt \
    --peerAddresses peer0.org3.trade.com:13051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.trade.com/peers/peer0.org3.trade.com/tls/ca.crt \
    -c '{"function":"CreateMerchant","Args":["M004", "BOOKSTORE", "100000004", "10000.0"]}'