#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

printColor "$BLUE" "Cleaning generated artifacts..."

if [ -d "$NETWORK_DIR/crypto-config" ]; then
    printColor "$YELLOW" "  Removing crypto-config/"
    sudo rm -rf "$NETWORK_DIR/crypto-config"
    printColor "$GREEN" "  crypto-config removed"
fi

if [ -d "$NETWORK_DIR/channel-artifacts" ]; then
    printColor "$YELLOW" "  Removing channel-artifacts/"
    sudo rm -rf "$NETWORK_DIR/channel-artifacts"
    printColor "$GREEN" "  channel-artifacts removed"
fi

if [ -d "$NETWORK_DIR/system-genesis-block" ]; then
    printColor "$YELLOW" "  Removing system-genesis-block/"
    sudo rm -rf "$NETWORK_DIR/system-genesis-block"
    printColor "$GREEN" "  system-genesis-block removed"
fi

if [ -d "$NETWORK_DIR/fabric-ca" ]; then
    printColor "$YELLOW" "  Removing fabric-ca/"
    sudo rm -rf "$NETWORK_DIR/fabric-ca"
    printColor "$GREEN" "  fabric-ca removed"
fi

if [ -d "$NETWORK_DIR/fabric-ca-client" ]; then
    printColor "$YELLOW" "  Removing fabric-ca-client/"
    sudo rm -rf "$NETWORK_DIR/fabric-ca-client"
    printColor "$GREEN" "  fabric-ca-client removed"
fi

if [ -d "$PROJECT_ROOT/console-application/wallet" ]; then
    printColor "$YELLOW" "  Removing console-application/wallet/"
    sudo rm -rf "$PROJECT_ROOT/console-application/wallet"
    printColor "$GREEN" "  console-application wallet removed"
fi

printColor "$GREEN" "Artifacts cleaned"
