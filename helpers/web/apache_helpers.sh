#!/bin/bash
#
# apache_helpers.sh - Part of LOMP Stack v3.0
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
# apache_helpers.sh - Helper pentru configurare Apache vhost și optimizare php.ini pentru WordPress

# Configurează vhost Apache pentru WordPress
# Usage: configure_apache_vhost_wordpress <user> <domain>
configure_apache_vhost_wordpress() {
  local user="$1"
  local domain="$2"
  local docroot="/home/$user/www/$domain"
  local vhost_file="/etc/apache2/sites-available/$domain.conf"
  color_echo yellow "[Apache] Configurare vhost WordPress pentru $user/$domain..."
  sudo mkdir -p "$docroot"
  sudo tee "$vhost_file" >/dev/null <<EOF
<VirtualHost *:80>
    ServerName $domain
    DocumentRoot $docroot
    <Directory $docroot>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "/var/log/apache2/${domain}_error.log"
    CustomLog "/var/log/apache2/${domain}_access.log" combined
</VirtualHost>
EOF
  sudo a2ensite "$domain.conf"
  sudo systemctl reload apache2
}

# Optimizări PHP ini pentru WordPress (global, pentru php.ini)
optimize_apache_php_ini_wordpress() {
  color_echo yellow "[Apache] Optimizare php.ini pentru WordPress..."
  PHP_INI="/etc/php/*/apache2/php.ini"
  sudo sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^post_max_size.*/post_max_size = 64M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^memory_limit.*/memory_limit = 256M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^max_execution_time.*/max_execution_time = 120/' $PHP_INI 2>/dev/null || true
  sudo systemctl restart apache2
}
