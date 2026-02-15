#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

ensure_crypto_permissions() {
    printColor "$YELLOW" "Adjusting crypto-config permissions..."
    sudo chown -R "$USER":"$USER" "$NETWORK_DIR/crypto-config" 2>/dev/null || true
    sudo chmod -R a+rwx "$NETWORK_DIR/crypto-config" 2>/dev/null || true
}

printColor "$GREEN" "Starting Trading Network..."

# Generate crypto material if needed
if [ ! -d "$NETWORK_DIR/crypto-config/peerOrganizations" ]; then
    printColor "$YELLOW" "Crypto material not found. Generating..."
    chmod +x "$SCRIPT_DIR/generate.sh"
    "$SCRIPT_DIR/generate.sh" || exit 1
    ensure_crypto_permissions
fi

# Start Docker containers
cd "$NETWORK_DIR"
docker compose up -d

if [ $? -eq 0 ]; then
    printColor "$GREEN" "Waiting for containers to start..."
    sleep 10

    # Enroll CA admins if needed
    chmod +x "$SCRIPT_DIR/initialize-ca.sh"
    "$SCRIPT_DIR/initialize-ca.sh" || exit 1

    ensure_crypto_permissions
    
    printColor "$GREEN" "Trading Network started successfully"
    echo ""
    printColor "$BLUE" "Network Status:"
    docker ps --filter "network=trade" --format "table {{.Names}}\t{{.Status}}" | head -15
else
    printColor "$RED" "Failed to start Trading Network"
    exit 1
fi
