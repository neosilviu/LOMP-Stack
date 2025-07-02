#!/bin/bash
#
# wp_helpers.sh - Part of LOMP Stack v3.0
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
# wp_helpers.sh - Funcții utilitare pentru management WordPress

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/dependency_manager.sh"
source "$SCRIPT_DIR/../utils/error_handler.sh"

# Initialize error handling
setup_error_handlers

# Source helpers using dependency manager
source_stack_helper "functions"

# Source wp_config_helper pentru generarea wp-config.php
if [ -f "$SCRIPT_DIR/wp_config_helper.sh" ]; then
  . "$SCRIPT_DIR/wp_config_helper.sh"
else
  log_warning "wp_config_helper.sh nu a fost găsit, wp-config.php nu va fi generat automat"
fi

# Helper pentru a rula WP-CLI ca userul WordPress cu WP_CLI_PHP corect
wp_cli_as_user() {
  local username="$1"
  shift
  sudo -u "$username" -i -- bash -c "WP_CLI_PHP=/usr/bin/php wp $*"
}

# Funcție comună pentru actualizarea opțiunilor WordPress
wp_update_options() {
  local webroot="$1"
  local domain="$2"
  local username="$3"
  
  if [ -f "$webroot/wp-config.php" ]; then
    if [ "$(id -u)" -eq 0 ] && [ -n "$username" ]; then
      wp_cli_as_user "$username" --path="$webroot" option update siteurl "http://$domain"
      wp_cli_as_user "$username" --path="$webroot" option update home "http://$domain"
      wp_cli_as_user "$username" --path="$webroot" option update blogname "$domain"
      wp_cli_as_user "$username" --path="$webroot" option update admin_email "admin@$domain"
      if command -v wp >/dev/null 2>&1; then
        wp_cli_as_user "$username" --path="$webroot" plugin install litespeed-cache --activate
      fi
    else
      WP_CLI_PHP=/usr/bin/php wp --path="$webroot" option update siteurl "http://$domain"
      WP_CLI_PHP=/usr/bin/php wp --path="$webroot" option update home "http://$domain"
      WP_CLI_PHP=/usr/bin/php wp --path="$webroot" option update blogname "$domain"
      WP_CLI_PHP=/usr/bin/php wp --path="$webroot" option update admin_email "admin@$domain"
      if command -v wp >/dev/null 2>&1; then
        WP_CLI_PHP=/usr/bin/php wp --path="$webroot" plugin install litespeed-cache --activate
      fi
    fi
  fi
}

