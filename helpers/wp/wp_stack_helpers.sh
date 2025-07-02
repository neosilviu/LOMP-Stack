#!/bin/bash
#
# wp_stack_helpers.sh - Part of LOMP Stack v3.0
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
# wp_stack_helpers.sh - Helper pentru instalare/configurare WordPress, LSCache, .htaccess

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$SCRIPT_DIR/../utils/functions.sh"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/lang.sh"

. "$SCRIPT_DIR/../utils/lang.sh"

# Instalează WordPress ultima stabilă în /var/www/html
install_wordpress_latest_stack() {
  local msg
  msg="$(tr_lang wp_install)"
  color_echo yellow "$msg"
  log_info "$msg"
  local WP_DOMAIN="${STACK_DOMAIN:-localhost}"
  local WP_USERNAME="${STACK_USERNAME:-wordpress}"
  local WP_WEBROOT="/home/$WP_USERNAME/$WP_DOMAIN"

  # --- Cleanup temporar robust pentru instalare WordPress ---
  local TMP_WP_ZIP="/tmp/wordpress.zip"
  local TMP_WP_DIR="/tmp/wordpress"
  cleanup_tmp_wp() {
    rm -rf "$TMP_WP_ZIP" "$TMP_WP_DIR"
  }
  trap cleanup_tmp_wp EXIT

  # Curăță înainte de descărcare dacă există deja
  rm -rf "$TMP_WP_ZIP" "$TMP_WP_DIR"

  if ! sudo mkdir -p "$WP_WEBROOT"; then log_error "mkdir $WP_WEBROOT failed"; return 1; fi
  if ! sudo chown $WP_USERNAME:$WP_USERNAME "$WP_WEBROOT"; then log_error "chown $WP_WEBROOT failed"; return 1; fi
  if ! wget https://wordpress.org/latest.zip -O "$TMP_WP_ZIP"; then log_error "wget WordPress failed"; return 1; fi
  if ! unzip -o "$TMP_WP_ZIP" -d /tmp/; then log_error "unzip WordPress failed"; return 1; fi
  if ! cp -r "$TMP_WP_DIR"/* "$WP_WEBROOT/"; then log_error "copy WordPress files failed"; return 1; fi
  if ! sudo chown -R $WP_USERNAME:www-data "$WP_WEBROOT"; then log_error "chown www-data failed"; return 1; fi
  if ! sudo chmod -R 755 "$WP_WEBROOT"; then log_error "chmod 755 failed"; return 1; fi
}

# Activează și configurează LSCache pentru WordPress
configure_lscache_wordpress() {
  local msg
  msg="[WP] $(tr_lang lscache_enable)"
  color_echo yellow "$msg"
  log_info "$msg"
  local WP_DOMAIN="${STACK_DOMAIN:-localhost}"
  local WP_USERNAME="${STACK_USERNAME:-wordpress}"
  local WP_WEBROOT="/home/$WP_USERNAME/$WP_DOMAIN"
  if ! grep -q 'lscache' "$WP_WEBROOT/wp-config.php" 2>/dev/null; then
    if ! echo -e "/** Enable LiteSpeed Cache */\ndefine('WP_CACHE', true);\ndefine('LSCACHE_ENABLED', true);" | sudo tee -a "$WP_WEBROOT/wp-config.php"; then
      log_error "Failed to enable LSCache in wp-config.php"; return 1
    fi
  fi
}

# Setează permisiuni .htaccess pentru WordPress
set_htaccess_permissions_wordpress() {
  local msg
  msg="[WP] $(tr_lang htaccess_permissions)"
  color_echo yellow "$msg"
  log_info "$msg"
  local WP_DOMAIN="${STACK_DOMAIN:-localhost}"
  local WP_USERNAME="${STACK_USERNAME:-wordpress}"
  local WP_WEBROOT="/home/$WP_USERNAME/$WP_DOMAIN"
  if ! sudo touch "$WP_WEBROOT/.htaccess"; then log_error "touch .htaccess failed"; return 1; fi
  if ! sudo chown www-data:www-data "$WP_WEBROOT/.htaccess"; then log_error "chown .htaccess failed"; return 1; fi
  if ! sudo chmod 664 "$WP_WEBROOT/.htaccess"; then log_error "chmod .htaccess failed"; return 1; fi
}

# Instalare completă WordPress stack pentru OLS
install_wordpress_stack_ols() {
  install_wordpress_latest_stack
  if declare -f configure_ols_vhost_wordpress >/dev/null; then configure_ols_vhost_wordpress; fi
  if declare -f optimize_lsphp_ini_wordpress >/dev/null; then optimize_lsphp_ini_wordpress; fi
  set_htaccess_permissions_wordpress
  configure_lscache_wordpress
  if declare -f secure_mariadb_wordpress >/dev/null; then secure_mariadb_wordpress; fi
}

# Instalare completă WordPress stack pentru Nginx
install_wordpress_stack_nginx() {
  install_wordpress_latest_stack
  if declare -f configure_nginx_wordpress >/dev/null; then configure_nginx_wordpress; fi
  if declare -f optimize_php_ini_wordpress >/dev/null; then optimize_php_ini_wordpress; fi
  set_htaccess_permissions_wordpress
  configure_lscache_wordpress
  if declare -f secure_mariadb_wordpress >/dev/null; then secure_mariadb_wordpress; fi
}
