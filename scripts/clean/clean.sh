#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/scripts/utils/print-colored.sh"

printColor "$YELLOW" "Cleaning generated artifacts..."

if [ -d "$NETWORK_DIR/crypto-config" ]; then
    printColor "$BLUE" "Removing crypto-config/"
    sudo rm -rf "$NETWORK_DIR/crypto-config"
fi

if [ -d "$NETWORK_DIR/channel-artifacts" ]; then
    printColor "$BLUE" "Removing channel-artifacts/"
    sudo rm -rf "$NETWORK_DIR/channel-artifacts"
fi

if [ -d "$NETWORK_DIR/system-genesis-block" ]; then
    printColor "$BLUE" "Removing system-genesis-block/"
    sudo rm -rf "$NETWORK_DIR/system-genesis-block"
fi

printColor "$GREEN" "All generated artifacts cleaned"
