#!/bin/bash
#
# install_monitoring.sh - Part of LOMP Stack v3.0
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
# install_monitoring.sh - Instalează instrumente de monitorizare (opțional)

# Sourcing robust, indiferent de directorul de execuție (inclusiv din bash -c sau symlink)
SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Sourcing absolut, fallback cu warning dacă lipsesc
if [ -f "$PROJECT_ROOT/helpers/utils/functions.sh" ]; then
  . "$PROJECT_ROOT/helpers/utils/functions.sh"
else
  echo "[FATAL] Nu găsesc functions.sh la $PROJECT_ROOT/helpers/utils/functions.sh" >&2; exit 2
fi
if [ -f "$PROJECT_ROOT/helpers/utils/lang.sh" ]; then
  . "$PROJECT_ROOT/helpers/utils/lang.sh"
else
  echo "[FATAL] Nu găsesc lang.sh la $PROJECT_ROOT/helpers/utils/lang.sh" >&2; exit 2
fi
color_echo cyan "$(tr_lang monitoring_install)"

# Source system helpers for shared monitoring functions
if [ -f "$PROJECT_ROOT/helpers/monitoring/system_helpers.sh" ]; then
  . "$PROJECT_ROOT/helpers/monitoring/system_helpers.sh"
else
  echo "[FATAL] Nu găsesc system_helpers.sh la $PROJECT_ROOT/helpers/monitoring/system_helpers.sh" >&2; exit 2
fi

# Health-check webserver
check_webserver_health() {
  local ws_sel="$1"
  if [[ "$ws_sel" == "ols" ]]; then
    if ! systemctl is-active --quiet lsws; then
      color_echo red "[EROARE] OpenLiteSpeed nu rulează!"; return 1
    fi
  elif [[ "$ws_sel" == "nginx" ]]; then
    if ! systemctl is-active --quiet nginx; then
      color_echo red "[EROARE] Nginx nu rulează!"; return 1
    fi
  elif [[ "$ws_sel" == "apache" ]]; then
    if ! systemctl is-active --quiet apache2; then
      color_echo red "[EROARE] Apache nu rulează!"; return 1
    fi
  fi
  color_echo green "[OK] Webserverul este funcțional."
}

# Health-check PHP/lsphp
check_php_health() {
  local ws_sel="$1"
  if [[ "$ws_sel" == "ols" ]]; then
    # Detectează lsphp în /usr/bin/ și /usr/local/lsws/lsphp*/bin/lsphp
    local found=0
    local errors=0
    # Caută lsphp* în /usr/bin/
    for bin in /usr/bin/lsphp*; do
      [[ -x "$bin" && "$bin" =~ lsphp[0-9]+$ ]] || continue
      found=1
      if ! "$bin" -v >/dev/null 2>&1; then
        color_echo red "[EROARE] $bin nu răspunde corect!"; errors=1
      fi
    done
    # Caută lsphp în /usr/local/lsws/lsphp*/bin/lsphp
    for bin in /usr/local/lsws/lsphp*/bin/lsphp; do
      [[ -x "$bin" ]] || continue
      found=1
      if ! "$bin" -v >/dev/null 2>&1; then
        color_echo red "[EROARE] $bin nu răspunde corect!"; errors=1
      fi
    done
    if [[ $found -eq 0 ]]; then
      color_echo red "[EROARE] Nicio versiune lsphp* nu este instalată în /usr/bin/ sau /usr/local/lsws/lsphp*/bin/lsphp!"; return 1
    fi
    if [[ $errors -ne 0 ]]; then
      return 1
    fi
  else
    # Verifică toate versiunile php* instalate (php, php8.1, php8.2 etc.)
    local found=0
    local errors=0
    for bin in /usr/bin/php*; do
      [[ -x "$bin" && "$bin" =~ php([0-9]+\.[0-9]+)?$ ]] || continue
      found=1
      if ! "$bin" -v >/dev/null 2>&1; then
        color_echo red "[EROARE] $bin nu răspunde corect!"; errors=1
      fi
    done
    if [[ $found -eq 0 ]]; then
      color_echo red "[EROARE] Nicio versiune php* nu este instalată!"; return 1
    fi
    if [[ $errors -ne 0 ]]; then
      return 1
    fi
  fi
  color_echo green "[OK] PHP/lsphp este funcțional."
}

# Health-check WP-CLI
check_wpcli_health() {
  if ! command -v wp >/dev/null 2>&1; then
    color_echo red "[EROARE] WP-CLI nu este instalat!"; return 1
  fi
  if ! WP_CLI_PHP=/usr/bin/php wp --info >/dev/null 2>&1; then
    color_echo red "[EROARE] WP-CLI nu răspunde corect cu PHP standard!"; return 1
  fi
  color_echo green "[OK] WP-CLI este funcțional cu PHP standard."
}

