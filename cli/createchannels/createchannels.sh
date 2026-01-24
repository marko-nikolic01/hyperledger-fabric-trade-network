#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

printColor "$GREEN" "Setting up channels..."
echo ""

# Create and setup tradechannel1
printColor "$BLUE" "Setting up tradechannel1"
chmod +x "$SCRIPT_DIR/createChannel.sh"
"$SCRIPT_DIR/createChannel.sh" tradechannel1

if [ $? -ne 0 ]; then
    printColor "$RED" "Failed to setup tradechannel1"
    exit 1
fi

echo ""
sleep 3

# Create and setup tradechannel2
printColor "$BLUE" "Setting up tradechannel2"
"$SCRIPT_DIR/createChannel.sh" tradechannel2

if [ $? -ne 0 ]; then
    printColor "$RED" "Failed to setup tradechannel2"
    exit 1
fi

echo ""
printColor "$GREEN" "All channels created and configured"