# Funcție comună pentru descărcarea și instalarea fișierelor WordPress
wp_download_and_install_files() {
  local webroot="$1"
  local username="$2"
  
  log_info "Descărcarea WordPress..." "cyan"
  cd /tmp || { log_error "Nu pot accesa /tmp"; return 1; }
  
  # Cleanup temporar robust
  local TMP_WP_ZIP="/tmp/wordpress.zip"
  local TMP_WP_DIR="/tmp/wordpress"
  cleanup_tmp_wp() {
    rm -rf "$TMP_WP_ZIP" "$TMP_WP_DIR"
  }
  trap cleanup_tmp_wp EXIT
  
  # Curăță înainte de descărcare dacă există deja
  rm -rf "$TMP_WP_ZIP" "$TMP_WP_DIR"
  
  # Descarcă și extrage WordPress
  if ! wget -q https://wordpress.org/latest.zip -O "$TMP_WP_ZIP"; then
    log_error "Descărcarea WordPress a eșuat"
    return 1
  fi
  
  if ! unzip -q "$TMP_WP_ZIP" -d /tmp/; then
    log_error "Extragerea WordPress a eșuat"
    return 1
  fi
  
  # Copiază fișierele în webroot
  if [ -n "$username" ]; then
    sudo -u "$username" cp -r "$TMP_WP_DIR"/* "$webroot/"
  else
    cp -r "$TMP_WP_DIR"/* "$webroot/"
  fi
  
  # Setează permisiunile
  if [ -n "$username" ]; then
    sudo chown -R "$username:www-data" "$webroot"
  fi
  sudo chmod -R 755 "$webroot"
  
  # Cleanup
  cleanup_tmp_wp
}

# Funcție comună pentru generarea raportului de instalare WordPress
wp_generate_install_report() {
  local domain="$1"
  local webroot="$2"
  local username="$3"
  local admin_user="${4:-admin}"
  local admin_pass="$5"
  local db_name="$6"
  local db_user="$7"
  local db_pass="$8"
  local db_host="${9:-localhost}"
  
  # Determinează directorul de raport
  local report_dir
  if [ "$(id -u)" -eq 0 ]; then
    report_dir="/root/config"
  else
    report_dir="$HOME/config"
  fi
  
  local report_file="$report_dir/wordpress_install_report.txt"
  mkdir -p "$report_dir"
  
  # Obține parola root MariaDB dacă există
  local mariadb_root_pass_file="/root/.stack_mariadb_root_pass"
  local mariadb_root_pass=""
  if sudo test -f "$mariadb_root_pass_file"; then
    mariadb_root_pass=$(sudo cat "$mariadb_root_pass_file")
  fi
  
  # Generează raportul
  {
    echo "==================== RAPORT INSTALARE WORDPRESS ===================="
    echo "Domeniu: $domain"
    echo "Webroot: $webroot"
    echo "User: $username"
    echo "Admin User: $admin_user"
    echo "Admin Password: $admin_pass"
    echo "Admin Email: admin@$domain"
    echo "Data instalare: $(date)"
    if [ -n "$db_name" ]; then
      echo "DB_NAME: $db_name"
      echo "DB_USER: $db_user"
      echo "DB_PASS: $db_pass"
      echo "DB_HOST: $db_host"
    fi
    if [[ -n "$mariadb_root_pass" ]]; then
      echo "MariaDB root password: $mariadb_root_pass (salvat și în $mariadb_root_pass_file)"
    fi
    echo "wp-config.php: $webroot/wp-config.php"
    echo "URL site: http://$domain"
    echo "--------------------------------------"
    echo "Poți accesa WordPress la: http://$domain"
    echo "Admin: http://$domain/wp-admin"
    if [ -n "$admin_user" ]; then
      echo "WP Admin user: $admin_user"
      echo "WP Admin pass: $admin_pass"
    fi
    if [ -n "$db_user" ]; then
      echo "User DB: $db_user / $db_pass"
    fi
    if [[ -n "$mariadb_root_pass" ]]; then
      echo "Root DB: root / $mariadb_root_pass"
    fi
    echo "--------------------------------------"
    echo "Acest raport a fost generat automat și salvat în $report_file."
    echo "=================================================================="
  } > "$report_file"
  
  log_info "Raport instalare WordPress salvat: $report_file" "green"
  
  # Salvează raportul și în home-ul utilizatorului WordPress, dacă există
  if [ -n "$username" ] && id "$username" &>/dev/null; then
    local user_home
    user_home=$(eval echo "~$username")
    if [[ -d "$user_home" ]]; then
      local user_report_dir="$user_home/config"
      local user_report_file="$user_report_dir/wordpress_install_report.txt"
      
      if sudo mkdir -p "$user_report_dir"; then
        if sudo cp "$report_file" "$user_report_file"; then
          sudo chown "$username:$username" "$user_report_file"
          log_info "Raportul a fost salvat și în $user_report_file" "green"
        else
          log_error "Nu am putut copia raportul în $user_report_dir!"
        fi
      else
        log_error "Nu am putut crea directorul $user_report_dir pentru raport!"
      fi
    fi
  fi
}

# Verifică dacă WordPress este instalat în directorul dat (sau curent)
wp_is_installed() {
  local dir="${1:-.}"
  [[ -f "$dir/wp-config.php" && -d "$dir/wp-content" ]] && return 0 || return 1
}

# Instalează WordPress complet (fișiere + baza de date)
wp_install_if_needed() {
  local WP_WEBROOT="$1"
  local WP_DOMAIN="$2"
  local WP_USERNAME="$3"
  local DB_NAME="$4"
  local DB_USER="$5"
  local DB_PASS="$6"
  local DB_HOST="${7:-localhost}"
  local WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
  local WP_ADMIN_PASS="${WP_ADMIN_PASS:-}"
  local WP_ADMIN_EMAIL="admin@$WP_DOMAIN"
  
  log_info "Instalez WordPress izolat în $WP_WEBROOT..." "cyan"
  
  # Generează parolă admin dacă nu este setată
  if [ -z "$WP_ADMIN_PASS" ]; then
    WP_ADMIN_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
  fi
  
  # 1. Descarcă și extrage WordPress dacă nu există
  if [ ! -f "$WP_WEBROOT/wp-config.php" ] || [ ! -d "$WP_WEBROOT/wp-content" ]; then
    wp_download_and_install_files "$WP_WEBROOT" "$WP_USERNAME"
  fi
  
  # 2. Generează wp-config.php dacă nu există și avem informațiile DB
  if [ ! -f "$WP_WEBROOT/wp-config.php" ] && [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASS" ]; then
    log_info "Generez wp-config.php..." "cyan"
    if command -v wp_generate_config >/dev/null 2>&1; then
      if wp_generate_config "$WP_WEBROOT" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"; then
        log_info "wp-config.php generat cu succes!" "green"
      else
        log_warning "Nu am putut genera wp-config.php automat."
      fi
    else
      log_warning "Funcția wp_generate_config nu este disponibilă."
    fi
  fi
  
  # 3. Instalează WordPress în baza de date dacă nu este instalat
  if command -v wp >/dev/null 2>&1 && [ -f "$WP_WEBROOT/wp-config.php" ]; then
    # Verifică dacă WordPress este deja instalat în DB
    if ! sudo -u "$WP_USERNAME" wp --path="$WP_WEBROOT" core is-installed 2>/dev/null; then
      log_info "Instalarea WordPress în baza de date..." "cyan"
      # Încearcă să instaleze WordPress în DB
      if sudo -u "$WP_USERNAME" wp --path="$WP_WEBROOT" core install \
        --url="http://$WP_DOMAIN" \
        --title="$WP_DOMAIN" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" 2>/dev/null; then
        
        log_info "WordPress instalat cu succes în baza de date!" "green"
        
        # Generează raportul de instalare
        wp_generate_install_report "$WP_DOMAIN" "$WP_WEBROOT" "$WP_USERNAME" "$WP_ADMIN_USER" "$WP_ADMIN_PASS" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"
        
      else
        log_warning "WP-CLI nu a reușit să instaleze WordPress în DB, dar fișierele sunt prezente."
      fi
    else
      log_info "WordPress este deja instalat în baza de date." "green"
    fi
  else
    log_warning "WP-CLI nu este disponibil sau wp-config.php lipsește. Fișierele WordPress au fost copiate."
  fi
  
  log_info "Instalarea WordPress pentru $WP_DOMAIN ($WP_USERNAME) a fost finalizată." "green"
}

# Face backup rapid la fișierele WordPress
wp_backup_files() {
  local dir="${1:-.}"
  local out="${2:-wp_backup_$(date +%F).tar.gz}"
  tar czf "$out" -C "$dir" .
}

# Update WordPress core, plugins și teme cu WP-CLI
wp_update_all() {
  local dir="${1:-.}"
  if ! command -v wp >/dev/null; then
    echo "WP-CLI not installed!"; return 1
  fi
  wp core update --path="$dir"
  wp plugin update --all --path="$dir"
  wp theme update --all --path="$dir"
}

# Wrapper for platform_steps.sh compatibility
install_wordpress_latest() {
  # Încarcă variabilele de user/domeniu dacă există
  if [ -f /tmp/stack_user_env ]; then
    source /tmp/stack_user_env
  fi
  
  # Fallback dacă nu există variabile
  WP_DOMAIN="${STACK_DOMAIN:-localhost}"
  WP_USERNAME="${STACK_USERNAME:-wordpress}"
  DOMAIN_DIR="$WP_DOMAIN"
  WP_WEBROOT="/home/$WP_USERNAME/$DOMAIN_DIR"

  # Creează și setează permisiuni pentru webroot
  if ! sudo mkdir -p "$WP_WEBROOT"; then 
    log_error "mkdir $WP_WEBROOT failed"
    ls -ld "$(dirname $WP_WEBROOT)" 
    return 1
  fi
  
  if ! sudo chown $WP_USERNAME:www-data "$WP_WEBROOT"; then 
    log_error "chown $WP_WEBROOT failed (user: $WP_USERNAME)"
    ls -ld "$WP_WEBROOT"
    return 1
  fi

  # Instalează fișierele WordPress
  wp_download_and_install_files "$WP_WEBROOT" "$WP_USERNAME"

  # Generează wp-config.php dacă nu există și avem informațiile DB
  if [ ! -f "$WP_WEBROOT/wp-config.php" ] && [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASS" ]; then
    log_info "Generez wp-config.php pentru $WP_DOMAIN..." "cyan"
    if command -v wp_generate_config >/dev/null 2>&1; then
      if wp_generate_config "$WP_WEBROOT" "$DB_NAME" "$DB_USER" "$DB_PASS" "${DB_HOST:-localhost}"; then
        log_info "wp-config.php generat cu succes!" "green"
      else
        log_warning "Nu am putut genera wp-config.php automat."
      fi
    else
      log_warning "Funcția wp_generate_config nu este disponibilă."
    fi
  fi

  # Actualizează opțiunile WordPress cu WP-CLI
  wp_update_options "$WP_WEBROOT" "$WP_DOMAIN" "$WP_USERNAME"
  
  # Generează raportul de instalare
  wp_generate_install_report "$WP_DOMAIN" "$WP_WEBROOT" "$WP_USERNAME" "$WP_ADMIN_USER" "$WP_ADMIN_PASS" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"
}

# Wrapper pentru wp_install_if_needed care folosește variabilele standard de DB
wp_install_with_db() {
  local WP_WEBROOT="$1"
  local WP_DOMAIN="$2"
  local WP_USERNAME="$3"
  
  # Încarcă variabilele de DB dacă există
  if [ -f /tmp/stack_user_env ]; then
    source /tmp/stack_user_env
  fi
  
  # Folosește variabilele de mediu sau fallback-uri
  local DB_NAME="${DB_NAME:-wp_${WP_USERNAME}}"
  local DB_USER="${DB_USER:-${WP_USERNAME}}"
  local DB_PASS="${DB_PASS:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)}"
  local DB_HOST="${DB_HOST:-localhost}"
  
  log_info "Folosesc DB: $DB_NAME (user: $DB_USER, host: $DB_HOST)" "cyan"
  
  # Apelează funcția principală cu parametrii DB
  wp_install_if_needed "$WP_WEBROOT" "$WP_DOMAIN" "$WP_USERNAME" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"
}