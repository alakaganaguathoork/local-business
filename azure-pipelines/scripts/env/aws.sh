#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# This script automates AWS CLI installation/uninstallation based on provided argume nt `--action``.
# Usage: aws.sh --action <install|uninstall>

# ────────────────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────────────────

color() {
  # prints in bold magenta
  printf "\e[1;35m%b\e[0m" "$1"
}

italic() {
  printf "\e[3m%b\e[0m" "$1"
}

die() {
  echo >&2 "❌ ${1}"
  exit "${2:-1}"
}

# ────────────────────────────────────────────────────────────────────────────────
# Defaults
# ────────────────────────────────────────────────────────────────────────────────

ACTION=""

# ────────────────────────────────────────────────────────────────────────────────
# Parse args
# ────────────────────────────────────────────────────────────────────────────────

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --action|-a)
        ACTION="${2:-}"; shift 2 
        ;;
      -h|--help)
        echo "$(color "Usage:") $(italic "$0 --action <install|uninstall>")"
        exit 0 
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done

  # validate required args
  if [[ -z "$ACTION" ]]; then
    die "$(color "Missing required argument: --action")"
  fi
}

# ────────────────────────────────────────────────────────────────────────────────
# Functions
# ────────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────────
# Main logic
# ────────────────────────────────────────────────────────────────────────────────

parse_args "$@"

echo "$(color "Performing") $($ACTION)..."

case "$ACTION" in
  install)
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
    rm -r awscli-bundle

    echo "AWS CLI installed"
    ;;
  uninstall)
    sudo rm -rf /usr/local/aws
    sudo rm -rf /usr/local/bin/aws*
    
    echo "AWS CLI uninstalled"
    ;;
  *)
    die "Unknown action: $ACTION"
    ;;
esac
