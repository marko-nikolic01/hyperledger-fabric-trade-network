#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="$PROJECT_ROOT/network"

source "$PROJECT_ROOT/cli/utils/print-colored.sh"

ORG="${1:-}"
if [[ -z "$ORG" ]]; then
  printColor "$RED" "Usage: $0 <org1|org2|org3>"
  exit 1
fi

case "$ORG" in
  org1)
    CA_HOST="ca.org1.trade.com"
    CA_PORT=7054
    CA_NAME="ca-org1"
    ;;
  org2)
    CA_HOST="ca.org2.trade.com"
    CA_PORT=8054
    CA_NAME="ca-org2"
    ;;
  org3)
    CA_HOST="ca.org3.trade.com"
    CA_PORT=9054
    CA_NAME="ca-org3"
    ;;
  *)
    printColor "$RED" "Unknown org: $ORG"
    exit 1
    ;;
 esac

HOST_CA_CERT="$NETWORK_DIR/fabric-ca/${ORG}/ca-cert.pem"
if [[ ! -f "$HOST_CA_CERT" ]]; then
  printColor "$YELLOW" "CA cert not found at $HOST_CA_CERT, attempting to copy from CA container..."
  docker cp "${CA_HOST}:/etc/hyperledger/fabric-ca-server/ca-cert.pem" "$HOST_CA_CERT"
fi

printColor "$YELLOW" "Enrolling CA admin for ${ORG}..."

HOST_CLIENT_DIR="$NETWORK_DIR/fabric-ca-client/${ORG}"
mkdir -p "$HOST_CLIENT_DIR"

docker run --rm \
  --network trade \
  -v "$NETWORK_DIR:/work/network" \
  -e FABRIC_CA_CLIENT_HOME="/work/network/fabric-ca-client/${ORG}" \
  hyperledger/fabric-ca:1.5.7 \
  fabric-ca-client enroll \
  -u "https://admin:adminpw@${CA_HOST}:${CA_PORT}" \
  --tls.certfiles "/work/network/fabric-ca/${ORG}/ca-cert.pem" \
  --caname "$CA_NAME"

ORG_MSP_DIR="$NETWORK_DIR/crypto-config/peerOrganizations/${ORG}.trade.com/msp"
mkdir -p "$ORG_MSP_DIR/cacerts"
if ! cp -f "$HOST_CA_CERT" "$ORG_MSP_DIR/cacerts/ca-${ORG}.pem" 2>/dev/null; then
  printColor "$YELLOW" "Permission denied copying CA cert. Retrying with sudo..."
  sudo cp -f "$HOST_CA_CERT" "$ORG_MSP_DIR/cacerts/ca-${ORG}.pem"
  sudo chown "$USER":"$USER" "$ORG_MSP_DIR/cacerts/ca-${ORG}.pem" || true
fi

printColor "$GREEN" "Enrolled CA admin for ${ORG} and merged CA cert into MSPs."
