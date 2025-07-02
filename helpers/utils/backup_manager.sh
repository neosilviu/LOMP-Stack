#!/bin/bash
#
# backup_manager.sh - Part of LOMP Stack v3.0
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
# backup_manager.sh - Sistem general de backup/restore cu failback, suport rclone, multi-lingual și scheduling (cron)

# Check for mysql dependency
if ! command -v mysql >/dev/null 2>&1; then
  fatal_error "Comanda 'mysql' nu este instalată sau nu este în PATH! Instalează MariaDB/MySQL și reîncearcă."
  exit 1
fi

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependency_manager.sh"
source "$SCRIPT_DIR/error_handler.sh"

# Initialize error handling
setup_error_handlers
DEBUG_MODE=true

# Load translation and lang helpers using dependency manager
source_stack_helper "lang"

BACKUP_ROOT="/var/backups/stack"
LOG_FILE="/var/log/stack_backup_manager.log"

# Helper: print translated message
msg() {
  tr_lang "$1"
}

# Helper: print and log
log_msg() {
  local m; m="$(msg "$1")"
  echo "$m" | tee -a "$LOG_FILE"
}

# Pre/post hook support
run_hook() {
  local hook_type="$1" username="$2" domain="$3"
  local hook_script="/etc/stack/hooks/${hook_type}_backup.sh"
  if [ -x "$hook_script" ]; then
    "$hook_script" "$username" "$domain"
  fi
}

BACKUP_ROOT="/var/backups/stack"
LOG_FILE="/var/log/stack_backup_manager.log"


# Backup complet pentru un user/domeniu cu hooks și checksum
backup_user_domain() {
  local username="$1" domain="$2" now
  now=$(date +%Y%m%d_%H%M%S)
  backup_dir="$BACKUP_ROOT/${username}_${domain}_$now"
  mkdir -p "$backup_dir"
  log_msg "backup_start"; echo "$username/$domain $now" | tee -a "$LOG_FILE"

  run_hook pre "$username" "$domain"

  local ok=1
  # 1. Fisiere web
  if [ -d "/home/$username/www/$domain" ]; then
    tar czf "$backup_dir/web.tar.gz" -C "/home/$username/www" "$domain" || ok=0
  fi
  # 2. Baza de date
  dbname="${username}_db"
  mysqldump "$dbname" > "$backup_dir/db.sql" 2>>"$LOG_FILE" || ok=0
  # 3. Config Nginx
  cp "/etc/nginx/sites-available/$domain" "$backup_dir/nginx.conf" 2>/dev/null || true
  # 4. Config OLS (dacă există)
  if [ -d "/usr/local/lsws/conf/vhosts/$domain" ]; then
    tar czf "$backup_dir/ols_vhost.tar.gz" -C "/usr/local/lsws/conf/vhosts" "$domain" || ok=0
  fi
  # 5. wp-config.php
  if [ -f "/home/$username/www/$domain/wp-config.php" ]; then
    cp "/home/$username/www/$domain/wp-config.php" "$backup_dir/" || ok=0
  fi

  # 6. Generează checksum
  (cd "$backup_dir" && sha256sum * > checksums.sha256 2>/dev/null)

  run_hook post "$username" "$domain"

  # Upload cloud dacă există rclone.conf
  if [ -f "/home/$username/config/rclone.conf" ]; then
    backup_with_rclone "$backup_dir" "remote:${username}_${domain}_$now" && log_msg "cloud_upload_done" || log_msg "cloud_upload_error"
  fi

  # Notificare avansată (mail + extensibil)
  send_notification "$username" "$domain" "$backup_dir" "$ok" "backup"

  if [ "$ok" = 1 ]; then
    log_msg "backup_done"
  else
    log_msg "backup_error"
  fi
}

