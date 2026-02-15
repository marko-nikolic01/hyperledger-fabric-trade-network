#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

printColor "$YELLOW" "Stopping Trading Network..."

cd "$NETWORK_DIR"
docker compose down --remove-orphans

if [ $? -eq 0 ]; then
    printColor "$GREEN" "Trading Network stopped successfully"
    
    REMAINING=$(docker ps --filter "network=trade" -q | wc -l)
    if [ "$REMAINING" -gt 0 ]; then
        printColor "$YELLOW" "Warning: $REMAINING container(s) still running"
    fi
else
    printColor "$RED" "Failed to stop Trading Network"
    exit 1
fi
