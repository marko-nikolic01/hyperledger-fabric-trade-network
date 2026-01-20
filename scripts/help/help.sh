#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/scripts/utils/print-colored.sh"

printColor "$GREEN" "Trading Network CLI"
echo ""
printColor "$BLUE" "Usage: ./scripts/tn <command>"
echo ""
printColor "$YELLOW" "Available commands:"
echo "  up     - Start the network"
echo "  down   - Stop the network"
echo "  clean  - Remove generated artifacts"
echo "  help   - Show this help message"
