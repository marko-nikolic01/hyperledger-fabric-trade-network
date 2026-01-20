#!/bin/bash

# Color codes and print function

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NO_COLOR='\033[0m'

printColor() {
    color=$1
    shift
    echo -e "${color}$@${NO_COLOR}"
}
