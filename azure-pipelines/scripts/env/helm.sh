#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# This script automates AWS CLI installation/uninstallation based on provided argume nt `--action``.
# Usage: helm.sh --action <install|uninstall>

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
    curl -fsSL "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" -o get_helm.sh 
    chmod 700 get_helm.sh
    ./get_helm.sh

    echo "Helm installed"
    ;;
  uninstall)
    sudo rm -rf "$(which helm)"
    rm -rf ~/.helm
    rm -rf ~/.cache/helm
    rm -rf ~/.config/helm
    rm -rf ~/.local/share/helm

    
    echo "Helm uninstalled"
    ;;
  *)
    die "Unknown action: $ACTION"
    ;;
esac
