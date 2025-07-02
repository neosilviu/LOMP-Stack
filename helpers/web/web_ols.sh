#!/bin/bash
#
# web_ols.sh - Part of LOMP Stack v3.0
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
# web_ols.sh - Orchestrare instalare/configurare OLS + lsphp pentru WordPress
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/functions.sh"
. "$SCRIPT_DIR/ols_helpers.sh"
. "$SCRIPT_DIR/olsphp_helpers.sh"

install_ols_stack() {
  install_ols_latest
  install_olsphp_core
  # Setează parola admin OLS o singură dată, dacă nu există deja
  if [ -d /usr/local/lsws ]; then
    if [ ! -f /etc/ols_admin_info ]; then
      if type set_ols_admin_password &>/dev/null; then
        set_ols_admin_password
      fi
    fi
  fi
}