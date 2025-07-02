#!/bin/bash
#
# add_user_domain.sh - Part of LOMP Stack v3.0
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
# add_user_domain.sh - Adaugă user și domeniu nou, complet izolat (Nginx+PHP)
# --- Folosește funcții din user_domain_helpers.sh pentru toate operațiile izolate ---

# Helper pentru sourcing robust din ../utils sau ../security
source_stack_helper() {
  local relpath="$1"
  local basedir
  basedir="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  local fullpath="$basedir/$relpath"
  # Normalize path (elimină ../ și ./)
  fullpath="$(readlink -f "$fullpath" 2>/dev/null || realpath "$fullpath" 2>/dev/null || echo "$fullpath")"
  if [ -f "$fullpath" ]; then
    # shellcheck source=/dev/null
    source "$fullpath"
    return 0
  else
    echo "[WARN] Nu găsesc $relpath ($fullpath)!" >&2
    return 1
  fi
}

# Importă funcțiile principale
source_stack_helper "user_domain_helpers.sh" || exit 1

# Check for mysql dependency
if ! command -v mysql >/dev/null 2>&1; then
  echo "[EROARE] Comanda 'mysql' nu este instalată sau nu este în PATH! Instalează MariaDB/MySQL și reîncearcă." >&2
  exit 1
fi

# 2. Creează userul UNIX dacă nu există
create_stack_unix_user() {
  local username="$1"
  if [[ -z "$username" ]]; then
    echo "[EROARE] Username-ul nu a fost setat corect! Ieșire."
    exit 1
  fi
  if ! id "$username" &>/dev/null; then
    color_echo cyan "[INFO] Creez userul UNIX '$username'..."
    sudo useradd -m -s /bin/bash -g www-data "$username"
    # Prompt pentru parolă la creare user
    while true; do
      read -s -p "Setează parola pentru userul $username: " user_pass1; echo
      read -s -p "Confirmă parola pentru userul $username: " user_pass2; echo
      if [[ "$user_pass1" != "$user_pass2" ]]; then
        echo "[EROARE] Parolele nu coincid. Încearcă din nou."
      elif [[ -z "$user_pass1" ]]; then
        echo "[EROARE] Parola nu poate fi goală. Încearcă din nou."
      else
        echo "$username:$user_pass1" | sudo chpasswd
        break
      fi
    done
    sudo passwd -e "$username" # Forțează schimbarea parolei la primul login dacă vrei
  else
    color_echo cyan "[INFO] Userul UNIX '$username' există deja."
  fi
}

# 3. Creează foldere, backup, permisiuni
setup_user_dirs_and_backup() {
  local username="$1"
  user_logs_dir="/home/$username/logs"
  user_config_dir="/home/$username/config"
  sudo mkdir -p "$user_logs_dir" "$user_config_dir"
  sudo chown -R "$username":www-data "$user_logs_dir" "$user_config_dir"
  sudo chmod 750 "$user_logs_dir" "$user_config_dir"
  if type create_user_backup_dir &>/dev/null; then
    create_user_backup_dir "$username"
  else
    echo "[WARN] Funcția create_user_backup_dir nu este disponibilă."
  fi
}

# 4. Config, notificări, backup scripts
setup_user_config_and_notify() {
  local username="$1"
  local domain="$2"
  local user_config_dir="$3"
  if source_stack_helper "../utils/backup_helpers.sh"; then
    generate_user_backup_scripts "$username" "$domain" "$user_config_dir"
  else
    echo "[WARN] Nu găsesc backup_helpers.sh! Scripturile de backup nu vor fi generate."
  fi
  if source_stack_helper "../utils/notify_helpers.sh"; then
    notify_backup_mail "$username" "$domain"
  fi
  if source_stack_helper "../utils/config_helpers.sh"; then
    copy_user_config_files "$username" "$user_config_dir"
  else
    echo "[WARN] Nu găsesc config_helpers.sh! Nu se copiază fișiere de config."
  fi
}

# 5. Cloudflare flow
# (eliminat, se face doar din platform_steps.sh)

