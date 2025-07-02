#!/bin/bash
#
# db_helpers.sh - Part of LOMP Stack v3.0
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
# db_helpers.sh - Funcții utilitare generale pentru gestionarea bazelor de date (MySQL/MariaDB)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$SCRIPT_DIR/../utils/functions.sh"

# Detectează tipul de server de baze de date instalat (MySQL/MariaDB)
detect_db_type() {
  if command -v mariadb >/dev/null 2>&1; then
    echo "mariadb"
  elif command -v mysql >/dev/null 2>&1; then
    echo "mysql"
  else
    echo "none"
  fi
}

# Permite alegerea tipului de conexiune: port sau socket
select_db_connection_type() {
  local type
  echo "Choose DB connection type:"
  echo "  1) TCP port (default)"
  echo "  2) Unix socket"
  read -rp "Select [1-2]: " type
  case "$type" in
    2)
      export DB_CONN_TYPE="socket"
      read -rp "Enter socket path [/var/run/mysqld/mysqld.sock]: " DB_SOCKET
      export DB_SOCKET="${DB_SOCKET:-/var/run/mysqld/mysqld.sock}"
      ;;
    *)
      export DB_CONN_TYPE="port"
      read -rp "Enter host [localhost]: " DB_HOST
      export DB_HOST="${DB_HOST:-localhost}"
      read -rp "Enter port [3306]: " DB_PORT
      export DB_PORT="${DB_PORT:-3306}"
      ;;
  esac
}

# Selectează și exportă variabilele pentru utilizator/parolă DB (din config sau interactiv)
select_db_credentials() {
  export MYSQL_USER="${MYSQL_USER:-root}"
  export MYSQL_PASS="${MYSQL_PASS:-}"
  if [[ -z "$MYSQL_PASS" ]]; then
    read -rsp "Enter DB password for $MYSQL_USER: " MYSQL_PASS
    export MYSQL_PASS
    echo
  fi
  select_db_connection_type
}

# Construiește argumentele de conexiune pentru mysql/mysqldump în funcție de tipul ales
get_db_conn_args() {
  if [[ "$DB_CONN_TYPE" == "socket" ]]; then
    echo "--socket=$DB_SOCKET"
  else
    echo "-h$DB_HOST -P$DB_PORT"
  fi
}

# Afișează versiunea serverului de baze de date
show_db_version() {
  local db_type
  db_type="$(detect_db_type)"
  if [[ "$db_type" == "mariadb" ]]; then
    mariadb --version
  elif [[ "$db_type" == "mysql" ]]; then
    mysql --version
  else
    echo "No MySQL/MariaDB server detected."
  fi
}

# Testează dacă serverul DB răspunde pe portul dat
check_db_port() {
  local host="${1:-localhost}"
  local port="${2:-3306}"
  (echo > /dev/tcp/$host/$port) >/dev/null 2>&1 && echo "open" || echo "closed"
}

# Health-check MariaDB instalare și configurare
check_mariadb_health() {
  local errors=0
  color_echo yellow "[DB] Verificare stare MariaDB..."
  if ! sudo systemctl is-active --quiet mariadb; then
    color_echo red "[EROARE] Serviciul MariaDB nu rulează!"; errors=1
  fi
  if ! sudo mariadb --version >/dev/null 2>&1; then
    color_echo red "[EROARE] Binarul mariadb nu este funcțional!"; errors=1
  fi
  if ! sudo mysqladmin ping >/dev/null 2>&1; then
    color_echo red "[EROARE] MariaDB nu răspunde la ping!"; errors=1
  fi
  if ! sudo mysql -e 'SHOW DATABASES;' >/dev/null 2>&1; then
    color_echo red "[EROARE] Nu se pot lista bazele de date cu root!"; errors=1
  fi
  if [[ $errors -eq 0 ]]; then
    color_echo green "[OK] MariaDB este instalat și configurat corect."
    return 0
  else
    color_echo red "[EROARE] MariaDB are probleme de instalare/configurare!"
    return 1
  fi
}

# Wrapper for platform_steps.sh compatibility
install_selected_db() {
  # Asigură sursarea funcțiilor din db_mariadb.sh
  . "$(dirname "${BASH_SOURCE[0]}")/db_mariadb.sh"
  install_mariadb_latest
  secure_mariadb_wordpress
}