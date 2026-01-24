#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

printColor "$BLUE" "Checking containers..."
echo ""

if ! docker info > /dev/null 2>&1; then
    printColor "$RED" "Docker is not running"
    exit 1
fi

ORDERERS=("orderer0.trade.com" "orderer1.trade.com" "orderer2.trade.com")
PEERS=("peer0.org1.trade.com" "peer1.org1.trade.com" "peer2.org1.trade.com" 
       "peer0.org2.trade.com" "peer1.org2.trade.com" "peer2.org2.trade.com"
       "peer0.org3.trade.com" "peer1.org3.trade.com" "peer2.org3.trade.com")
COUCHDBS=("couchdb0.org1" "couchdb1.org1" "couchdb2.org1"
          "couchdb0.org2" "couchdb1.org2" "couchdb2.org2"
          "couchdb0.org3" "couchdb1.org3" "couchdb2.org3")
CLI="cli"

ALL_RUNNING=true

printColor "$YELLOW" "Orderers:"
for container in "${ORDERERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        printColor "$GREEN" "  $container"
    else
        printColor "$RED" "  $container"
        ALL_RUNNING=false
    fi
done

echo ""
printColor "$YELLOW" "Peers:"
for container in "${PEERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        printColor "$GREEN" "  $container"
    else
        printColor "$RED" "  $container"
        ALL_RUNNING=false
    fi
done

echo ""
printColor "$YELLOW" "CouchDB:"
for container in "${COUCHDBS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        printColor "$GREEN" "  $container"
    else
        printColor "$RED" "  $container"
        ALL_RUNNING=false
    fi
done

echo ""
printColor "$YELLOW" "CLI:"
if docker ps --format '{{.Names}}' | grep -q "^${CLI}$"; then
    printColor "$GREEN" "  $CLI"
else
    printColor "$RED" "  $CLI"
    ALL_RUNNING=false
fi

echo ""
if [ "$ALL_RUNNING" = true ]; then
    printColor "$GREEN" "All 21 containers are running"
    exit 0
else
    printColor "$RED" "Some containers are not running"
    exit 1
fi