# 6. Webroot, vhost, db, wp-config
setup_stack_resources() {
  local username="$1"
  local domain="$2"
  webroot="/home/$username/$domain"
  dbname="${username}_${domain}_db"
  dbuser="${username}_${domain}_user"
  dbpass=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
  redisdb=$(id -u "$username")
  export STACK_DOMAIN="$domain"
  export STACK_USERNAME="$username"
  export STACK_WEBROOT="$webroot"
  # Scrie variabilele și în env temporar imediat după setare, pentru health-check robust
  echo "STACK_DOMAIN=$domain" > /tmp/stack_user_env
  echo "STACK_USERNAME=$username" >> /tmp/stack_user_env
  echo "STACK_WEBROOT=$webroot" >> /tmp/stack_user_env

  exec 3>>/var/log/stack_user_domain.log
  echo "[START] $(date) - user=$username, domain=$domain" >&3

  if ! id "$username" &>/dev/null; then
    create_isolated_user "$username" && echo "[OK] User creat: $username" >&3
  else
    color_echo cyan "[INFO] Userul $username există deja, se va adăuga doar domeniul."
  fi
  create_isolated_webroot "$username" "$webroot" && echo "[OK] Webroot creat: $webroot" >&3
  if [ -d /usr/local/lsws ]; then
    create_ols_vhost "$username" "$domain" "$webroot" && echo "[OK] Vhost OLS creat pentru $domain ($webroot)" >&3
  fi
  if ! command -v mysql >/dev/null 2>&1; then
    echo "[EROARE] Comanda 'mysql' nu este instalată sau nu este în PATH! Instalează MariaDB/MySQL și reîncearcă." >&2
    return 1
  fi
  create_isolated_db "$dbname" "$dbuser" "$dbpass" && echo "[OK] DB MySQL/MariaDB creată: $dbname, user: $dbuser" >&3
  
  # Instalează WordPress complet (fișiere + wp-config.php + DB) folosind funcția centralizată
  if source_stack_helper "../wp/wp_helpers.sh"; then
    wp_install_if_needed "$webroot" "$domain" "$username" "$dbname" "$dbuser" "$dbpass" "localhost"
  else
    color_echo red "[EROARE] Nu pot sursa wp_helpers.sh! WordPress NU a fost instalat automat."
  fi
}

# 7. SSL
setup_ssl_if_needed() {
  local domain="$1"
  local webroot="$2"
  if [[ "$STACK_CF_TUNNEL" != "1" ]]; then
    if source_stack_helper "../utils/ssl_helpers.sh"; then
      color_echo cyan "[INFO] Încerc generare certificat SSL Let's Encrypt pentru $domain..." | tee -a /var/log/stack_user_domain.log
      generate_ssl_certificate "$domain" "$webroot"
    else
      echo "[WARN] Nu găsesc ssl_helpers.sh! Certificatul SSL nu va fi generat automat."
    fi
  else
    color_echo cyan "[INFO] Tunel Cloudflare activ - se folosește tunelul, nu se generează certificat SSL Let's Encrypt."
  fi
}

# 8. Raport final
show_stack_report() {
  local domain="$1"
  local username="$2"
  local webroot="$3"
  local dbname="$4"
  local dbuser="$5"
  local dbpass="$6"
  local redisdb="$7"
  local user_logs_dir="$8"
  local user_config_dir="$9"
  if source_stack_helper "../utils/report_helpers.sh"; then
    report_stack_install_summary "$domain" "$username" "$webroot" "$dbname" "$dbuser" "$dbpass" "$redisdb" "$user_logs_dir" "$user_config_dir"
    export_stack_env_vars "$domain" "$username" "$webroot"
  else
    echo "\n================ RAPORT FINAL INSTALARE STACK ================"
    echo "User și domeniu: $domain ($username) create și izolate cu succes!"
    echo "Webroot: $webroot"
    echo "Baza de date MySQL: $dbname"
    echo "User DB: $dbuser"
    echo "Parolă DB: $dbpass"
    echo "Redis DB index (pt. config): $redisdb"
    echo "Redis status: $(systemctl is-active redis-server 2>/dev/null || echo 'necunoscut')"
    echo "Loguri user: $user_logs_dir"
    echo "Config user: $user_config_dir"
    # Afișează parola admin OLS dacă există info
    if [ -f /etc/ols_admin_info ]; then
      . /etc/ols_admin_info
      echo "OpenLiteSpeed admin user: $OLS_ADMIN_USER"
      echo "OpenLiteSpeed admin pass: $OLS_ADMIN_PASS"
      echo "(Acces: https://<server>:7080  - schimbă parola după prima logare!)"
    fi
    if [ -f "$user_config_dir/cloudflare_config.yml" ]; then
      echo "Cloudflare config: $user_config_dir/cloudflare_config.yml (copiat automat)"
    fi
    if [[ "$STACK_CF_TUNNEL" == "1" ]]; then
      echo "Tunel Cloudflare: ACTIV (toate conexiunile trec prin tunel, porturi 80/443 blocate extern)"
    else
      echo "Tunel Cloudflare: INACTIV (SSL Let's Encrypt folosit dacă e posibil)"
    fi
    if [ -f /etc/letsencrypt/live/$domain/fullchain.pem ]; then
      echo "Certificat SSL Let's Encrypt: ACTIV pentru $domain"
    else
      echo "Certificat SSL Let's Encrypt: INACTIV pentru $domain"
    fi
    echo "Vhost webserver: configurat pentru $domain (Nginx/Apache/OLS)"
    echo "WordPress: instalat în $webroot, cu siteurl/home/blogname setate la $domain"
    echo "Admin email WordPress: admin@$domain"
    echo "============================================================="
    echo "STACK_DOMAIN=$domain" > /tmp/stack_user_env
    echo "STACK_USERNAME=$username" >> /tmp/stack_user_env
    echo "STACK_WEBROOT=$webroot" >> /tmp/stack_user_env
  fi
}

