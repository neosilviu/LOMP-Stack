#!/bin/bash
#
# component_manager.sh - Part of LOMP Stack v3.0
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
# component_manager.sh - Meniu interactiv colorat pentru gestionarea componentelor suplimentare (Redis, AI, Cloudflare, etc.) după instalare.
# Folosește noile funcții de logging (log_info, log_error) și tr_lang pentru afișare modernă și traduceri.


# Source dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helpers/utils/dependency_manager.sh"
source "$SCRIPT_DIR/helpers/utils/error_handler.sh"

# Initialize error handling
setup_error_handlers

# Source helpers using the dependency manager
source_stack_helper "functions"
source_stack_helper "lang"
source_stack_helper "menu_helpers"

# Set default language if not set
export LANG_OPT="${LANG_OPT:-ro}"

while true; do

  log_info "\n\033[1;35m╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗\033[0m"
  log_info "\033[1;35m║                🧩  $(tr_lang component_manager_title 2>/dev/null || echo 'Component Manager')                ║\033[0m"
  log_info "\033[1;35m╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝\033[0m"
  color_echo yellow "  1. 🟥  | $(tr_lang cm_redis)"
  color_echo green "  2. 🤖  | $(tr_lang cm_ai)"
  color_echo cyan "  3. ☁️   | $(tr_lang cm_cloudflare)"
  color_echo blue "  4. 📊  | $(tr_lang cm_monitoring)"
  color_echo magenta "  5. 🛡️   | $(tr_lang cm_security)"
  color_echo cyan "  6. 🔍  | $(tr_lang cm_check)"
  color_echo yellow "  7. 🧹  | $(tr_lang cm_cleanup)"
  color_echo green "  8. 🔗  | $(tr_lang cm_coredeps)"
  color_echo magenta "  9. ♻️   | $(tr_lang cm_unused)"
  color_echo blue " 10. 🧩  | $(tr_lang show_component_versions)"
  color_echo blue " 11. 🧩  | $(tr_lang meniu_pachete_php_lsphp_optionale)"
  color_echo red "  0. ❌  | $(tr_lang cm_exit)"
  log_info "\033[1;30m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m"
  echo
  read -p "Alege opțiunea [0-11]: " opt
  case $opt in
    1)
      color_echo yellow "\nAlege modul de funcționare pentru Redis:"
      color_echo yellow "  1. Doar socket (fără TCP, recomandat pentru securitate și performanță)"
      color_echo yellow "  2. Doar TCP (port 6379, pentru acces rețea)"
      color_echo yellow "  3. Ambele (socket + TCP)"
      read -p "Selectează [1-3]: " redis_mode
      case $redis_mode in
        1) bash helpers/security/install_redis.sh socket-only;;
        2) bash helpers/security/install_redis.sh tcp-only;;
        3) bash helpers/security/install_redis.sh dual;;
        *) log_error "Mod invalid! Se folosește implicit doar socket."; bash helpers/security/install_redis.sh socket-only;;
      esac
      ;;
    2) bash helpers/ai/ai_server_agent.sh;;
    3) bash helpers/security/install_cloudflare.sh;;
    4) bash helpers/monitoring/install_monitoring.sh;;
    5) bash helpers/security/install_security.sh;;
    6)
      bash helpers/monitoring/install_monitoring.sh
      ws_sel=""
      if systemctl is-active --quiet lsws; then ws_sel="ols";
      elif systemctl is-active --quiet nginx; then ws_sel="nginx";
      elif systemctl is-active --quiet apache2; then ws_sel="apache";
      else ws_sel="ols"; fi
      bash -c "cd '$(pwd)' && source helpers/monitoring/install_monitoring.sh && run_all_health_checks '$ws_sel'"
      ;;
    7) bash helpers/utils/clean_demo.sh;;
    8) bash helpers/utils/check_core_dependencies.sh;;
    9) sudo apt autoremove --purge -y && sudo apt autoclean -y;;
   10) show_versions_menu;;
   11) show_php_packages_menu;;
    0) color_echo red "Iesire."; exit 0;;
    *) color_echo red "Opțiune invalidă!";;
  esac
done
