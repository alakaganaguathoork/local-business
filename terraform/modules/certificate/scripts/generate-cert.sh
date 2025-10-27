#!/usr/bin/env bash
set -euo pipefail

# Read (and ignore) the external data source query from stdin.
if [ ! -t 0 ]; then
  cat >/dev/null
fi

log() { 
    printf '%s\n' "$*" >&2; 
}

# Base64-encode (single line) for JSON safety
b64() { 
    base64 | tr -d '\n'; 
}

# Resolve paths relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/generated-certs"
mkdir -p "${OUT_DIR}"

# Files
CA_KEY="${OUT_DIR}/ca.key"
CA_CRT="${OUT_DIR}/ca.crt"
LEAF_KEY="${OUT_DIR}/leaf.key"
LEAF_CSR="${OUT_DIR}/leaf.csr"
LEAF_CRT="${OUT_DIR}/leaf.crt"

# Verify openssl exists
if ! command -v openssl >/dev/null 2>&1; then
  log "ERROR: openssl is not installed on this runner."
  log "Tip: On Terraform Cloud hosted runners, prefer the tls provider (Option A) or run via an Agent with openssl installed."
  # Return an empty JSON to avoid invalid output; Terraform will fail when decoding.
  echo '{"error":"openssl not found"}'
  exit 1
fi

# === Generate a simple CA ===
log "Generating CA..."
openssl genrsa \
    -out "${CA_KEY}" \
    4096  \
    >/dev/null 2>&1

openssl req \
    -new \
    -x509 \
    -days 3650 \
    -key "${CA_KEY}" \
    -out "${CA_CRT}" \
    -config "${SCRIPT_DIR}/ca-config.cnf" \
    >/dev/null 2>&1

# === Generate leaf (wildcard) signed by our CA ===
log "Generating leaf..."
openssl genrsa \
    -out "${LEAF_KEY}" \
    2048 \
    >/dev/null 2>&1

openssl req \
    -new \
    -key "${LEAF_KEY}" \
    -out "${LEAF_CSR}" \
    -config "${SCRIPT_DIR}/ca-config.cnf" \
    -reqexts v3_req \
    >/dev/null 2>&1


openssl x509 \
    -req \
    -in "${LEAF_CSR}" \
    -CA "${CA_CRT}" \
    -CAkey "${CA_KEY}" \
    -CAcreateserial \
    -out "${LEAF_CRT}" \
    -days 397 \
    -extensions v3_req \
    -extfile $SCRIPT_DIR/ca-config.cnf \
    >/dev/null 2>&1

PK_B64="$(b64 < "${LEAF_KEY}")"
CRT_B64="$(b64 < "${LEAF_CRT}")"
CHAIN_B64="$(b64 < "${CA_CRT}")"

# IMPORTANT: print ONLY JSON to stdout
printf '{ "private_key_b64": "%s", "certificate_b64": "%s", "chain_b64": "%s" }\n' \
  "${PK_B64}" "${CRT_B64}" "${CHAIN_B64}"
