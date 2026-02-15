#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NETWORK_DIR="${PROJECT_ROOT}/network"
CHANNEL_NAME="${1:-}"

if [[ -z "${CHANNEL_NAME}" ]]; then
  echo "Usage: $0 <channel-name>" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
CONTAINER_WORK_DIR="/tmp/ca-msp-update"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

echo "Updating channel MSPs with Fabric CA root certs for channel ${CHANNEL_NAME}..."

docker exec cli mkdir -p "${CONTAINER_WORK_DIR}"

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
  cli peer channel fetch config "${CONTAINER_WORK_DIR}/config_block.pb" \
  -o orderer0.trade.com:7050 \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/trade.com/orderers/orderer0.trade.com/msp/tlscacerts/tlsca.trade.com-cert.pem \
  -c "${CHANNEL_NAME}"

docker exec cli configtxlator proto_decode \
  --input "${CONTAINER_WORK_DIR}/config_block.pb" \
  --type common.Block > "${WORK_DIR}/config_block.json"

python3 - <<PY
import json
from pathlib import Path

work_dir = Path("${WORK_DIR}")
block = json.loads((work_dir / "config_block.json").read_text())
config = block["data"]["data"][0]["payload"]["data"]["config"]
(work_dir / "config.json").write_text(json.dumps(config, indent=2))
PY

python3 - <<PY
import base64
import json
from pathlib import Path

work_dir = Path("${WORK_DIR}")
network_dir = Path("${NETWORK_DIR}")
config = json.loads((work_dir / "config.json").read_text())

orgs = ["org1", "org2", "org3"]
org_msp = {"org1": "Org1MSP", "org2": "Org2MSP", "org3": "Org3MSP"}

for org in orgs:
  ca_cert_path = network_dir / "fabric-ca" / org / "ca-cert.pem"
  if not ca_cert_path.exists():
    raise SystemExit(f"CA cert not found: {ca_cert_path}")

  admin_cert_dir = network_dir / "crypto-config" / "peerOrganizations" / f"{org}.trade.com" / "users" / f"Admin@{org}.trade.com" / "msp" / "signcerts"
  if not admin_cert_dir.exists():
    raise SystemExit(f"Admin cert directory not found: {admin_cert_dir}")
  admin_cert_files = list(admin_cert_dir.glob("*.pem"))
  if not admin_cert_files:
    raise SystemExit(f"Admin cert not found in: {admin_cert_dir}")
  admin_cert_pem = admin_cert_files[0].read_bytes()
  admin_cert_b64 = base64.b64encode(admin_cert_pem).decode("utf-8")

  cert_pem = ca_cert_path.read_bytes()
  cert_b64 = base64.b64encode(cert_pem).decode("utf-8")

  msp = config["channel_group"]["groups"]["Application"]["groups"][org_msp[org]]["values"]["MSP"]["value"]
  root_certs = msp["config"].get("root_certs", [])
  if cert_b64 not in root_certs:
    root_certs.append(cert_b64)
  msp["config"]["root_certs"] = root_certs

  if "fabric_node_ous" in msp["config"]:
    msp["config"]["fabric_node_ous"]["enable"] = False

  admins = msp["config"].get("admins", [])
  if admin_cert_b64 not in admins:
    admins.append(admin_cert_b64)
  msp["config"]["admins"] = admins

  policies = config["channel_group"]["groups"]["Application"]["groups"][org_msp[org]].get("policies", {})
  member_identity = {
    "principal_classification": "ROLE",
    "principal": {
      "msp_identifier": org_msp[org],
      "role": "MEMBER"
    }
  }
  member_rule = {"n_out_of": {"n": 1, "rules": [{"signed_by": 0}]}}
  for key in ("Readers", "Writers", "Endorsement"):
    if key in policies:
      policies[key]["policy"]["value"]["identities"] = [member_identity]
      policies[key]["policy"]["value"]["rule"] = member_rule

(work_dir / "updated_config.json").write_text(json.dumps(config, indent=2))
PY