# Health-check WordPress
check_wordpress_health() {
  local wp_dir="$1"
  if [[ -z "$wp_dir" || ! -d "$wp_dir" ]]; then
    color_echo red "[EROARE] Directorul WordPress $wp_dir nu există!";
    # Debug suplimentar: permisiuni și user curent
    if [[ -n "$hc_user" ]]; then
      color_echo yellow "[DEBUG] Utilizator așteptat pentru WordPress: $hc_user"
    fi
    color_echo yellow "[DEBUG] Utilizator curent execuție: $(whoami)"
    color_echo yellow "[DEBUG] Permisiuni parent: $(ls -ld "$(dirname \"$wp_dir\")")"
    return 1
  fi
  # Validare permisiuni de scriere și owner pe directorul WordPress
  if [[ ! -w "$wp_dir" ]]; then
    color_echo red "[EROARE] Directorul $wp_dir NU are permisiuni de scriere!"; ok=0
  fi
  local owner_info group_info
  owner_info=$(stat -c '%U' "$wp_dir" 2>/dev/null)
  group_info=$(stat -c '%G' "$wp_dir" 2>/dev/null)
  color_echo yellow "[DEBUG] Owner $wp_dir: $owner_info"
  color_echo yellow "[DEBUG] Grup $wp_dir: $group_info"
  if [[ -n "$hc_user" && "$owner_info" != "$hc_user" ]]; then
    color_echo red "[EROARE] Ownerul directorului $wp_dir este '$owner_info', dar utilizatorul așteptat este '$hc_user'! Recomandat: chown -R $hc_user:$hc_user $wp_dir dacă este nevoie."
    ok=0
  fi
  if [[ -n "$hc_user" && "$group_info" != "$hc_user" ]]; then
    color_echo yellow "[WARN] Grupul directorului $wp_dir este '$group_info', dar ideal ar fi să fie '$hc_user'. Recomandat: chgrp -R $hc_user $wp_dir dacă este nevoie."
  fi
  local ok=1
  if [[ ! -f "$wp_dir/wp-config.php" ]]; then
    color_echo red "[EROARE] wp-config.php lipsește în $wp_dir!"; ok=0
  elif [[ ! -r "$wp_dir/wp-config.php" ]]; then
    color_echo red "[EROARE] wp-config.php există dar nu are permisiuni de citire!"; ok=0
  fi
  if [[ ! -d "$wp_dir/wp-content" ]]; then
    color_echo red "[EROARE] Directorul wp-content lipsește în $wp_dir!"; ok=0
  elif [[ ! -r "$wp_dir/wp-content" ]]; then
    color_echo red "[EROARE] Directorul wp-content există dar nu are permisiuni de citire!"; ok=0
  fi
  if [[ ! -f "$wp_dir/wp-includes/version.php" ]]; then
    color_echo red "[EROARE] wp-includes/version.php lipsește în $wp_dir!"; ok=0
  elif [[ ! -r "$wp_dir/wp-includes/version.php" ]]; then
    color_echo red "[EROARE] wp-includes/version.php există dar nu are permisiuni de citire!"; ok=0
  fi
  if [[ ! -f "$wp_dir/wp-admin/index.php" ]]; then
    color_echo red "[EROARE] wp-admin/index.php lipsește în $wp_dir!"; ok=0
  elif [[ ! -r "$wp_dir/wp-admin/index.php" ]]; then
    color_echo red "[EROARE] wp-admin/index.php există dar nu are permisiuni de citire!"; ok=0
  fi
  if [[ -f "$wp_dir/.htaccess" ]]; then
    if [[ ! -r "$wp_dir/.htaccess" ]]; then
      color_echo red "[EROARE] .htaccess există dar nu are permisiuni de citire!"; ok=0
    fi
  else
    color_echo yellow "[WARN] .htaccess lipsește în $wp_dir (nu este obligatoriu, dar recomandat pentru permisiuni și rewrite)."
  fi
  if [[ $ok -eq 1 ]]; then
    color_echo green "[OK] WordPress a fost instalat corect în $wp_dir (inclusiv permisiuni esențiale)."
  else
    color_echo red "[EROARE] WordPress nu a fost instalat complet sau are permisiuni greșite în $wp_dir!"; return 1
  fi
}

# Health-check Redis
check_redis_health() {
  # Nu face health-check dacă redis-server sau redis-cli nu sunt instalate
  if ! command -v redis-server >/dev/null 2>&1 || ! command -v redis-cli >/dev/null 2>&1; then
    color_echo yellow "[INFO] Redis nu este instalat. Se omite health-check-ul."
    return 0
  fi
  # Testează întâi socket, apoi TCP doar dacă socketul nu răspunde
  if redis-cli -s /var/run/redis/redis-server.sock ping | grep -q PONG; then
    color_echo green "[OK] Redis este funcțional pe socket (/var/run/redis/redis-server.sock)."
    return 0
  else
    color_echo yellow "[INFO] Redis socket nu răspunde, încerc TCP..."
    if redis-cli -h 127.0.0.1 -p 6379 ping | grep -q PONG; then
      color_echo green "[OK] Redis este funcțional pe TCP (127.0.0.1:6379)."
      return 0
    else
      color_echo red "[EROARE] Redis nu răspunde nici pe socket, nici pe TCP!"
      return 1
    fi
  fi
}

