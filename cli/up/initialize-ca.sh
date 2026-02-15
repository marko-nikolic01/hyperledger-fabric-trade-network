#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

ensure_admin_enrolled() {
  local org="$1"
  local msp_dir="$NETWORK_DIR/fabric-ca-client/${org}/msp"
  local signcerts_dir="$msp_dir/signcerts"
  local enroll_script="$SCRIPT_DIR/enroll-org-admin.sh"

  if [ -d "$signcerts_dir" ] && [ "$(ls -A "$signcerts_dir" 2>/dev/null)" ]; then
    printColor "$GREEN" "CA admin already enrolled for ${org}"
    return 0
  fi

  printColor "$YELLOW" "Enrolling CA admin for ${org}..."
  chmod +x "$enroll_script"
  "$enroll_script" "${org}" || return 1
}

printColor "$GREEN" "Initializing Fabric CA identities..."

ensure_admin_enrolled "org1" || exit 1
ensure_admin_enrolled "org2" || exit 1
ensure_admin_enrolled "org3" || exit 1

printColor "$GREEN" "Fabric CA admin enrollment complete"
