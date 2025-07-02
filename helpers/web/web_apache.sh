#!/bin/bash
#
# web_apache.sh - Part of LOMP Stack v3.0
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
# web_apache.sh - Orchestrare instalare/configurare Apache + PHP pentru WordPress

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/dependency_manager.sh"
source "$SCRIPT_DIR/../utils/error_handler.sh"

# Initialize error handling
setup_error_handlers

# Source helpers using dependency manager
source_stack_helper "functions"
source "$SCRIPT_DIR/apache_helpers.sh"

# Instalează Apache și PHP cu extensii de bază
install_apache_stack() {
  log_info "Instalare Apache..." "yellow"
  sudo apt install -y apache2
  log_info "Instalare PHP + extensii..." "yellow"
  sudo apt install -y php libapache2-mod-php php-mysql php-xml php-curl php-gd php-mbstring php-zip
  sudo systemctl restart apache2
}

# Configurează vhost și optimizează php.ini pentru un user/domain
# Usage: configure_apache_wordpress_stack <user> <domain>
configure_apache_wordpress_stack() {
  local user="$1"
  local domain="$2"
  configure_apache_vhost_wordpress "$user" "$domain"
  optimize_apache_php_ini_wordpress
}