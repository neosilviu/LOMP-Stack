#!/bin/bash
#
# lang.sh - Part of LOMP Stack v3.0
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
# lang.sh - Helper pentru traduceri și funcția tr_lang
# Exemplu: tr_lang "start"


# tr_lang: traducere din fișiere JSON din translations/
tr_lang() {
  local key="$1"
  local lang_file lang
  lang="${LANG_OPT:-ro}"
  lang_file="$(dirname "${BASH_SOURCE[0]}")/../../translations/${lang}.json"
  if [[ ! -f "$lang_file" ]]; then
    lang_file="$(dirname "${BASH_SOURCE[0]}")/../../translations/ro.json"
  fi
  # Caută cheia în fișierul JSON (jq sau fallback grep/sed)
  if command -v jq &>/dev/null; then
    jq -r --arg k "$key" '.[$k] // $k' "$lang_file"
  else
    # fallback simplu fără jq
    local val
    val=$(grep -E '"'$key'"' "$lang_file" | sed -E 's/.*: *"(.*)".*/\1/' | head -n1)
    if [[ -n "$val" ]]; then
      echo "$val"
    else
      echo "$key"
    fi
  fi
}