# Health-check MariaDB (din db_helpers.sh)
check_mariadb_health() {
  local errors=0
  # color_echo yellow "[DB] Verificare stare MariaDB..."
  if ! sudo systemctl is-active --quiet mariadb; then
    color_echo red "[EROARE] Serviciul MariaDB nu rulează!"; errors=1
  fi
  if ! sudo mariadb --version >/dev/null 2>&1; then
    color_echo red "[EROARE] Binarul mariadb nu este funcțional!"; errors=1
  fi
  if ! sudo mysqladmin ping >/dev/null 2>&1; then
    color_echo red "[EROARE] MariaDB nu răspunde la ping!"; errors=1
  fi
  if ! sudo mysql -e 'SHOW DATABASES;' >/dev/null 2>&1; then
    color_echo red "[EROARE] Nu se pot lista bazele de date cu root!"; errors=1
  fi
  if [[ $errors -eq 0 ]]; then
    color_echo green "[OK] MariaDB este instalat și configurat corect."
    return 0
  else
    color_echo red "[EROARE] MariaDB are probleme de instalare/configurare!"
    return 1
  fi
}

# Verifică sănătatea instalării WordPress (folosește WP-CLI pentru validări avansate)
wp_health_check() {
  local dir="${1:-.}"
  if ! command -v wp >/dev/null; then
    color_echo red "[EROARE] WP-CLI nu este instalat!"; return 1
  fi
  if [[ ! -d "$dir" ]]; then
    color_echo red "[EROARE] Directorul WordPress $dir nu există!" >&2
    ls -ld "$dir" 2>&1
    parent_dir=$(dirname "$dir")
    color_echo yellow "[DEBUG] Permisiuni parent: $(ls -ld "$parent_dir" 2>/dev/null)"
    color_echo yellow "[DEBUG] Utilizator execuție: $(whoami)"
    return 1
  fi
  color_echo yellow "[DEBUG] Directorul WordPress: $dir"
  ls -ld "$dir"
  color_echo yellow "[DEBUG] Conținut director:"
  ls -l "$dir"
  
  # Verifică integritatea fișierelor WordPress cu WP-CLI
  if ! wp core verify-checksums --path="$dir" --allow-root; then
    color_echo red "[EROARE] Verificarea checksum-urilor WordPress a eșuat!"
    return 1
  fi
  
  # Verifică starea plugin-urilor
  if ! wp plugin status --path="$dir" --allow-root; then
    color_echo red "[EROARE] Verificarea plugin-urilor WordPress a eșuat!"
    return 1
  fi
  
  color_echo green "[OK] WordPress health check complet cu WP-CLI a fost efectuat cu succes."
}

# Health-check Certbot
check_certbot_health() {
  if command -v certbot >/dev/null 2>&1; then
    if ! certbot --version >/dev/null 2>&1; then
      color_echo red "[EROARE] Certbot nu răspunde corect!"; exit 1
    fi
    color_echo green "[OK] Certbot este funcțional."
  else
    color_echo yellow "[INFO] Certbot nu este instalat."
  fi
}

run_all_health_checks() {
  color_echo cyan "==================== RAPORT HEALTH-CHECK STACK ===================="
  local errors=0
  # Determină user/domain pentru health-check (fallback la /var/www/wordpress dacă nu există env)
  # Determină corect calea WordPress pentru health-check izolat
  local WP_USER_DIR="/var/www/wordpress"
  if [[ -f /tmp/stack_user_env ]]; then
    local hc_user hc_domain hc_dir
    hc_user=$(grep '^STACK_USERNAME=' /tmp/stack_user_env | cut -d'=' -f2)
    hc_domain=$(grep '^STACK_DOMAIN=' /tmp/stack_user_env | cut -d'=' -f2)
    hc_dir="$hc_domain"
    if [[ -n "$hc_user" && -n "$hc_dir" ]]; then
      WP_USER_DIR="/home/$hc_user/$hc_dir"
    fi
  fi
  check_webserver_health "$1" || errors=1
  check_php_health "$1" || errors=1
  check_wpcli_health || errors=1
  check_wordpress_health "$WP_USER_DIR" || errors=1
  check_redis_health || errors=1
  check_mariadb_health || errors=1
  if [[ -d "$WP_USER_DIR" ]]; then
    wp_health_check "$WP_USER_DIR"
  else
    color_echo yellow "[WARN] Directorul WordPress $WP_USER_DIR nu există, nu pot rula health-check WP."
  fi
  check_certbot_health
  color_echo cyan "==================== SFÂRȘIT RAPORT HEALTH-CHECK ===================="
  if [[ $errors -ne 0 ]]; then
    color_echo red "\n[INFO] Au fost detectate probleme în stack. Vezi mesajele de mai sus. Apasă Enter pentru a reveni la meniu."
    read -r _
  else
    color_echo green "\n[INFO] Toate componentele principale sunt funcționale. Apasă Enter pentru a reveni la meniu."
    read -r _
  fi
}
