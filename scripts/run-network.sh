#!/bin/bash
set -e

bash "$(dirname "$0")/../cli/tn" up
bash "$(dirname "$0")/../cli/tn" createchannels
bash "$(dirname "$0")/../cli/tn" deploycc
