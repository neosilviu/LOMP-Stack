#!/bin/bash
#
# wp_config_helper.sh - Part of LOMP Stack v3.0
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
# wp_config_helper.sh - Funcții pentru generare și modificare wp-config.php

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/dependency_manager.sh"
source "$SCRIPT_DIR/../utils/error_handler.sh"

# Initialize error handling
setup_error_handlers
# DEBUG_MODE=true  # Removed as it was unused

# Source helpers using dependency manager
source_stack_helper "functions"

check_wpcli_exists() {
  if ! command -v wp >/dev/null 2>&1; then
    fatal_error "WP-CLI nu este instalat! Rulează scriptul principal de instalare pentru a instala WP-CLI."
    exit 1
  fi
}

# Generează un wp-config.php complet cu chei de securitate
wp_generate_config() {
  # Argumente: dir db_name db_user db_pass db_host
  local dir="$1" db_name="$2" db_user="$3" db_pass="$4" db_host="$5"
  # Debug parametri primiți
  log_debug "wp_generate_config: DIR=$dir DB_NAME=$db_name DB_USER=$db_user DB_PASS=$db_pass DB_HOST=$db_host"
  # Nu suprascrie dacă există deja wp-config.php
  if [[ -f "$dir/wp-config.php" ]]; then
    log_info "wp-config.php există deja în $dir, nu suprascriu." "yellow"
    return 0
  fi
  # Rezolvare robustă permisiuni director
  if [[ ! -d "$dir" ]]; then
    log_error "Directorul $dir nu există! Nu pot genera wp-config.php."
    return 1
  fi
  if [[ ! -w "$dir" ]]; then
    log_debug "Directorul $dir NU are permisiuni de scriere pentru userul $(whoami). Încerc automat corectare owner la $SUDO_USER:www-data..."
    if [[ -n "$SUDO_USER" ]]; then
      if sudo chown -R "$SUDO_USER:www-data" "$dir"; then
        log_info "Owner corectat automat: $dir este acum deținut de $SUDO_USER:www-data." "green"
      else
        log_error "Nu am putut schimba ownerul pentru $dir! Fă manual: sudo chown -R $SUDO_USER:www-data $dir"
        return 1
      fi
    else
      log_error "Scriptul nu rulează cu sudo, nu pot corecta automat permisiunile. Fă manual: sudo chown -R <user>:www-data $dir"
      return 1
    fi
    # Re-verifică permisiunea de scriere după corectare
    if [[ ! -w "$dir" ]]; then
      log_error "Directorul $dir încă NU are permisiuni de scriere pentru userul $(whoami) după corectare!"
      return 1
    fi
  fi
  local owner group
  owner=$(stat -c '%U' "$dir" 2>/dev/null)
  group=$(stat -c '%G' "$dir" 2>/dev/null)
  log_debug "Owner $dir: $owner"
  log_debug "Grup $dir: $group"
  # Generează fișierul wp-config.php
  cat > "$dir/wp-config.php" <<EOF
<?php
define('DB_NAME', '$db_name');
define('DB_USER', '$db_user');
define('DB_PASSWORD', '$db_pass');
define('DB_HOST', '$db_host');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// Redis cache (dacă există pluginul redis-cache activ)

// Redis pe socket (dacă există, altfel fallback la TCP)
if (file_exists('/var/run/redis/redis-server.sock')) {
  define('WP_REDIS_PATH', '/var/run/redis/redis-server.sock');
} else {
  define('WP_REDIS_HOST', '127.0.0.1');
  define('WP_REDIS_PORT', 6379);
}
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_DISABLED', false);


// OPcache recomandat (doar dacă e activ la nivel de PHP, dar dezactivează pentru CLI)
if (function_exists('opcache_get_status')) {
  if (php_sapi_name() !== 'cli') {
    ini_set('opcache.enable', 1);
    ini_set('opcache.enable_cli', 1);
    ini_set('opcache.memory_consumption', 128);
    ini_set('opcache.interned_strings_buffer', 16);
    ini_set('opcache.max_accelerated_files', 10000);
    ini_set('opcache.revalidate_freq', 60);
    ini_set('opcache.fast_shutdown', 1);
  } else {
    ini_set('opcache.enable_cli', 0);
  }
}

// Alte optimizări WordPress
define('WP_POST_REVISIONS', 5);
define('AUTOSAVE_INTERVAL', 120);
define('EMPTY_TRASH_DAYS', 7);
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');
define('WP_CACHE', true); // Activează cache la nivel de WP
EOF
  # Adaugă chei de securitate generate random
  curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> "$dir/wp-config.php"

  # Elimină ini_set opcache pentru CLI (WP-CLI)
  cat >> "$dir/wp-config.php" <<'EOF'
if (PHP_SAPI !== 'cli') {
  ini_set('opcache.enable', 1);
  ini_set('opcache.enable_cli', 1);
  ini_set('opcache.memory_consumption', 128);
  ini_set('opcache.interned_strings_buffer', 16);
  ini_set('opcache.max_accelerated_files', 10000);
  ini_set('opcache.revalidate_freq', 60);
  ini_set('opcache.fast_shutdown', 1);
}
EOF

  # Adaugă $table_prefix înainte de require_once (obligatoriu pentru WordPress)
  echo "\$table_prefix = 'wp_';" >> "$dir/wp-config.php"
  # Adaugă require_once pentru wp-settings.php la final (obligatoriu pentru WP-CLI)
  echo "require_once(ABSPATH . 'wp-settings.php');" >> "$dir/wp-config.php"
}

# Adaugă o opțiune custom în wp-config.php
wp_add_config_option() {
  local dir="${1:-.}"
  local option="$2"
  local value="$3"
  echo "define('$option', $value);" >> "$dir/wp-config.php"
}