#!/bin/bash
#
# notify_helpers.sh - Part of LOMP Stack v3.0
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
# notify_helpers.sh - Funcții pentru notificări (mail, slack, etc)

notify_backup_mail() {
  local username="$1"
  local domain="$2"
  if command -v mail >/dev/null 2>&1; then
    echo "Backup complet pentru $username/$domain la $(date)" | mail -s "[Stack] Backup complet $username/$domain" admin@$domain || true
  fi
}
