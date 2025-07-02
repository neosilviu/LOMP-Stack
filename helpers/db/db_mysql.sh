#!/bin/bash
#
# db_mysql.sh - Part of LOMP Stack v3.0
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
# db_mysql.sh - Funcții pentru instalare și securizare MySQL
. "$(dirname "$0")/../utils/functions.sh"

# Instalează MySQL ultima stabilă
install_mysql_latest() {
  local msg
  msg="[DB] Instalare MySQL..."
  color_echo yellow "$msg"
  log_info "$msg"
  if ! sudo apt install -y mysql-server; then
    log_error "MySQL install failed"; return 1
  fi
}

# Securizează MySQL pentru WordPress
secure_mysql_wordpress() {
  local msg
  msg="[DB] Securizare MySQL..."
  color_echo yellow "$msg"
  log_info "$msg"
  # Setează parola root dacă nu există deja
  if ! sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';"; then log_error "Set root password failed"; return 1; fi
  # Asigură pluginul corect pentru root
  if ! sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"; then log_error "Set plugin failed"; return 1; fi
  # Șterge accesul root din alte locații
  if ! sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"; then log_error "Delete root hosts failed"; return 1; fi
  # Șterge useri anonimi
  if ! sudo mysql -e "DELETE FROM mysql.user WHERE User='';"; then log_error "Delete anonymous users failed"; return 1; fi
  # Șterge baza de date de test
  if ! sudo mysql -e "DROP DATABASE IF EXISTS test;"; then log_error "Drop test db failed"; return 1; fi
  # Aplică privilegiile
  if ! sudo mysql -e "FLUSH PRIVILEGES;"; then log_error "Flush privileges failed"; return 1; fi
}