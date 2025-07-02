#!/bin/bash
#
# olsphp_helpers.sh - Part of LOMP Stack v3.0
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
# olsphp_helpers.sh - Helper pentru instalare și management PHP (lsphp) pentru OpenLiteSpeed
#
# Exemplu de utilizare cu versiune:
#   start_olsphp 81    # pornește lsphp81-fpm
#   stop_olsphp 80     # oprește lsphp80-fpm
#   restart_olsphp     # fallback, încearcă toate versiunile cunoscute
#   status_olsphp 81   # status pentru lsphp81-fpm

. "$(dirname "${BASH_SOURCE[0]}")/php_actions.sh"


# Use robust lsphp binary detection for service actions
start_olsphp() {
  local v="$1"
  local bin
  bin=$(find_lsphp_binary "$v")
  if [[ -n "$bin" ]]; then
    php_service_action lsphp start "$v"
  else
    color_echo red "lsphp$v nu a fost găsit în /usr/local/lsws/lsphp*/bin/ sau PATH."
    return 1
  fi
}
stop_olsphp() {
  local v="$1"
  local bin
  bin=$(find_lsphp_binary "$v")
  if [[ -n "$bin" ]]; then
    php_service_action lsphp stop "$v"
  else
    color_echo red "lsphp$v nu a fost găsit în /usr/local/lsws/lsphp*/bin/ sau PATH."
    return 1
  fi
}
restart_olsphp() {
  local v="$1"
  local bin
  bin=$(find_lsphp_binary "$v")
  if [[ -n "$bin" ]]; then
    php_service_action lsphp restart "$v"
  else
    color_echo red "lsphp$v nu a fost găsit în /usr/local/lsws/lsphp*/bin/ sau PATH."
    return 1
  fi
}
status_olsphp() {
  local v="$1"
  local bin
  bin=$(find_lsphp_binary "$v")
  if [[ -n "$bin" ]]; then
    php_service_action lsphp status "$v"
  else
    color_echo red "lsphp$v nu a fost găsit în /usr/local/lsws/lsphp*/bin/ sau PATH."
    return 1
  fi
}

# Instalează lsphp stack cu cea mai mare versiune disponibilă

# Instalează doar binarul lsphp (fără extensii)
install_olsphp_core() {
  color_echo yellow "$(tr_lang olsphp_install)"
  sudo apt-get update
  sudo apt-get install -y software-properties-common lsb-release ca-certificates
  latest_lsphp=$(apt-cache search '^lsphp[0-9][0-9]$' | awk '{print $1}' | sed 's/lsphp//' | sort -nr | head -n1)
  if [[ -z "$latest_lsphp" ]]; then
    color_echo red "Nu s-a găsit niciun pachet lsphp* disponibil!"
    return 1
  fi
  lsphp_pkg="lsphp$latest_lsphp"
  sudo apt-get install -y "$lsphp_pkg"
  color_echo green "lsphp versiunea $latest_lsphp a fost instalată."
}

# Instalează extensiile de bază pentru lsphp (doar dacă binarul există)
install_olsphp_extensions() {
  latest_lsphp=$(apt-cache search '^lsphp[0-9][0-9]$' | awk '{print $1}' | sed 's/lsphp//' | sort -nr | head -n1)
  if [[ -z "$latest_lsphp" ]]; then
    color_echo red "Nu s-a găsit niciun pachet lsphp* disponibil!"
    return 1
  fi
  lsphp_pkg="lsphp$latest_lsphp"
  # Instalează extensiile doar dacă binarul există
  if dpkg -l | grep -q "$lsphp_pkg"; then
    sudo apt-get install -y "$lsphp_pkg-mysql" "$lsphp_pkg-xml" "$lsphp_pkg-curl" "$lsphp_pkg-gd" "$lsphp_pkg-mbstring" "$lsphp_pkg-zip" "$lsphp_pkg-bcmath" "$lsphp_pkg-imagick" "$lsphp_pkg-intl" "$lsphp_pkg-soap" "$lsphp_pkg-redis"
    color_echo green "Extensiile lsphp pentru versiunea $latest_lsphp au fost instalate."
  else
    color_echo yellow "Binarul $lsphp_pkg nu este instalat, extensiile nu pot fi instalate."
  fi
}

olsphp_version() {
  color_echo yellow "$(tr_lang olsphp_version_info)"
  if command -v lsphp81 >/dev/null 2>&1; then
    lsphp81 -v
  else
    color_echo red "$(tr_lang olsphp_not_installed)"
  fi
}

install_olsphp_stack() {
  color_echo yellow "$(tr_lang olsphp_install)"
  sudo apt-get update
  sudo apt-get install -y software-properties-common lsb-release ca-certificates
  # Detectează cea mai mare versiune lsphp* disponibilă
  latest_lsphp=$(apt-cache search '^lsphp[0-9][0-9]$' | awk '{print $1}' | sed 's/lsphp//' | sort -nr | head -n1)
  if [[ -z "$latest_lsphp" ]]; then
    color_echo red "Nu s-a găsit niciun pachet lsphp* disponibil!"
    return 1
  fi
  lsphp_pkg="lsphp$latest_lsphp"
  # Instalează extensiile pentru acea versiune
  sudo apt-get install -y "$lsphp_pkg" "$lsphp_pkg-mysql" "$lsphp_pkg-xml" "$lsphp_pkg-curl" "$lsphp_pkg-gd" "$lsphp_pkg-mbstring" "$lsphp_pkg-zip"
  color_echo green "lsphp versiunea $latest_lsphp și extensiile au fost instalate."
}
