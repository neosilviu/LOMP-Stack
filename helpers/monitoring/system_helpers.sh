#!/bin/bash
#
# system_helpers.sh - Part of LOMP Stack v3.0
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
# system_helpers.sh - Helper pentru optimizări sistem, monitoring, afișare URL-uri

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/dependency_manager.sh"
source "$SCRIPT_DIR/../utils/error_handler.sh"

# Initialize error handling
setup_error_handlers
export DEBUG_MODE=true

# Source helpers using dependency manager
source_stack_helper "functions"

# Instalează și pornește Netdata (funcție centralizată pentru monitoring)
install_monitoring_netdata() {
  log_info "Instalez Netdata..." "yellow"
  sudo apt update
  sudo apt install -y netdata
  sudo systemctl enable netdata
  sudo systemctl start netdata
  color_echo green "Netdata instalat și pornit cu succes!"
}

# Restart multiple services safely (accepts a list of service names)
restart_services() {
  for svc in "$@"; do
    if systemctl list-units --type=service | grep -q "^$svc"; then
      sudo systemctl restart "$svc" || sudo service "$svc" restart || true
    else
      sudo service "$svc" restart || true
    fi
  done
}

# Afișează URL-uri utile după instalare
show_stack_urls() {
  local ip
  ip=$(hostname -I | awk '{print $1}')
  echo -e "\n--- INSTALARE FINALIZATĂ ---"
  echo "WordPress: http://$ip/"
  echo "OpenLiteSpeed Panel: http://$ip:7080 (admin:admin implicit)"
  echo "Netdata: http://$ip:19999"
  echo -e "\nRecomandare: Schimbă parola admin OLS și finalizează instalarea WordPress din browser."
}

# Pași post-instalare stack: securitate, redis, monitoring, restart, afișare URL-uri
# Exemplu apel: post_install_stack_services "80 443 7080" "mariadb redis-server netdata" "ols"
post_install_stack_services() {
  local ports="$1"
  local services="$2"
  local webtype="$3"

  # Securitate cu porturi parametrizate

  . "$SCRIPT_DIR/helpers/security/install_security.sh" $ports

  # Redis
  . "$SCRIPT_DIR/helpers/security/install_redis.sh"

  # Monitoring
  install_monitoring_netdata

  # Restart servicii
  restart_services $services

  # Restart OLS dacă e cazul
  if [[ "$webtype" == "ols" ]]; then
    sudo /usr/local/lsws/bin/lswsctrl restart
  fi

  # Afișare URL-uri
  show_stack_urls
}
