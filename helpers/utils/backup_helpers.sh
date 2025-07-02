#!/bin/bash
#
# backup_helpers.sh - Part of LOMP Stack v3.0
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
# backup_helpers.sh - Funcții pentru generare scripturi backup/restore per user

generate_user_backup_scripts() {
  local username="$1"
  local domain="$2"
  local user_config_dir="$3"
  local BACKUP_MANAGER
  BACKUP_MANAGER="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/backup_manager.sh"
  local backup_script="$user_config_dir/backup.sh"
  local restore_script="$user_config_dir/restore.sh"
  local incremental_backup_script="$user_config_dir/incremental_backup.sh"
  if [ ! -f "$BACKUP_MANAGER" ]; then
    echo "[WARN] Nu găsesc $BACKUP_MANAGER! Scripturile de backup nu vor fi generate."
    return 1
  fi
  cat <<EOF | sudo tee "$backup_script" > /dev/null
#!/bin/bash
exec /usr/bin/env bash "$BACKUP_MANAGER" backup_user_domain "$username" "$domain"
EOF
  cat <<EOF | sudo tee "$incremental_backup_script" > /dev/null
#!/bin/bash
exec /usr/bin/env bash "$BACKUP_MANAGER" incremental_backup_user_domain "$username" "$domain"
EOF
  cat <<EOF | sudo tee "$restore_script" > /dev/null
#!/bin/bash
if [ -z "$1" ]; then echo "Usage: $0 <backup_dir>"; exit 1; fi
exec /usr/bin/env bash "$BACKUP_MANAGER" restore_user_domain "$1" "$username" "$domain"
EOF
  sudo chown "$username":www-data "$backup_script" "$restore_script" "$incremental_backup_script"
  sudo chmod 750 "$backup_script" "$restore_script" "$incremental_backup_script"
  "$BACKUP_MANAGER" cleanup_old_backups "$username" "$domain" 7
}
