#!/bin/bash
#
# cloudflare_helpers.sh - Part of LOMP Stack v3.0
# Part of LOMP Stack v3.0
#
# Author: Silviu Ilie <neosilviu@gmail.com>
# Company: aemdPC
# Version: 3.0.0
# Copyright © 2025 aemdPC. All rights reserved.
# License: MIT License
#
# Repository: https://github.com/aemdPC/lomp-stack-v3
# Documentation: https://docs.aemdpc.com/lomp-stack
# Support: https://support.aemdpc.com
#
# cloudflare_helpers.sh - Funcții pentru confirmare tunel Cloudflare

# Sourcing color_echo din helpers/utils/functions.sh pentru mesaje colorate
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../utils/functions.sh"

confirm_cloudflare_tunnel() {
  local domain="$1"
  while true; do
    echo -ne "\033[1;36mDorești să configurezi tunel Cloudflare pentru $domain? ([Y]/n)\033[0m"
    read -r cf_tunnel_confirm
    if [[ -z "$cf_tunnel_confirm" || "$cf_tunnel_confirm" =~ ^[yY]$ ]]; then
      export STACK_CF_TUNNEL=1
      echo "STACK_CF_TUNNEL=1" >> /tmp/stack_user_env
      color_echo yellow "Tunel Cloudflare va fi configurat."
      break
    elif [[ "$cf_tunnel_confirm" =~ ^[nN]$ ]]; then
      export STACK_CF_TUNNEL=0
      echo "STACK_CF_TUNNEL=0" >> /tmp/stack_user_env
      color_echo yellow "Tunel Cloudflare NU va fi configurat."
      break
    else
      color_echo yellow "Te rog răspunde cu 'y' pentru DA sau 'n' pentru NU (Enter = DA implicit)."
    fi
  done
}

# Confirmare interactivă fallback (pentru compatibilitate vechi)
confirm_cloudflare_tunnel_interactive() {
  local domain="$1"
  local install_cf_tunnel
  read -rp "Dorești să instalezi tunel Cloudflare pentru $domain? [y/N]: " cf_confirm
  if [[ "$cf_confirm" =~ ^[Yy]$ ]]; then
    install_cf_tunnel=1
  else
    install_cf_tunnel=0
  fi
  export STACK_CF_TUNNEL="$install_cf_tunnel"
  echo "STACK_CF_TUNNEL=$install_cf_tunnel" >> /tmp/stack_user_env
  return $install_cf_tunnel
}
