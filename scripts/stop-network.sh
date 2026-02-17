#!/bin/bash
set -e

bash "$(dirname "$0")/../cli/tn" down
bash "$(dirname "$0")/../cli/tn" clean
