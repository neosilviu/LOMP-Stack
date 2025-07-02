#!/bin/bash
#
# install.sh - Scriptul principal de instalare cu meniu interactiv, traduceri și detecție automată a mediului
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
# Folosește funcții din helpers/ pentru modularitate și claritate.

# Încarcă modulele îmbunătățite
source helpers/utils/author_info.sh
source helpers/utils/dependency_manager.sh
source helpers/utils/error_handler.sh

# Configurează error handling
setup_error_handlers
export DEBUG_MODE="${DEBUG_MODE:-0}"

# Încarcă modulele existente folosind noul sistem
source_stack_helper "utils/functions.sh"
source_stack_helper "utils/platform_steps.sh" 
source_stack_helper "utils/menu_helpers.sh"

# Detectează mediul și setează variabila globală ENV_TYPE



# Inițializează mediul și limbajul
init_stack_environment

# Main menu loop optimizat
while true; do
  log_info "Main menu shown to user."
  clear
  main_menu_prompt
  mode_sel="$(echo "$REPLY" | tr -d '\r\n[:space:]')"
  [[ -z "$mode_sel" ]] && continue
  case $mode_sel in
    0)
      log_info "User exited the installer."
      log_info "$(tr_lang exit)"; exit 0;;
    1|2|3)
      # Confirmare separată pentru fiecare opțiune
      if [[ $mode_sel == 1 ]]; then
        confirm_action "$(tr_lang opt1) $(tr_lang confirm_hint)" || continue
      elif [[ $mode_sel == 2 ]]; then
        confirm_action "$(tr_lang opt2) $(tr_lang confirm_hint)" || continue
      fi
      [[ $mode_sel == 3 ]] && log_info "User selected advanced install."
      if [[ $mode_sel == 3 ]]; then
        select_webserver >&2; [[ $? -eq 1 ]] && continue
        select_database >&2; [[ $? -eq 1 ]] && continue
      fi
      log_info "User selected install option $mode_sel."
      case $ENV_TYPE in
        WSL) install_on_wsl;;
        DOCKER) install_on_docker;;
        PROXMOX) install_on_proxmox;;
        DEBIAN) install_on_debian;;
        UBUNTU) install_on_ubuntu;;
        *) install_on_unknown;;
      esac
      read -p $'\n'"$(tr_lang back)";;
    4)
      log_info "$(tr_lang opt4)"
      log_info "User opened component manager."
      bash component_manager.sh
      read -p $'\n'"$(tr_lang back)";;
    5)
      log_info "User selected add user/domain."
      add_user_domain_menu
      continue;;
    6)
      log_info "User selected backup manager."
      if [ -x "helpers/utils/backup_manager.sh" ]; then
        bash helpers/utils/backup_manager.sh && log_info "Backup manager completed successfully." || log_error "Backup manager failed!"
      else
        log_error "backup_manager.sh nu are permisiune de execuție! Rulează: chmod +x helpers/utils/backup_manager.sh"
        log_error "backup_manager.sh nu are permisiune de execuție!"
      fi
      continue;;
    7)
      log_info "User selected update system."
      if [ -f "helpers/utils/update_system.sh" ]; then
        bash helpers/utils/update_system.sh && log_info "System update completed successfully." || log_error "System update failed!"
      else
        log_error "update_system.sh nu a fost găsit în helpers/utils!"
        log_error "update_system.sh nu a fost găsit în helpers/utils!"
      fi
      read -p "$(tr_lang press_enter)"
      continue;;
    8)
      confirm_action "$(tr_lang clean_confirm)" || continue
      log_info "User selected system cleanup."
      bash cleanup.sh --lang $LANG_OPT
      read -p $'\n'"$(tr_lang back)";;
    *)
      [[ -n "$mode_sel" ]] && log_error "Invalid menu selection: $mode_sel" && log_error "$(tr_lang invalid)" && sleep 1
      ;;
  esac
done
