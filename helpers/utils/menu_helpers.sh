#!/bin/bash
#
# menu_helpers.sh - Helper optimizat pentru meniuri multi-limbă și funcții utilitare
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/author_info.sh"
. "$SCRIPT_DIR/lang.sh"
. "$SCRIPT_DIR/functions.sh"

# Asigură rularea în Bash
if [ -z "$BASH_VERSION" ]; then
  echo "[EROARE] Rulează scriptul din Bash, nu PowerShell/CMD!" >&2
  exit 1
fi

# Limbile disponibile pentru meniu
LANGS=("ro" "en" "es" "fr" "de")
FLAGS=("🇷🇴" "🇬🇧" "🇪🇸" "🇫🇷" "🇩🇪")
NAMES=("Română" "English" "Español" "Français" "Deutsch")

select_language() {
  color_echo magenta "\n╔════════════════════════════════════════════════════════════════════════════════════╗"
  color_echo magenta "║         LIMBĂ / LANGUAGE / IDIOMA / LANGUE / SPRACHE         ║"
  color_echo magenta "╚════════════════════════════════════════════════════════════════════════════════════╝"
  color_echo cyan "Alege limba:"
  for i in "${!LANGS[@]}"; do
    color_echo yellow " $((i+1)). ${FLAGS[$i]}  | ${NAMES[$i]}"
  done
  local sel
  read -p "Introdu numărul opțiunii (1-5): " sel
  LANG_OPT="${LANGS[$((sel-1))]:-ro}"
  export LANG_OPT
  sleep 1
}

get_prompt() {
  # Prompt multi-limbă compact
  local menu_type="$1" range label
  case "$menu_type" in
    install) range="0-8";;
    web|db) range="0-3";;
    *) range="";;
  esac
  case "$LANG_OPT" in
    en) label="Choose option";;
    es) label="Elija una opción";;
    fr) label="Choisissez une option";;
    de) label="Option wählen";;
    *)  label="Alege opțiunea";;
  esac
  printf "\033[1;36m%s%s: \033[0m" "$label" "${range:+ ($range)}"
}

main_menu_prompt() {
  color_echo magenta "\n\033[1;35m╔════════════════════════════════════════════════════════════════════════════════════╗\033[0m"
  color_echo magenta "\033[1;35m║   🚀 $(tr_lang mode_title) - WordPress LOMP Stack   ║\033[0m"
  color_echo magenta "\033[1;35m╚════════════════════════════════════════════════════════════════════════════════════╝\033[0m"
  color_echo cyan   "\n$(tr_lang select_mode)"
  color_echo green   "  1. 🚀  | $(tr_lang opt1)"
  color_echo cyan    "  2. ⚡  | $(tr_lang opt2)"
  color_echo magenta "  3. ⚙️   | $(tr_lang opt3)"
  color_echo blue    "  4. 📝  | $(tr_lang opt4)"
  color_echo yellow  "  5. ➕  | $(tr_lang add_user_domain)"
  color_echo blue    "  6. 💾  | $(tr_lang backup_manager_title)"
  color_echo magenta "  7. ⬆️   | $(tr_lang update_all)"
  color_echo yellow  "  8. 🧹  | $(tr_lang clean)"
  color_echo red     "  0. ❌  | $(tr_lang opt5)"
  color_echo none    "\033[1;30m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m"
  echo
  local prompt
  prompt="$(get_prompt install)"
  read -p "$prompt" mode_sel
  REPLY="$(echo "$mode_sel" | tr -d '[:space:]')"
}

confirm_action() {
  # Confirmă o acțiune cu (y/n) pe aceeași linie, fără newline
  echo -ne "\033[1;33m[?]\033[0m $1 [y/N]: "
  read -r confirm
  [[ "$confirm" =~ ^[Yy]$ ]]
}

select_webserver() {
  # Meniu pentru alegerea webserverului
  while true; do
    color_echo cyan "\n$(tr_lang web)"
    color_echo yellow " 1. 🚀  | $(tr_lang web1)"
    color_echo cyan   " 2. ⚡  | $(tr_lang web2)"
    color_echo magenta " 3. 🛠️   | $(tr_lang web3)"
    color_echo red   " 0. 🔙  | $(tr_lang back)"
    sleep 0.1
    local prompt
    prompt="$(get_prompt web)"
    read -p "$prompt" ws_sel
    case $ws_sel in
      0) return 1;;
      1) color_echo green "\n$(tr_lang ws_ols_selected)"; return 0;;
      2) color_echo green "\n$(tr_lang ws_nginx_selected)"; return 0;;
      3) color_echo green "\n$(tr_lang ws_apache_selected)"; return 0;;
      *) color_echo red "$(tr_lang invalid_option)";;
    esac
  done
}

# Importă helperul pentru baze de date pentru a permite selectarea bazei de date
. "$SCRIPT_DIR/../db/db_helpers.sh"
. "$SCRIPT_DIR/../web/php_actions.sh"

# Eliminat orice apel accidental la prompt_external_db_details sau cod executabil la încărcare

show_versions_menu() {
  color_echo magenta "\n╔════════════════════════════════════════════════════════════════════════════════════╗"
  color_echo magenta   "║           🔍  Main component version check                           ║"
  color_echo magenta   "╚════════════════════════════════════════════════════════════════════════════════════╝"
  color_echo yellow    " 1. PHP"
  color_echo yellow    " 2. OLS PHP (lsphp)"
  color_echo yellow    " 3. MariaDB"
  color_echo yellow    " 4. MySQL"
  color_echo yellow    " 5. WP-CLI"
  color_echo yellow    " 6. WordPress"
  color_echo red       " 0. Back"
  color_echo none      "────────────────────────────────────────────────────────────────────────────────────"
  read -p "Select component to check version [0-6]: " ver_sel
  case $ver_sel in
    1) . "$SCRIPT_DIR/php_helpers.sh"; php_version; read -p "$(tr_lang press_enter)";;
    2) . "$SCRIPT_DIR/olsphp_helpers.sh"; olsphp_version; read -p "$(tr_lang press_enter)";;
    3) . "$SCRIPT_DIR/db_mariadb.sh"; mariadb_version; read -p "$(tr_lang press_enter)";;
    4) . "$SCRIPT_DIR/db_mysql.sh"; mysql_version; read -p "$(tr_lang press_enter)";;
    5) . "$SCRIPT_DIR/wpcli_helpers.sh"; wp --version; read -p "$(tr_lang press_enter)";;
    6) . "$SCRIPT_DIR/wp_helpers.sh"; wp_version; read -p "$(tr_lang press_enter)";;
    0|*) return 0;;
  esac
}

# Importă meniul modular PHP/lsphp
. "$SCRIPT_DIR/../web/php_packages_menu.sh"
# Importă funcțiile pentru instalare/eliminare pachete PHP/lsphp
. "$SCRIPT_DIR/../web/php_actions.sh"

