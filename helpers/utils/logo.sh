#!/bin/bash
#
# logo.sh - Centralized logo display for each user
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

# Load author information
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/author_info.sh"

center_text() {
  local term_width text padding
  term_width=$(tput cols 2>/dev/null || echo 80)
  text="$1"
  padding=$(( (term_width - ${#text}) / 2 ))
  printf '%*s%s\n' "$padding" '' "$text"
}

display_logo() {
  local user_logo_dir="$HOME/.stack_logos"
  local user_logo_file="$user_logo_dir/logo.txt"
  local default_logo="\n  ██╗      ██████╗ ███╗   ███╗██████╗     ██╗   ██╗██████╗ \n  ██║     ██╔═══██╗████╗ ████║██╔══██╗    ██║   ██║╚════██╗\n  ██║     ██║   ██║██╔████╔██║██████╔╝    ██║   ██║ █████╔╝\n  ██║     ██║   ██║██║╚██╔╝██║██╔═══╝     ╚██╗ ██╔╝ ╚═══██╗\n  ███████╗╚██████╔╝██║ ╚═╝ ██║██║          ╚████╔╝ ██████╔╝\n  ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝           ╚═══╝  ╚═════╝ \n"

  mkdir -p "$user_logo_dir"
  if [[ ! -f "$user_logo_file" ]]; then
    echo -e "$default_logo" > "$user_logo_file"
  fi
  while IFS= read -r line; do
    center_text "$line"
  done < "$user_logo_file"
  
  # Add author information below logo
  echo
  center_text "Advanced Hosting Control Panel"
  center_text "by $AUTHOR_NAME ($AUTHOR_COMPANY)"
  center_text "Version $PROJECT_VERSION"
  echo
}
