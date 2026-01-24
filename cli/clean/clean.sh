#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/scripts/utils/print-colored.sh"

printColor "$YELLOW" "Cleaning Trading Network..."
echo ""

# Clean artifacts
chmod +x "$SCRIPT_DIR/cleanArtifacts.sh"
"$SCRIPT_DIR/cleanArtifacts.sh"

echo ""

# Clean volumes
chmod +x "$SCRIPT_DIR/cleanVolumes.sh"
"$SCRIPT_DIR/cleanVolumes.sh"

echo ""
printColor "$GREEN" "All generated artifacts and volumes cleaned"
