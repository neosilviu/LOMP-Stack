#!/bin/bash
#
# cleanup.sh - Part of LOMP Stack v3.0
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

# cleanup.sh - Curățare rapidă a sistemului pentru WordPress LOMP Stack
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers/utils/lang.sh"
. "$SCRIPT_DIR/helpers/utils/functions.sh"


# Confirmare acțiune (siguranță)
confirm_action "$(tr_lang clean_confirm)" || { color_echo yellow "$(tr_lang exit)"; exit 0; }

# Oprire și dezactivare servicii principale
for svc in openlitespeed nginx apache2 mariadb mysql redis-server redis netdata fail2ban; do
  sudo systemctl stop "$svc" --no-block --timeout=10 2>/dev/null || true
  sudo systemctl disable "$svc" 2>/dev/null || true
done

# Ștergere pachete principale și fișiere asociate
export DEBIAN_FRONTEND=noninteractive
for v in 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9 10.10 10.11 11.0 11.1 11.2; do
  sudo debconf-set-selections <<< "mariadb-server-$v mysql-server/remove-data-dir boolean true"
  sudo debconf-set-selections <<< "mysql-server-$v mysql-server/remove-data-dir boolean true"
done
sudo debconf-set-selections <<< "mariadb-server mysql-server/remove-data-dir boolean true"
sudo debconf-set-selections <<< "mysql-server mysql-server/remove-data-dir boolean true"
sudo apt purge -y openlitespeed nginx nginx-light apache2 mariadb-server mysql-server redis-server redis netdata fail2ban php* lsphp* ufw rclone nodejs git phpmyadmin mc htop ncdu zip unzip curl wget jq build-essential libxml2-dev libsqlite3-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev libzip-dev libonig-dev libssl-dev pkg-config bison re2c autoconf
sudo rm -rf /var/lib/mysql /etc/mysql /etc/mysql* /var/log/mysql /var/log/mariadb /var/lib/mariadb /etc/my.cnf /etc/my.cnf.d /var/run/mysqld
sudo apt autoremove -y
sudo apt autoclean -y
unset DEBIAN_FRONTEND


# Ștergere resurse și fișiere Stack (complet, inclusiv toate directoarele și fișierele relevante)
sudo rm -rf \
  /var/www/html /var/www/wordpress /var/www/* /srv/www/* /home/*/www/* /home/*/public_html \
  /usr/local/lsws /usr/local/lsws/* /usr/local/lsws/conf/vhosts/* /usr/local/lsws/logs/* /usr/local/lsws/cachedata /usr/local/lsws/autoupdate /usr/local/lsws/cgid /usr/local/lsws/admin/tmp /usr/local/lsws/admin/logs /usr/local/lsws/admin/conf /usr/local/lsws/Example/logs \
  /etc/nginx /etc/nginx/sites-available/* /etc/nginx/sites-enabled/* \
  /etc/apache2 /etc/apache2/sites-available/* /etc/apache2/sites-enabled/* \
  /etc/mysql /etc/mysql* /var/lib/mysql /var/lib/mariadb /etc/my.cnf /etc/my.cnf.d /var/run/mysqld \
  /etc/redis /var/lib/redis /var/run/redis /var/log/redis \
  /etc/cloudflared /root/.cloudflared \
  /etc/stack_installer_user.conf /etc/php* /etc/php /etc/letsencrypt /etc/ssl/private /etc/ssl/certs /etc/ssl /etc/ssl/* \
  /etc/systemd/system/openlitespeed* /etc/systemd/system/nginx* /etc/systemd/system/apache2* /etc/systemd/system/redis* /etc/systemd/system/mariadb* /etc/systemd/system/mysql* /etc/systemd/system/netdata* /etc/systemd/system/fail2ban* /etc/systemd/system/php* \
  /etc/cron.d/*wp* /etc/cron.d/*stack* \
  /usr/local/bin/wp /usr/bin/wp /usr/sbin/openlitespeed /usr/sbin/nginx /usr/sbin/apache2 /usr/sbin/redis-server /usr/sbin/mysqld /usr/sbin/mariadbd \
  /var/lib/php /var/log/nginx /var/log/apache2 /var/log/lsws /var/log/mysql /var/log/mariadb /var/log/netdata /var/log/fail2ban /var/log/php* \
  /home/*/.wp-cli /home/*/.stack* /root/.wp-cli /root/.stack* /tmp/stack_installer.log /tmp/wordpress.zip /tmp/wordpress /tmp/wp_test_dir


# Curățare forțată a directoarelor rămase după dpkg (chiar dacă nu sunt goale)
for dir in \
  /usr/local/lsws \
  /etc/php \
  /var/www \
  /etc/redis \
  /usr/local/lsws \
  /var/lib/redis \
; do
  if [ -d "$dir" ]; then
    sudo rm -rf "$dir"
    echo "[CLEANUP] Șters forțat: $dir"
  fi
done

# Șterge recursiv subfolderele lsphp* din /usr/local dacă nu mai există fișiere utile
if [ -d /usr/local ]; then
  for d in /usr/local/lsphp*; do
    if [ -d "$d" ]; then
      echo "[CLEANUP] Șterg $d ..."
      sudo rm -rf "$d"
    fi
  done
fi

# Oferă posibilitatea de a șterge useri din /home (exclus root și utilizatori de sistem)
echo "\n===== Utilizatori existenți în /home ====="
user_list=()
for d in /home/*; do
  u=$(basename "$d")
  # Exclude utilizatori de sistem și userul 'wp' (poți extinde lista după nevoie)
  if [[ "$u" != "root" && "$u" != "admin" ]]; then
    user_list+=("$u")
    echo " - $u"
  fi
done

if [ ${#user_list[@]} -gt 0 ]; then
  echo
  color_echo yellow "Poți introduce mai multe nume de useri separați prin spațiu (sau Enter pentru a nu șterge nimic):"
  read -p "Introdu userii de șters: " DELUSERS
  # Afișează userii de șters cu roșu, dacă există
  if [[ -n "$DELUSERS" ]]; then
    color_echo red "Useri de șters: $DELUSERS"
  fi
  deleted_any=0
  # Filtrare useri validați
  valid_users=()
  for DELUSER in $DELUSERS; do
    if [[ " ${user_list[*]} " == *" $DELUSER "* ]]; then
      valid_users+=("$DELUSER")
    else
      color_echo yellow "Userul $DELUSER nu există sau nu este eligibil."
    fi
  done
  if [ ${#valid_users[@]} -gt 0 ]; then
    # Confirmarea pe aceeași linie, cu întrebare galbenă
    echo -n -e "\033[1;33mEști sigur că vrei să ștergi toți acești utilizatori: "
    echo -n -e "\033[1;31m${valid_users[*]}\033[1;33m ? (y/n): \033[0m"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      for DELUSER in "${valid_users[@]}"; do
        if sudo deluser --remove-home "$DELUSER"; then
          color_echo yellow "Utilizatorul $DELUSER a fost șters."
          deleted_any=1
        else
          color_echo red "Eroare: Utilizatorul $DELUSER nu a putut fi șters sau nu există."
        fi
      done
    else
      color_echo yellow "Nu s-a șters niciun utilizator. (Anulat de utilizator)"
    fi
  else
    color_echo yellow "Nu există useri validați pentru ștergere."
  fi
  if [ $deleted_any -eq 0 ]; then
    color_echo yellow "Nu s-a șters niciun utilizator."
  fi
else
  color_echo yellow "Nu există useri custom în /home."
fi

color_echo green "[DONE] $(tr_lang clean_done)"
