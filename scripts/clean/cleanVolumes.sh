#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/scripts/utils/print-colored.sh"

printColor "$BLUE" "Cleaning Docker volumes..."

cd "$NETWORK_DIR"
docker compose down -v 2>/dev/null || true

printColor "$GREEN" "Docker volumes removed"
