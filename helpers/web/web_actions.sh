# shellcheck shell=bash
# web_actions.sh - Funcții generice pentru acțiuni de start/stop/restart/status webservere

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/dependency_manager.sh"
source "$SCRIPT_DIR/../utils/error_handler.sh"

# Initialize error handling
setup_error_handlers

# Source helpers using dependency manager
source_stack_helper "functions"
source_stack_helper "lang"

# Usage: webserver_action <tip> <actiune>
# tip: ols | nginx | apache
# actiune: start | stop | restart | status
webserver_action() {
  local ws_type="$1" action="$2"
  local service_name msg_key
  case "$ws_type" in
    ols|openlitespeed)
      service_name="openlitespeed"
      msg_key="ols_${action}"
      ;;
    nginx)
      service_name="nginx"
      msg_key="nginx_${action}"
      ;;
    apache|apache2)
      service_name="apache2"
      msg_key="apache_${action}"
      ;;
    *)
      log_error "[WEB] Tip webserver necunoscut ($ws_type)"; return 1;;
  esac
  color_echo cyan "$(tr_lang $msg_key)"
  sudo service "$service_name" "$action"
}

# Funcție generică pentru instalare webserver
# Usage: install_web_package <tip>
install_web_package() {
  local ws_type="$1" pkg msg_key
  case "$ws_type" in
    ols|openlitespeed)
      pkg="openlitespeed"
      msg_key="ols_install"
      ;;
    nginx)
      pkg="nginx"
      msg_key="nginx_install"
      ;;
    apache|apache2)
      pkg="apache2"
      msg_key="apache_install"
      ;;
    *)
      color_echo red "[WEB] Tip webserver necunoscut ($ws_type)"; return 1;;
  esac
  color_echo cyan "$(tr_lang $msg_key)"
  if [[ "$ws_type" == "ols" || "$ws_type" == "openlitespeed" ]]; then
    wget -O - https://repo.litespeed.sh | sudo bash
  fi
  sudo apt install -y "$pkg"
}
