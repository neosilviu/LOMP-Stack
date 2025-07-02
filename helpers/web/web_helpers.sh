#!/bin/bash
#
# web_helpers.sh - Part of LOMP Stack v3.0
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
# web_helpers.sh - Funcții utilitare pentru management webservere

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/dependency_manager.sh"
source "$SCRIPT_DIR/../utils/error_handler.sh"

# Initialize error handling
setup_error_handlers

# Source helpers using dependency manager
source_stack_helper "functions"

# Detectează tipul de webserver instalat (OLS, Nginx, Apache)
detect_web_type() {
  if command -v openlitespeed >/dev/null 2>&1; then
    echo "ols"
  elif command -v nginx >/dev/null 2>&1; then
    echo "nginx"
  elif command -v apache2 >/dev/null 2>&1; then
    echo "apache"
  else
    echo "none"
  fi
}

# Selectează webserverul (interactiv sau din variabilă)
select_web_type() {
  local ws_type
  echo "Alege webserverul:"
  echo "  1) OpenLiteSpeed (default)"
  echo "  2) Nginx"
  echo "  3) Apache"
  read -rp "Select [1-3]: " ws_type
  case "$ws_type" in
    2) export WEB_TYPE="nginx";;
    3) export WEB_TYPE="apache";;
    *) export WEB_TYPE="ols";;
  esac
}

# Afișează versiunea webserverului
show_web_version() {
  local ws_type
  ws_type="${1:-$(detect_web_type)}"
  case "$ws_type" in
    ols) openlitespeed -v;;
    nginx) nginx -v;;
    apache) apache2 -v;;
    *) echo "No webserver detected.";;
  esac
}

# Testează dacă portul webserverului răspunde
check_web_port() {
  local port="${1:-80}"
  (echo > /dev/tcp/localhost/$port) >/dev/null 2>&1 && echo "open" || echo "closed"
}