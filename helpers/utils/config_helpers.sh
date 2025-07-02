#!/bin/bash
#==============================================================================
# LOMP Stack v3.0 - Configuration Helpers
# 
# Functions for copying configuration files per user
# 
# Author: Silviu Ilie
# Email: neosilviu@gmail.com
# Company: aemdPC
# License: MIT
# Version: 3.0
# 
# Description: Provides utility functions for managing and copying
# configuration files for LOMP Stack users, including rclone and PHP
# configurations with proper permissions.
#==============================================================================

# Load author info
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/author_info.sh" ]]; then
    source "$SCRIPT_DIR/author_info.sh"
fi

copy_user_config_files() {
  local username="$1"
  local user_config_dir="$2"
  # Copiază rclone.conf dacă există
  local RCLONE_CONF_SRC="/etc/rclone.conf"
  if [ -f "$RCLONE_CONF_SRC" ]; then
    sudo cp "$RCLONE_CONF_SRC" "$user_config_dir/rclone.conf"
    sudo chown "$username":www-data "$user_config_dir/rclone.conf"
    sudo chmod 640 "$user_config_dir/rclone.conf"
    echo "Rclone config: $user_config_dir/rclone.conf (copiat automat)"
  fi
  # Copiază php.ini personalizat dacă există
  local PHP_INI_SRC
  PHP_INI_SRC="/etc/php/$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')/fpm/php.ini"
  if [ -f "$PHP_INI_SRC" ]; then
    sudo cp "$PHP_INI_SRC" "$user_config_dir/php.ini"
    sudo chown "$username":www-data "$user_config_dir/php.ini"
    sudo chmod 640 "$user_config_dir/php.ini"
    echo "PHP config: $user_config_dir/php.ini (copiat automat)"
  fi
}

# Funcție pentru afișarea informațiilor despre autor
show_config_helpers_info() {
    if command -v print_author_header >/dev/null 2>&1; then
        print_author_header
        echo
        echo "Configuration Helpers Module - User configuration management"
        echo "Provides utilities for copying and managing configuration files"
        echo "for LOMP Stack users with proper permissions and ownership."
        echo
        print_author_footer
    else
        echo "=============================================="
        echo "   LOMP Stack v3.0 - Configuration Helpers"
        echo "=============================================="
        echo "Author: Silviu Ilie"
        echo "Email: neosilviu@gmail.com"
        echo "Company: aemdPC"
        echo "License: MIT"
        echo "Version: 3.0"
        echo "=============================================="
    fi
}

# Export functions
export -f copy_user_config_files show_config_helpers_info
