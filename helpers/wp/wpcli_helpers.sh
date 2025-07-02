#!/bin/bash
#
# wpcli_helpers.sh - Part of LOMP Stack v3.0
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
# wpcli_helpers.sh - Helper pentru instalare și management WP-CLI

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/dependency_manager.sh"
source "$SCRIPT_DIR/../utils/error_handler.sh"

# Initialize error handling
setup_error_handlers
export DEBUG_MODE=true

# Source helpers using dependency manager
source_stack_helper "functions"
source_stack_helper "lang"

install_wpcli() {
  log_info "$(tr_lang wpcli_install)" "yellow"
  # Instalează direct ultima versiune stabilă WP-CLI (fără detecție dinamică)
  local latest_url
  latest_url="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
  log_info "Se descarcă WP-CLI de la: $latest_url" "cyan"
  curl -L -o wp-cli.phar "$latest_url"
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
  # Instalează extensia php-mysql pentru WP-CLI (php cli)
  if ! php -m | grep -q mysqli; then
    log_info "Instalez extensia php-mysql pentru WP-CLI..." "yellow"
    if command -v apt >/dev/null 2>&1; then
      sudo apt update && sudo apt install -y php-mysql
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y php-mysqlnd
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y php-mysqlnd
    else
      log_error "Nu pot instala php-mysql automat. Instalează manual extensia pentru PHP CLI!"
    fi
  fi
}

# Dacă scriptul este rulat direct, execută instalarea și afișează statusul
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -e
  install_wpcli
  if command -v wp >/dev/null 2>&1; then
    log_info "WP-CLI instalat cu succes: $(wp --version 2>/dev/null | head -n1)" "green"
  else
    log_error "WP-CLI nu a fost instalat corect! Verifică permisiunile și rețeaua."
  fi
fi
