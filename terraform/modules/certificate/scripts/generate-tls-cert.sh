#!/bin/bash

set -e

SCRIPT_DIR="scripts"
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
CERTS_DIR="generated-certs"

verify_openssl() {
    if ! type -P openssl >/dev/null; then
        echo "openssl is not installed!"
        exit 1
    else
        echo "openssl is installed, continue..."
    fi
}

create_cert_dir() {
    if [[ ! -d "$GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR" ]]; then
        printf "no directory %s \n" "$GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR"
        mkdir -p $GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR/{certs,cacerts,private}
    fi
}

cd "$GIT_ROOT_DIR/$SCRIPT_DIR/generated-certs/"


generate_ca_cert() {
    # CA private key
    echo "Generating CA key into $GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR/private/ca.key"

    openssl genrsa \
        -out "$GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR/private/ca.key" \
        4096

    echo "Generating CA cert into $GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR/private/ca.crt"
    openssl req \
        -new \
        -x509 \
        -days 3650 \
        -key "$GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR/private/ca.key" \
        -out "$GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR/private/ca.crt" \
        -config "$GIT_ROOT_DIR/$SCRIPT_DIR/ca-config.cnf"
    
    echo "Verification: "
    openssl x509 \
        -in "$GIT_ROOT_DIR/$SCRIPT_DIR/$CERTS_DIR/private/ca.crt" \
        -text \
        -noout
    
}

verify_openssl
create_cert_dir
generate_ca_cert