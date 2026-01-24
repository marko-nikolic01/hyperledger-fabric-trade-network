#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/scripts/utils/print-colored.sh"

printColor "$BLUE" "Checking Trading Network status..."
echo ""

# Check containers
chmod +x "$SCRIPT_DIR/checkContainers.sh"
"$SCRIPT_DIR/checkContainers.sh"
CONTAINERS_OK=$?

# Check channels
echo ""
chmod +x "$SCRIPT_DIR/checkChannels.sh"
"$SCRIPT_DIR/checkChannels.sh"
CHANNELS_OK=$?

# Summary
echo ""
if [ $CONTAINERS_OK -eq 0 ] && [ $CHANNELS_OK -eq 0 ]; then
    printColor "$GREEN" "All checks passed"
    printColor "$GREEN" "  - 21 containers running"
    printColor "$GREEN" "  - 2 channels configured"
    printColor "$GREEN" "  - 9 peers on each channel"
    exit 0
else
    printColor "$RED" "Some checks failed"
    [ $CONTAINERS_OK -ne 0 ] && printColor "$RED" "  - Container check failed"
    [ $CHANNELS_OK -ne 0 ] && printColor "$RED" "  - Channel check failed"
    exit 1
fi

