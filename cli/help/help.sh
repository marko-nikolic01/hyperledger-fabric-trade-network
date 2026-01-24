#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

printColor "$GREEN" "Trading Network CLI"
echo ""
printColor "$BLUE" "Usage: ./tn <command>"
echo ""
printColor "$YELLOW" "Available commands:"
echo "  check          - Check network status"
echo "  clean          - Remove generated artifacts"
echo "  createchannels - Create and configure channels"
echo "  deploycc       - Deploy and initialize chaincode on all channels"
echo "  down           - Stop the network"
echo "  help           - Show this help message"
echo "  interactive    - Run interactive menu"
echo "  up             - Start the network"
