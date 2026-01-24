#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONSOLE_APP_DIR="$PROJECT_ROOT/console-application"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

printColor "$BLUE" "Starting Interactive Console Application..."
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    printColor "$RED" "Error: Node.js is not installed"
    printColor "$YELLOW" "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check if console application exists
if [ ! -d "$CONSOLE_APP_DIR" ]; then
    printColor "$RED" "Error: Console application directory not found"
    exit 1
fi

cd "$CONSOLE_APP_DIR"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    printColor "$YELLOW" "Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        printColor "$RED" "Failed to install dependencies"
        exit 1
    fi
fi

# Always rebuild to ensure latest changes
printColor "$YELLOW" "Building application..."
npm run build
if [ $? -ne 0 ]; then
    printColor "$RED" "Failed to build application"
    exit 1
fi

# Run the application
npm start