docker exec cli mkdir -p "${CONTAINER_WORK_DIR}"
docker cp "${WORK_DIR}/config.json" "cli:${CONTAINER_WORK_DIR}/config.json"
docker cp "${WORK_DIR}/updated_config.json" "cli:${CONTAINER_WORK_DIR}/updated_config.json"

docker exec cli configtxlator proto_encode \
  --input "${CONTAINER_WORK_DIR}/config.json" \
  --type common.Config \
  --output "${CONTAINER_WORK_DIR}/config.pb"

docker exec cli configtxlator proto_encode \
  --input "${CONTAINER_WORK_DIR}/updated_config.json" \
  --type common.Config \
  --output "${CONTAINER_WORK_DIR}/updated_config.pb"

set +e
UPDATE_OUTPUT=$(docker exec cli configtxlator compute_update \
  --channel_id "${CHANNEL_NAME}" \
  --original "${CONTAINER_WORK_DIR}/config.pb" \
  --updated "${CONTAINER_WORK_DIR}/updated_config.pb" \
  --output "${CONTAINER_WORK_DIR}/config_update.pb" 2>&1)
UPDATE_STATUS=$?
set -e

if [ ${UPDATE_STATUS} -ne 0 ]; then
  if echo "${UPDATE_OUTPUT}" | grep -qi "no differences"; then
    echo "No MSP updates needed for ${CHANNEL_NAME}."
    exit 0
  fi
  echo "${UPDATE_OUTPUT}" >&2
  exit ${UPDATE_STATUS}
fi

docker exec cli configtxlator proto_decode \
  --input "${CONTAINER_WORK_DIR}/config_update.pb" \
  --type common.ConfigUpdate > "${WORK_DIR}/config_update.json"

python3 - <<PY
import json
from pathlib import Path

work_dir = Path("${WORK_DIR}")
config_update = json.loads((work_dir / "config_update.json").read_text())

envelope = {
    "payload": {
        "header": {
            "channel_header": {
                "channel_id": "${CHANNEL_NAME}",
                "type": 2
            }
        },
        "data": {
            "config_update": config_update
        }
    }
}

(work_dir / "config_update_envelope.json").write_text(json.dumps(envelope, indent=2))
PY

docker cp "${WORK_DIR}/config_update_envelope.json" "cli:${CONTAINER_WORK_DIR}/config_update_envelope.json"
docker exec cli configtxlator proto_encode \
  --input "${CONTAINER_WORK_DIR}/config_update_envelope.json" \
  --type common.Envelope \
  --output "${CONTAINER_WORK_DIR}/config_update_envelope.pb"

# Sign config update with each org admin
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
  cli peer channel signconfigtx \
  -f "${CONTAINER_WORK_DIR}/config_update_envelope.pb"

docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.trade.com:9051 \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.trade.com/peers/peer0.org2.trade.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.trade.com/users/Admin@org2.trade.com/msp \
  cli peer channel signconfigtx \
  -f "${CONTAINER_WORK_DIR}/config_update_envelope.pb"

docker exec \
  -e CORE_PEER_LOCALMSPID=Org3MSP \
  -e CORE_PEER_ADDRESS=peer0.org3.trade.com:13051 \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.trade.com/peers/peer0.org3.trade.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.trade.com/users/Admin@org3.trade.com/msp \
  cli peer channel signconfigtx \
  -f "${CONTAINER_WORK_DIR}/config_update_envelope.pb"

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.trade.com:7051 \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/peers/peer0.org1.trade.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.trade.com/users/Admin@org1.trade.com/msp \
  cli peer channel update \
  -f "${CONTAINER_WORK_DIR}/config_update_envelope.pb" \
  -c "${CHANNEL_NAME}" \
  -o orderer0.trade.com:7050 \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/trade.com/orderers/orderer0.trade.com/msp/tlscacerts/tlsca.trade.com-cert.pem

echo "Channel MSP updated with Fabric CA root certs for ${CHANNEL_NAME}."