# Backup incremental pentru un user/domeniu (doar fișiere modificate)
incremental_backup_user_domain() {
  local username="$1" domain="$2" now
  now=$(date +%Y%m%d_%H%M%S)
  backup_dir="$BACKUP_ROOT/${username}_${domain}_incremental_$now"
  mkdir -p "$backup_dir"
  log_msg "backup_incremental_start"; echo "$username/$domain $now" | tee -a "$LOG_FILE"

  run_hook pre "$username" "$domain"

  local ok=1
  # 1. Fisiere web incremental cu rsync
  if [ -d "/home/$username/www/$domain" ]; then
    rsync -a --delete --link-dest="$BACKUP_ROOT/latest_${username}_${domain}" "/home/$username/www/$domain/" "$backup_dir/web/" || ok=0
  fi
  # 2. Baza de date
  dbname="${username}_db"
  mysqldump "$dbname" > "$backup_dir/db.sql" 2>>"$LOG_FILE" || ok=0
  # 3. Config Nginx
  cp "/etc/nginx/sites-available/$domain" "$backup_dir/nginx.conf" 2>/dev/null || true
  # 4. Config OLS (dacă există)
  if [ -d "/usr/local/lsws/conf/vhosts/$domain" ]; then
    tar czf "$backup_dir/ols_vhost.tar.gz" -C "/usr/local/lsws/conf/vhosts" "$domain" || ok=0
  fi
  # 5. wp-config.php
  if [ -f "/home/$username/www/$domain/wp-config.php" ]; then
    cp "/home/$username/www/$domain/wp-config.php" "$backup_dir/" || ok=0
  fi

  # 6. Generează checksum
  (cd "$backup_dir" && sha256sum * > checksums.sha256 2>/dev/null)

  # Actualizează latest pointer
  ln -sfn "$backup_dir" "$BACKUP_ROOT/latest_${username}_${domain}"

  run_hook post "$username" "$domain"

  # Upload cloud dacă există rclone.conf
  if [ -f "/home/$username/config/rclone.conf" ]; then
    backup_with_rclone "$backup_dir" "remote:${username}_${domain}_incremental_$now" && log_msg "cloud_upload_done" || log_msg "cloud_upload_error"
  fi

  # Notificare avansată (mail + extensibil)
  send_notification "$username" "$domain" "$backup_dir" "$ok" "incremental_backup"

  if [ "$ok" = 1 ]; then
    log_msg "backup_incremental_done"
  else
    log_msg "backup_incremental_error"
  fi
}
# Notificare avansată (mail, extensibilă cu Slack, webhook etc)
send_notification() {
  local username="$1" domain="$2" backup_dir="$3" status="$4" type="$5"
  local subject msgbody
  if [ "$type" = "backup" ]; then
    subject="[Stack] Backup complet $username/$domain: $(date)"
    msgbody="Backup complet pentru $username/$domain la $(date).\nBackup dir: $backup_dir\nStatus: $([[ "$status" = 1 ]] && echo 'SUCCES' || echo 'EROARE')"
  elif [ "$type" = "incremental_backup" ]; then
    subject="[Stack] Backup incremental $username/$domain: $(date)"
    msgbody="Backup incremental pentru $username/$domain la $(date).\nBackup dir: $backup_dir\nStatus: $([[ "$status" = 1 ]] && echo 'SUCCES' || echo 'EROARE')"
  else
    subject="[Stack] Notificare $type $username/$domain: $(date)"
    msgbody="Notificare $type pentru $username/$domain la $(date).\nBackup dir: $backup_dir\nStatus: $([[ "$status" = 1 ]] && echo 'SUCCES' || echo 'EROARE')"
  fi
  # Notificare email (dacă există mail)
  if command -v mail >/dev/null 2>&1; then
    echo -e "$msgbody" | mail -s "$subject" "admin@$domain"
  fi
  # Extensibil: Slack/webhook/alte servicii
  # if [ -f "/home/$username/config/slack_webhook_url" ]; then
  #   curl -X POST -H 'Content-type: application/json' --data '{"text":"'$msgbody'"}' "$(cat /home/$username/config/slack_webhook_url)"
  # fi
}


# Restore backup pentru un user/domeniu cu hooks și verificare checksum
restore_user_domain() {
  local backup_dir="$1" username="$2" domain="$3"
  log_msg "restore_start"; echo "$username/$domain $backup_dir" | tee -a "$LOG_FILE"

  run_hook pre_restore "$username" "$domain"

  # 0. Verifică checksum
  if [ -f "$backup_dir/checksums.sha256" ]; then
    (cd "$backup_dir" && sha256sum -c checksums.sha256) || { log_msg "restore_checksum_error"; return 1; }
  fi

  # 1. Restore web files
  if [ -f "$backup_dir/web.tar.gz" ]; then
    tar xzf "$backup_dir/web.tar.gz" -C "/home/$username/www"
  fi
  # 2. Restore DB
  if [ -f "$backup_dir/db.sql" ]; then
    mysql "${username}_db" < "$backup_dir/db.sql"
  fi
  # 3. Restore Nginx config
  if [ -f "$backup_dir/nginx.conf" ]; then
    cp "$backup_dir/nginx.conf" "/etc/nginx/sites-available/$domain"
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
    nginx -t && systemctl reload nginx
  fi
  # 4. Restore OLS config
  if [ -f "$backup_dir/ols_vhost.tar.gz" ]; then
    tar xzf "$backup_dir/ols_vhost.tar.gz" -C "/usr/local/lsws/conf/vhosts"
    /usr/local/lsws/bin/lswsctrl restart
  fi
  # 5. Restore wp-config.php
  if [ -f "$backup_dir/wp-config.php" ]; then
    cp "$backup_dir/wp-config.php" "/home/$username/www/$domain/"
  fi

  run_hook post_restore "$username" "$domain"

  log_msg "restore_done"
}


