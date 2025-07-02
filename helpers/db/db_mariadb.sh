# shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$SCRIPT_DIR/../utils/functions.sh"

# Instalează MariaDB ultima stabilă
install_mariadb_latest() {
  local msg
  msg="[DB] Instalare MariaDB..."
  color_echo yellow "$msg"
  log_info "$msg"
  if ! sudo apt install -y mariadb-server; then
    log_error "MariaDB install failed"; return 1
  fi
}

# Securizează MariaDB pentru WordPress
secure_mariadb_wordpress() {
  # Detectează versiunea MariaDB
  local MARIADB_VERSION
  MARIADB_VERSION=$(mysql -V | grep -oE 'Distrib ([0-9]+\.[0-9]+)' | awk '{print $2}')
  color_echo cyan "[DEBUG] MariaDB version detected: $MARIADB_VERSION"
  local msg
  msg="[DB] Securizare MariaDB..."
  color_echo yellow "$msg"
  log_info "$msg"
  local ROOT_PASS="${MYSQL_PASS:-}"
  local ESCAPED_PASS
  local secrets_file="/root/.stack_mariadb_root_pass"
  # 1. Încearcă autentificare root fără parolă (unix_socket)
  if sudo mysql -u root -e "SELECT 1;" 2>/dev/null; then
    color_echo yellow "[DB] root@localhost folosește unix_socket (fără parolă). Se va seta o parolă random și pluginul corect."
    ROOT_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
    ESCAPED_PASS=$(printf "%s" "$ROOT_PASS" | sed "s/'/''/g")
    # Fallback pentru versiuni vechi (<10.2)
    if awk -v v="$MARIADB_VERSION" 'BEGIN{exit (v<10.2)?0:1}'; then
      if ! sudo mysql -u root -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$ESCAPED_PASS');" 2>/tmp/mariadb_setpass.log; then
        color_echo red "[FATAL] Nu pot seta parola root (fallback vechi)! Output debug:"
        cat /tmp/mariadb_setpass.log
        color_echo red "Exemplu: sudo mysql -u root -e \"SET PASSWORD FOR 'root'@'localhost' = PASSWORD('parola_noua');\""
        return 1
      fi
    else
      # Pentru >=10.2, folosește sintaxa modernă
      if ! sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ESCAPED_PASS';" 2>/tmp/mariadb_setpass.log; then
        color_echo red "[FATAL] Nu pot seta parola root pentru MariaDB! Output debug:"
        cat /tmp/mariadb_setpass.log
        color_echo red "Exemplu: sudo mysql -u root -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY 'parola_noua';\""
        return 1
      fi
    fi
    # Afișează pluginul actual root pentru debug
    sudo mysql -u root -e "SELECT User,Host,plugin FROM mysql.user WHERE User='root';"
    color_echo yellow "[DB] Parolă root setată: $ROOT_PASS"
  # 2. Dacă nu merge unix_socket, încearcă cu parola existentă
  elif [[ -n "$ROOT_PASS" ]]; then
    ESCAPED_PASS=$(printf "%s" "$ROOT_PASS" | sed "s/'/''/g")
    if ! sudo mysql -u root -p"$ROOT_PASS" -e "SELECT 1;" 2>/tmp/mariadb_auth.log; then
      color_echo red "[FATAL] Nu pot autentifica root nici cu parola specificată! Output debug:"
      cat /tmp/mariadb_auth.log
      return 1
    fi
    # Fallback pentru versiuni vechi (<10.2)
    if awk -v v="$MARIADB_VERSION" 'BEGIN{exit (v<10.2)?0:1}'; then
      if ! sudo mysql -u root -p"$ROOT_PASS" -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$ESCAPED_PASS');" 2>/tmp/mariadb_setpass.log; then
        color_echo red "[FATAL] Nu pot seta parola root cu parola dată (fallback vechi)! Output debug:"
        cat /tmp/mariadb_setpass.log
        return 1
      fi
    else
      if ! sudo mysql -u root -p"$ROOT_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ESCAPED_PASS';" 2>/tmp/mariadb_setpass.log; then
        color_echo red "[FATAL] Nu pot seta parola root cu parola dată! Output debug:"
        cat /tmp/mariadb_setpass.log
        return 1
      fi
    fi
    sudo mysql -u root -p"$ROOT_PASS" -e "SELECT User,Host,plugin FROM mysql.user WHERE User='root';"
    # Detectează și schimbă pluginul dacă nu e corect (ex: unix_socket)
    local plugin
    plugin=$(sudo mysql -u root -p"$ROOT_PASS" -N -e "SELECT plugin FROM mysql.user WHERE User='root' AND Host='localhost';")
    if [[ "$plugin" != "mysql_native_password" && "$plugin" != "" ]]; then
      color_echo yellow "[WARN] Pluginul root este '$plugin', încerc să-l schimb la 'mysql_native_password' (dacă e suportat)."
      sudo mysql -u root -p"$ROOT_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('$ESCAPED_PASS');" 2>/tmp/mariadb_plugin.log || true
      sudo mysql -u root -p"$ROOT_PASS" -e "SELECT User,Host,plugin FROM mysql.user WHERE User='root';"
    fi
  else
    log_error "[FATAL] Nu pot autentifica root nici cu unix_socket, nici cu parolă. MariaDB nu poate fi securizat automat."
    return 1
  fi
  # Operațiuni de securizare (acum cu root autentificat)
  for q in \
    "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" \
    "DELETE FROM mysql.user WHERE User=''" \
    "DROP DATABASE IF EXISTS test" \
    "FLUSH PRIVILEGES"
  do
    if ! sudo mysql -u root -p"$ROOT_PASS" -e "$q" 2>/tmp/mariadb_sec.log; then
      color_echo red "[FATAL] Eroare la: $q"
      cat /tmp/mariadb_sec.log
      return 1
    fi
  done
  # Salvează parola root într-un fișier securizat pentru integrare cu WordPress
  echo "$ROOT_PASS" | sudo tee "$secrets_file" >/dev/null
  sudo chmod 600 "$secrets_file"
  color_echo green "[DB] Parola root MariaDB a fost salvată în $secrets_file (doar root are acces)."
  # Health-check MariaDB la finalul securizării
  check_mariadb_health || exit 2
}

# Health-check MariaDB după setarea parolei root
check_mariadb_health() {
  local root_pass_file="/root/.stack_mariadb_root_pass"
  local root_pass
  if [[ -f "$root_pass_file" ]]; then
    root_pass=$(<"$root_pass_file")
  else
    color_echo red "[EROARE] Nu există fișierul cu parola root MariaDB ($root_pass_file)!"; return 1
  fi
  # Testează autentificarea și listarea bazelor de date
  sudo mysql -u root -p"$root_pass" -e 'SHOW DATABASES;' 2>&1 | sudo tee /tmp/mariadb_health.log >/dev/null
  local status=$?
  if [[ $status -eq 0 ]]; then
    color_echo green "[OK] MariaDB funcționează corect cu root și parola setată."
    return 0
  else
    color_echo red "[FATAL] MariaDB nu este funcțional cu root și parola setată! Output debug:"
    cat /tmp/mariadb_health.log
    return 1
  fi
}