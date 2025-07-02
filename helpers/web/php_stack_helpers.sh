#!/bin/bash
#
# php_stack_helpers.sh - Part of LOMP Stack v3.0
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
# php_stack_helpers.sh - Helper unificat pentru gestionarea PHP și lsphp (OpenLiteSpeed)

# Instalare PHP sau lsphp în funcție de tip
install_php_stack_unified() {
  local php_type="$1"
  case "$php_type" in
    lsphp|olsphp|openlitespeed)
      . "$(dirname "${BASH_SOURCE[0]}")/olsphp_helpers.sh"
      install_olsphp_stack
      ;;
    php|php-fpm|nginx|apache)
      . "$(dirname "${BASH_SOURCE[0]}")/php_helpers.sh"
      install_php_stack
      ;;
    *)
      color_echo red "$(tr_lang php_type_unknown): $php_type";;
  esac
}

# Pornește serviciul PHP/lsphp
start_php_stack_unified() {
  local php_type="$1"
  case "$php_type" in
    lsphp|olsphp|openlitespeed)
      . "$(dirname "${BASH_SOURCE[0]}")/olsphp_helpers.sh"
      start_olsphp
      ;;
    php|php-fpm|nginx|apache)
      . "$(dirname "${BASH_SOURCE[0]}")/php_helpers.sh"
      start_php
      ;;
    *)
      color_echo red "$(tr_lang php_type_unknown): $php_type";;
  esac
}

# Oprește serviciul PHP/lsphp
stop_php_stack_unified() {
  local php_type="$1"
  case "$php_type" in
    lsphp|olsphp|openlitespeed)
      . "$(dirname "${BASH_SOURCE[0]}")/olsphp_helpers.sh"
      stop_olsphp
      ;;
    php|php-fpm|nginx|apache)
      . "$(dirname "${BASH_SOURCE[0]}")/php_helpers.sh"
      stop_php
      ;;
    *)
      color_echo red "$(tr_lang php_type_unknown): $php_type";;
  esac
}

# Status serviciu PHP/lsphp
status_php_stack_unified() {
  local php_type="$1"
  case "$php_type" in
    lsphp|olsphp|openlitespeed)
      . "$(dirname "${BASH_SOURCE[0]}")/olsphp_helpers.sh"
      status_olsphp
      ;;
    php|php-fpm|nginx|apache)
      . "$(dirname "${BASH_SOURCE[0]}")/php_helpers.sh"
      status_php
      ;;
    *)
      color_echo red "$(tr_lang php_type_unknown): $php_type";;
  esac
}

# Versiune PHP/lsphp
version_php_stack_unified() {
  local php_type="$1"
  case "$php_type" in
    lsphp|olsphp|openlitespeed)
      . "$(dirname "${BASH_SOURCE[0]}")/olsphp_helpers.sh"
      olsphp_version
      ;;
    php|php-fpm|nginx|apache)
      . "$(dirname "${BASH_SOURCE[0]}")/php_helpers.sh"
      php_version
      ;;
    *)
      color_echo red "$(tr_lang php_type_unknown): $php_type";;
  esac
}
