#!/bin/bash
#
# install_security.sh - Part of LOMP Stack v3.0
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
# install_security.sh - Instalează securitate avansată (opțional, porturi parametrizate)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../utils/functions.sh"
. "$SCRIPT_DIR/../utils/lang.sh"
color_echo cyan "$(tr_lang security_install)"

# Preia porturi din argumente sau folosește default
if [[ $# -eq 0 ]]; then
  PORTS=(80 443)
else
  PORTS=("$@")
fi

# Exemplu: fail2ban + configurare UFW strictă
sudo apt update
sudo apt install -y fail2ban ufw
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# UFW - doar porturi esențiale
for port in "${PORTS[@]}"; do
  sudo ufw allow $port
done
sudo ufw default deny incoming
sudo ufw --force enable

color_echo green "$(tr_lang security_done)"
