# shellcheck shell=bash
# helpers/platform_steps.sh - Doar logica pentru modurile minimal și ultra

_stack_install_common() {
  local ws_sel="$1"
  # Asigură utilitare esențiale și update CA pentru WSL
  sudo apt update && sudo apt install -y curl wget unzip jq
  # Repară și forțează CA certificates pentru WSL
  if grep -qi microsoft /proc/version 2>/dev/null; then
    color_echo cyan "[INFO] WSL detectat: repar și actualizez certificatele CA..."
    sudo apt-get install --reinstall -y ca-certificates
    sudo mkdir -p /etc/ssl/certs
    sudo update-ca-certificates
  fi
  # Webserver
  if [[ "$ws_sel" == "ols" ]]; then
    . "$(dirname "${BASH_SOURCE[0]}")/../web/web_ols.sh"
    install_ols_stack
  elif [[ "$ws_sel" == "nginx" ]]; then
    . "$(dirname "${BASH_SOURCE[0]}")/../web/web_nginx.sh"
    install_nginx
  elif [[ "$ws_sel" == "apache" ]]; then
    . "$(dirname "${BASH_SOURCE[0]}")/../web/web_apache.sh"
    install_apache
  fi
  # PHP/lsphp sau fallback la PHP dacă lsphp nu e disponibil
  if [[ "$ws_sel" == "ols" ]]; then
    . "$(dirname "${BASH_SOURCE[0]}")/../web/olsphp_helpers.sh"
    install_olsphp_core || {
      color_echo yellow "[WARN] lsphp nu este disponibil pentru această distribuție. Se folosește fallback la PHP standard."
      . "$(dirname "${BASH_SOURCE[0]}")/../web/php_helpers.sh"
      install_php_stack
    }
    install_olsphp_extensions
  else
    . "$(dirname "${BASH_SOURCE[0]}")/../web/php_helpers.sh"
    install_php_core
    install_php_extensions
  fi

  # WP-CLI - instalare și health-check înainte de orice user/domain
  . "$(dirname "${BASH_SOURCE[0]}")/../wp/wpcli_helpers.sh"
  install_wpcli

  # MariaDB/MySQL (ultimul stable) - instalare și health-check înainte de orice user/domain
  . "$(dirname "${BASH_SOURCE[0]}")/../db/db_helpers.sh"
  . "$(dirname "${BASH_SOURCE[0]}")/../db/db_stack_helpers.sh"
  install_selected_db
  check_mariadb_health || { color_echo red "[FATAL] MariaDB nu este funcțional!"; exit 1; }

  # Instalează Redis o singură dată la nivel de platformă
  . "$(dirname "${BASH_SOURCE[0]}")/../security/install_redis.sh"
  install_redis || color_echo yellow "[WARN] Instalare/configurare Redis eșuată! Continuăm fără Redis."

  # Meniu și creare user izolat la începutul instalării
  . "$(dirname "${BASH_SOURCE[0]}")/../user/add_user_domain.sh"
  if [[ -n "$STACK_DOMAIN" && -n "$STACK_USERNAME" ]]; then
    add_user_and_domain "$STACK_DOMAIN" "$STACK_USERNAME"
  else
    add_user_and_domain
  fi
  # Extrage user/domain din env temporar (setat de add_user_and_domain)
  USER_CREATED=$(grep '^STACK_USERNAME=' /tmp/stack_user_env | cut -d'=' -f2)
  DOMAIN_CREATED=$(grep '^STACK_DOMAIN=' /tmp/stack_user_env | cut -d'=' -f2)

  # WordPress (ultimul stable)
  . "$(dirname "${BASH_SOURCE[0]}")/../wp/wp_helpers.sh"

  # Health-check sumar la finalul instalării
  . "$(dirname "${BASH_SOURCE[0]}")/../monitoring/install_monitoring.sh"
  echo
  color_echo cyan "==================== RAPORT HEALTH-CHECK STACK ===================="
  check_webserver_health "$ws_sel"
  check_php_health "$ws_sel"
  check_wpcli_health
  check_wordpress_health
  check_redis_health
  check_mariadb_health
  # Health-check WordPress izolat pentru ultimul user/domain creat
  WP_USER_DIR="/home/$USER_CREATED/$DOMAIN_CREATED"
  if [ -d "$WP_USER_DIR" ]; then
    wp_health_check "$WP_USER_DIR"
  else
    color_echo yellow "[WARN] Directorul WordPress $WP_USER_DIR nu există, nu pot rula health-check WP."
  fi
  check_certbot_health
  color_echo cyan "==================== SFÂRȘIT RAPORT HEALTH-CHECK ===================="
}

# Inițializează mediul și limbajul pentru stack
init_stack_environment() {
  log_info "Detecting environment..."
  ENV_TYPE=$(detect_environment)
  log_info "Environment detected: $ENV_TYPE"
  color_echo yellow "[DEBUG] Environment detected: $ENV_TYPE"
  select_language
}

install_on_wsl() {
  local mode="$1"
  if [[ "$mode" == "minimal" ]]; then
    ws_sel="ols"
    color_echo cyan "[INFO] Se instalează: OpenLiteSpeed, lsphp, wp-cli, MariaDB, WordPress (ultimele versiuni stabile)"
  elif [[ "$mode" == "ultra" ]]; then
    ws_sel="nginx"
    color_echo cyan "[INFO] Se instalează: Nginx, PHP, wp-cli, MariaDB, WordPress (ultimele versiuni stabile)"
  else
    ws_sel="ols"
  fi
  _stack_install_common "$ws_sel"
}

install_on_debian() {
  color_echo cyan "[INFO] Instalare pe Debian: OpenLiteSpeed, lsphp, wp-cli, MariaDB, WordPress."
  _stack_install_common "ols"
}

install_on_ubuntu() {
  color_echo cyan "[INFO] Instalare pe Ubuntu: Nginx, PHP, wp-cli, MariaDB, WordPress."
  _stack_install_common "nginx"
}

install_on_proxmox() {
  color_echo cyan "[INFO] Instalare pe Proxmox: Apache, PHP, wp-cli, MariaDB, WordPress."
  _stack_install_common "apache"
}

install_on_docker() {
  color_echo cyan "[INFO] Instalare pe Docker: Nginx, PHP, wp-cli, MariaDB, WordPress."
  _stack_install_common "nginx"
}
install_on_unknown() {
  color_echo red "[ERROR] Mediu necunoscut. Nu se poate instala."
  exit 1
}