# Failback: dacă restore eșuează, revine la backup anterior
failback_restore() {
  local username="$1" domain="$2" failed_backup="$3"
  log_msg "failback_start"
  # Găsește backup-ul anterior
  prev_backup=""
  for f in "$BACKUP_ROOT"/${username}_${domain}_*; do
    [ -e "$f" ] || continue
    if [[ "$f" != "$failed_backup" ]]; then
      backups+=("$f")
    fi
  done
  if [ ${#backups[@]} -gt 0 ]; then
    local sorted=()
    mapfile -t sorted < <(printf '%s\n' "${backups[@]}" | sort -r)
    prev_backup="${sorted[0]}"
  fi
  if [ -n "$prev_backup" ]; then
    restore_user_domain "$prev_backup" "$username" "$domain"
  else
    log_msg "failback_error"
  fi
}


# Backup/restore cu rclone (opțional)
backup_with_rclone() {
  local src_dir="$1" rclone_remote="$2"
  rclone copy "$src_dir" "$rclone_remote" --progress 2>>"$LOG_FILE"
}
restore_with_rclone() {
  local rclone_remote="$1" dest_dir="$2"
  rclone copy "$rclone_remote" "$dest_dir" --progress 2>>"$LOG_FILE"
}

# Listă backup-uri disponibile pentru user/domeniu
list_backups() {
  local username="$1" domain="$2"
  ls -1d $BACKUP_ROOT/${username}_${domain}_* 2>/dev/null | sort -r
}

# Șterge backup vechi (păstrează ultimele N)
cleanup_old_backups() {
  local username="$1" domain="$2" keep="$3"
  local backups=()
  for f in "$BACKUP_ROOT"/${username}_${domain}_*; do
    [ -e "$f" ] || continue
    backups+=("$f")
  done
  local backups_sorted=()
  mapfile -t backups_sorted < <(printf '%s\n' "${backups[@]}" | sort -r)
  local total=${#backups_sorted[@]}
  if [ "$total" -le "$keep" ]; then return; fi
  for ((i=keep; i<total; i++)); do
    rm -rf "${backups_sorted[$i]}"
    log_msg "backup_deleted"
  done
}

# Adaugă backup la cron (ex: zilnic la 2:00)
schedule_backup_cron() {
  local username="$1" domain="$2" hour="$3" min="$4"
  (crontab -l 2>/dev/null; echo "$min $hour * * * $SCRIPT_DIR/backup_manager.sh scheduled $username $domain") | sort | uniq | crontab -
  log_msg "cron_scheduled"
}

# Execută backup programat (pentru cron)
if [ "$1" = "scheduled" ]; then
  backup_user_domain "$2" "$3"
  exit 0
fi


# Manager general de backup cu meniu multi-lingual și loop
backup_manager_menu() {
  while true; do
    echo "==== $(msg backup_manager_title) ===="
    echo "1. $(msg backup_menu_backup)"
    echo "2. $(msg backup_menu_restore)"
    echo "3. $(msg backup_menu_list)"
    echo "4. $(msg backup_menu_rclone_backup)"
    echo "5. $(msg backup_menu_rclone_restore)"
    echo "6. $(msg backup_menu_cleanup)"
    echo "7. $(msg backup_menu_schedule)"
    echo "0. $(msg backup_menu_exit)"
    read -p "$(msg backup_menu_prompt)" opt
    case $opt in
      1)
        read -p "$(msg backup_prompt_user)" u; read -p "$(msg backup_prompt_domain)" d; backup_user_domain "$u" "$d"; read -p "$(msg press_enter)";;
      2)
        read -p "$(msg backup_prompt_path)" b; read -p "$(msg backup_prompt_user)" u; read -p "$(msg backup_prompt_domain)" d; restore_user_domain "$b" "$u" "$d" || failback_restore "$u" "$d" "$b"; read -p "$(msg press_enter)";;
      3)
        read -p "$(msg backup_prompt_user)" u; read -p "$(msg backup_prompt_domain)" d; list_backups "$u" "$d"; read -p "$(msg press_enter)";;
      4)
        read -p "$(msg backup_prompt_srcdir)" s; read -p "$(msg backup_prompt_rclone)" r; backup_with_rclone "$s" "$r"; read -p "$(msg press_enter)";;
      5)
        read -p "$(msg backup_prompt_rclone)" r; read -p "$(msg backup_prompt_dstdir)" d; restore_with_rclone "$r" "$d"; read -p "$(msg press_enter)";;
      6)
        read -p "$(msg backup_prompt_user)" u; read -p "$(msg backup_prompt_domain)" d; read -p "$(msg backup_prompt_keep)" k; cleanup_old_backups "$u" "$d" "$k"; read -p "$(msg press_enter)";;
      7)
        read -p "$(msg backup_prompt_user)" u; read -p "$(msg backup_prompt_domain)" d; read -p "$(msg backup_prompt_hour)" h; read -p "$(msg backup_prompt_min)" m; schedule_backup_cron "$u" "$d" "$h" "$m"; read -p "$(msg press_enter)";;
      0) exit 0;;
      *) echo "$(msg invalid_option)";;
    esac
  done
}


