#!/bin/bash
#
# report_helpers.sh - Part of LOMP Stack v3.0
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
# report_helpers.sh - Funcții pentru raportare și export variabile stack

report_stack_install_summary() {
  local domain="$1" username="$2" webroot="$3" dbname="$4" dbuser="$5" dbpass="$6" redisdb="$7" user_logs_dir="$8" user_config_dir="$9"
  echo "\n================ RAPORT FINAL INSTALARE STACK ================"
  echo "User și domeniu: $domain ($username) create și izolate cu succes!"
  echo "Webroot: $webroot"
  echo "Baza de date MySQL: $dbname"
  echo "User DB: $dbuser"
  echo "Parolă DB: $dbpass"
  echo "Redis DB index (pt. config): $redisdb"
  echo "Redis status: $(systemctl is-active redis-server 2>/dev/null || echo 'necunoscut')"
  echo "Loguri user: $user_logs_dir"
  echo "Config user: $user_config_dir"
  if [ -f "$user_config_dir/cloudflare_config.yml" ]; then
    echo "Cloudflare config: $user_config_dir/cloudflare_config.yml (copiat automat)"
  fi
  if [[ "$STACK_CF_TUNNEL" == "1" ]]; then
    echo "Tunel Cloudflare: ACTIV (toate conexiunile trec prin tunel, porturi 80/443 blocate extern)"
  else
    echo "Tunel Cloudflare: INACTIV (SSL Let's Encrypt folosit dacă e posibil)"
  fi
  if [ -f /etc/letsencrypt/live/$domain/fullchain.pem ]; then
    echo "Certificat SSL Let's Encrypt: ACTIV pentru $domain"
  else
    echo "Certificat SSL Let's Encrypt: INACTIV pentru $domain"
  fi
  echo "Vhost webserver: configurat pentru $domain (Nginx/Apache/OLS)"
  echo "WordPress: instalat în $webroot, cu siteurl/home/blogname setate la $domain"
  echo "Admin email WordPress: admin@$domain"
  echo "============================================================="
}

export_stack_env_vars() {
  local domain="$1" username="$2" webroot="$3"
  echo "STACK_DOMAIN=$domain" > /tmp/stack_user_env
  echo "STACK_USERNAME=$username" >> /tmp/stack_user_env
  echo "STACK_WEBROOT=$webroot" >> /tmp/stack_user_env
}
