#!/bin/bash
#
# security_helpers.sh - Part of LOMP Stack v3.0
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
# security_helpers.sh - Funcții utilitare pentru management securitate (firewall, fail2ban, etc)

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/dependency_manager.sh"
source "$SCRIPT_DIR/../utils/error_handler.sh"

# Initialize error handling
setup_error_handlers
export DEBUG_MODE=true

# Source helpers using dependency manager
source_stack_helper "functions"

# Activează firewall-ul UFW cu porturi date
enable_firewall() {
  local ports=("$@")
  sudo apt install -y ufw
  for port in "${ports[@]}"; do
    sudo ufw allow $port
  done
  sudo ufw default deny incoming
  sudo ufw --force enable
}

# Dezactivează firewall-ul UFW
disable_firewall() {
  sudo ufw --force disable
}

# Status fail2ban
fail2ban_status() {
  sudo systemctl status fail2ban
}

# Verifică dacă un port este deschis
is_port_open() {
  local port="$1"
  (echo > /dev/tcp/localhost/$port) >/dev/null 2>&1 && echo "open" || echo "closed"
}

# Testează rapid securitatea de bază
quick_security_check() {
  sudo ufw status
  sudo systemctl status fail2ban
}