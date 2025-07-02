#!/bin/bash
#==============================================================================
# LOMP Stack v3.0 - SSL Helpers
# 
# Functions for generating Let's Encrypt SSL certificates
# 
# Author: Silviu Ilie
# Email: neosilviu@gmail.com
# Company: aemdPC
# License: MIT
# Version: 3.0
# 
# Description: Provides SSL certificate generation utilities for the LOMP
# Stack, supporting nginx, Apache, and OpenLiteSpeed web servers with
# automatic Let's Encrypt certificate provisioning.
#==============================================================================

# Load author info
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/author_info.sh" ]]; then
    source "$SCRIPT_DIR/author_info.sh"
fi

generate_ssl_certificate() {
  local domain="$1"
  local webroot="$2"
  if ! command -v certbot >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y certbot python3-certbot-nginx python3-certbot-apache python3-certbot
  fi
  if command -v nginx >/dev/null 2>&1; then
    sudo certbot --nginx -n --agree-tos --redirect --email "admin@$domain" -d "$domain" -d "www.$domain" || \
      echo "[WARN] Certificat Let's Encrypt (nginx) eșuat pentru $domain" | tee -a /var/log/stack_user_domain.log
    sudo nginx -t && sudo systemctl reload nginx
  elif command -v apache2 >/dev/null 2>&1; then
    sudo certbot --apache -n --agree-tos --redirect --email "admin@$domain" -d "$domain" -d "www.$domain" || \
      echo "[WARN] Certificat Let's Encrypt (apache) eșuat pentru $domain" | tee -a /var/log/stack_user_domain.log
    sudo systemctl reload apache2
  elif [ -d /usr/local/lsws ]; then
    sudo certbot certonly --webroot -w "$webroot" -n --agree-tos --email "admin@$domain" -d "$domain" -d "www.$domain" || \
      echo "[WARN] Certificat Let's Encrypt (OLS) eșuat pentru $domain" | tee -a /var/log/stack_user_domain.log
    sudo /usr/local/lsws/bin/lswsctrl restart
  fi
}

# Funcție pentru afișarea informațiilor despre autor
show_ssl_helpers_info() {
    if command -v print_author_header >/dev/null 2>&1; then
        print_author_header
        echo
        echo "SSL Helpers Module - Let's Encrypt certificate management"
        echo "Provides SSL certificate generation utilities for nginx,"
        echo "Apache, and OpenLiteSpeed web servers with automatic provisioning."
        echo
        print_author_footer
    else
        echo "=============================================="
        echo "   LOMP Stack v3.0 - SSL Helpers"
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
export -f generate_ssl_certificate show_ssl_helpers_info
