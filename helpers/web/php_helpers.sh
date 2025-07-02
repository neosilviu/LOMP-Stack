#!/bin/bash
#
# php_helpers.sh - Part of LOMP Stack v3.0
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
# php_helpers.sh - Helper pentru instalare și management PHP
# Exemplu de utilizare cu versiune:
#   start_php 8.1   # pornește php8.1-fpm
#   stop_php 8.0    # oprește php8.0-fpm
#   restart_php     # fallback, încearcă toate versiunile cunoscute
#   status_php 8.1  # status pentru php8.1-fpm

. "$(dirname "${BASH_SOURCE[0]}")/php_actions.sh"

start_php() { php_service_action php start "$1"; }
stop_php() { php_service_action php stop "$1"; }
restart_php() { php_service_action php restart "$1"; }
status_php() { php_service_action php status "$1"; }

php_version() {
  color_echo yellow "$(tr_lang php_version_info)"
  php -v
}

install_php_stack() {
  color_echo yellow "$(tr_lang php_install)"
  sudo apt-get update
  sudo apt-get install -y lsb-release ca-certificates apt-transport-https software-properties-common
  sudo add-apt-repository ppa:ondrej/php -y
  sudo apt-get update
  sudo apt-get install -y php php-fpm php-mysql php-xml php-curl php-gd php-mbstring php-zip
}

# Instalează doar binarul PHP (fără extensii)
install_php_core() {
  color_echo yellow "$(tr_lang php_install)"
  sudo apt-get update
  sudo apt-get install -y lsb-release ca-certificates apt-transport-https software-properties-common
  sudo add-apt-repository ppa:ondrej/php -y
  sudo apt-get update
  sudo apt-get install -y php php-fpm
  color_echo green "php și php-fpm au fost instalate."
}

# Instalează extensiile de bază pentru PHP (doar dacă binarul există)
install_php_extensions() {
  if ! command -v php >/dev/null 2>&1; then
    color_echo yellow "Binarul php nu este instalat, extensiile nu pot fi instalate."
    return 1
  fi
  sudo apt-get install -y php-mysql php-xml php-curl php-gd php-mbstring php-zip
  color_echo green "Extensiile de bază pentru PHP au fost instalate."
}

# Configurează versiunea PHP pentru un user (symlink www.conf sau pool dedicat)
# Usage: configure_user_php <user> <php_version>
configure_user_php() {
  local user="$1" phpver="$2"
  local pool_dir="/etc/php/$phpver/fpm/pool.d"
  local pool_file="$pool_dir/$user.conf"
  if [[ ! -d "$pool_dir" ]]; then
    color_echo red "[PHP] Versiunea $phpver nu este instalată!"
    return 1
  fi
  sudo cp /etc/php/$phpver/fpm/pool.d/www.conf "$pool_file"
  sudo sed -i "s/^user = .*/user = $user/" "$pool_file"
  sudo sed -i "s/^group = .*/group = $user/" "$pool_file"
  sudo sed -i "s/^listen = .*/listen = \/run\/php\/$user-php$phpver-fpm.sock/" "$pool_file"
  sudo systemctl restart php$phpver-fpm
  color_echo green "[PHP] Configurat user $user cu PHP $phpver (pool dedicat)"
}
