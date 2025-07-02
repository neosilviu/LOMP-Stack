#!/bin/bash
#
# user_input_helpers.sh - Part of LOMP Stack v3.0
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
# user_input_helpers.sh - Funcții pentru validare și confirmare input user/domeniu

validate_user_domain_input() {
  local domain username domain_dir confirm

  # Prompt pentru domeniu cu validare strictă
  while true; do
    echo -ne "\n\033[1;36mIntrodu domeniu (ex: exemplu.com):\033[0m"
    read -r domain
    domain="$(echo "$domain" | xargs)"
    if [[ -z "$domain" || ! "$domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
      echo -e "\033[1;31m[EROARE]\033[0m Domeniu invalid! Folosește doar litere, cifre, '-', '.' (fără spații)"
    else
      break
    fi
  done

  domain_dir="${domain%%.*}"

  # Prompt pentru user cu fallback la default
  echo -ne "\033[1;36mIntrodu nume user (Enter pentru default: $domain_dir):\033[0m"
  read -r username
  username="$(echo "$username" | xargs)"
  if [[ -z "$username" ]]; then
    username="$domain_dir"
  fi

  # Rezumat și confirmare
  echo -e "\n------------------------------"
  echo -e "Domeniu: \033[1;32m$domain\033[0m"
  echo -e "User:    \033[1;32m$username\033[0m"
  echo -e "------------------------------\n"

  while true; do
    echo -ne "Confirmi? ([Y]/n): "
    read -r confirm
    if [[ -z "$confirm" || "$confirm" =~ ^[yY]$ ]]; then
      echo -e "\n\033[1;32m[OK]\033[0m Datele au fost confirmate. Se continuă cu instalarea pentru domeniu: $domain și user: $username.\n"
      break
    elif [[ "$confirm" =~ ^[nN]$ ]]; then
      echo -e "\033[1;33m[INFO]\033[0m Operațiune anulată de utilizator. Revenire la completare domeniu și user."
      return 1
    else
      echo -e "Te rog răspunde cu 'y' pentru DA sau 'n' pentru NU (Enter = DA implicit)."
    fi
  done

  export STACK_DOMAIN="$domain"
  export STACK_USERNAME="$username"
}