# Funcția principală refactorizată
add_user_and_domain() {
  local domain="$1"
  local username="$2"
  if [[ -z "$domain" || -z "$username" ]]; then
    if source_stack_helper "../utils/user_input_helpers.sh"; then
      validate_user_domain_input
      domain="$STACK_DOMAIN"
      username="$STACK_USERNAME"
    else
      echo "[EROARE] Nu găsesc user_input_helpers.sh! Inputul nu poate fi validat."
      exit 1
    fi
  fi
  # Confirmarea se face doar în helperul de input, nu mai cerem încă o dată aici
  create_stack_unix_user "$username"
  setup_user_dirs_and_backup "$username"
  setup_user_config_and_notify "$username" "$domain" "/home/$username/config"
  # Cloudflare: confirmare și instalare tunel dacă e selectat
  if source_stack_helper "../security/cloudflare_helpers.sh"; then
#echo "[DEBUG] Ajuns la confirmare tunel Cloudflare pentru $domain (interactiv: $- / tty: $(test -t 0 && echo da || echo nu))" >&2
    confirm_cloudflare_tunnel "$domain"
  fi
  if [[ "$STACK_CF_TUNNEL" == "1" ]]; then
    if source_stack_helper "../security/install_cloudflare.sh"; then
      install_cloudflare_tunnel_if_confirmed "$username" "$domain"
    fi
  else
    color_echo cyan "[INFO] Tunel Cloudflare nu a fost selectat, se va încerca SSL Let's Encrypt."
  fi

  # Mută generarea certificatului Let's Encrypt imediat după Cloudflare
  local confirm_ssl
  read -p "Dorești să generezi certificat SSL Let's Encrypt pentru domeniul $domain? [y/N]: " confirm_ssl
  if [[ "$confirm_ssl" =~ ^[Yy]$ ]]; then
    setup_ssl_if_needed "$domain" "/home/$username/${domain%%.*}"
  else
    color_echo yellow "[INFO] Ai ales să NU generezi certificat SSL Let's Encrypt pentru $domain. Toate operațiile legate de SSL și dependințele acestuia vor fi sărite complet. Poți genera certificatul și configura SSL ulterior."
  fi

  setup_stack_resources "$username" "$domain"

  # Configurare vhost și optimizare ini după user/domain pentru toate webserverele
  local ws_sel
  ws_sel="${STACK_WEBSERVER:-ols}"
  if [[ "$ws_sel" == "ols" ]]; then
    source_stack_helper "../web/ols_helpers.sh"
    source_stack_helper "../web/olsphp_helpers.sh"
    configure_ols_vhost_wordpress "$username" "$domain"
    optimize_lsphp_ini_wordpress "$username" "$domain"
  elif [[ "$ws_sel" == "nginx" ]]; then
    source_stack_helper "../web/web_nginx.sh"
    configure_nginx_wordpress_stack "$username" "$domain"
  elif [[ "$ws_sel" == "apache" ]]; then
    source_stack_helper "../web/web_apache.sh"
    configure_apache_wordpress_stack "$username" "$domain"
  fi
  show_stack_report "$domain" "$username" "/home/$username/$domain" "${username}_${domain}_db" "${username}_${domain}_user" "(parola ascunsă)" "$(id -u "$username")" "/home/$username/logs" "/home/$username/config"

  # Instalare WordPress izolată automat după adăugare user/domain
  if source_stack_helper "../wp/wp_helpers.sh"; then
    color_echo cyan "[INFO] Instalez WordPress izolat în /home/$username/$domain..."
    install_wordpress_latest
    color_echo cyan "[INFO] Instalarea WordPress pentru $domain ($username) a fost finalizată."
  else
    color_echo red "[EROARE] Nu pot sursa wp_helpers.sh! WordPress NU a fost instalat automat."
  fi
}