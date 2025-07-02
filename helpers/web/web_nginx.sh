#!/bin/bash
#
# web_nginx.sh - Part of LOMP Stack v3.0
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
# web_nginx.sh - Orchestrare instalare/configurare Nginx + PHP pentru WordPress
. "$(dirname "$0")/../utils/functions.sh"
. "$(dirname "$0")/nginx_helpers.sh"
. "$(dirname "$0")/php_helpers.sh"

# Instalează Nginx și PHP cu extensii de bază
install_nginx_stack() {
  install_nginx_latest
  install_php_wordpress
  configure_nginx_wordpress
  optimize_php_ini_wordpress
}

# Configurează vhost și optimizează php.ini pentru un user/domain
# Usage: configure_nginx_wordpress_stack <user> <domain>
configure_nginx_wordpress_stack() {
  local user="$1"
  local domain="$2"
  configure_nginx_wordpress "$user" "$domain"
  optimize_php_ini_wordpress "$user" "$domain"
}