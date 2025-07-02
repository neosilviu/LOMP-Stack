#!/bin/bash
#
# auto_translate_lang.sh - Part of LOMP Stack v3.0
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
# auto_translate_lang.sh
# Usage: ./auto_translate_lang.sh <target_lang|all> [source_file]
# Example: ./auto_translate_lang.sh en lang_ro.sh
#          ./auto_translate_lang.sh all lang_ro.sh

TARGET_LANG="$1"
SRC_FILE="${2:-lang_ro.sh}"

if ! command -v trans &> /dev/null; then
  echo "Eroare: utilitarul 'trans' (translate-shell) nu este instalat!" >&2
  exit 1
fi

if [ -z "$TARGET_LANG" ]; then
  echo "Usage: $0 <target_lang|all> [source_file]" >&2
  exit 1
fi

if [ "$TARGET_LANG" = "all" ]; then
  for lang in en es fr de; do
    "$0" "$lang" "$SRC_FILE"
  done
  exit 0
fi


OUT_FILE="lang_${TARGET_LANG}.sh"

echo "# shellcheck shell=bash" > "$OUT_FILE"
echo "# $TARGET_LANG translations for installer (associative array version)" >> "$OUT_FILE"
echo "declare -A TR_${TARGET_LANG^^}=(" >> "$OUT_FILE"

grep -E '^[ ]*[a-zA-Z0-9_]+\)' "$SRC_FILE" | while read -r line; do
  key=$(echo "$line" | cut -d')' -f1)
  ro_text=$(echo "$line" | sed -E 's/^[^)]*\) echo \"(.*)\";;/\1/')
  tr_text=$(trans -b :$TARGET_LANG "$ro_text")
  # Escape quotes for Bash
  tr_text_escaped=$(echo "$tr_text" | sed 's/"/\\"/g')
  echo "  [$key]=\"$tr_text_escaped\"" >> "$OUT_FILE"
done

echo ")" >> "$OUT_FILE"
echo "" >> "$OUT_FILE"
echo "tr_lang_key() {" >> "$OUT_FILE"
echo "  local key=\"$1\"" >> "$OUT_FILE"
echo "  if [[ -n \"\${TR_${TARGET_LANG^^}[$key]+x}\" ]]; then" >> "$OUT_FILE"
echo "    echo \"\${TR_${TARGET_LANG^^}[$key]}\"" >> "$OUT_FILE"
echo "  else" >> "$OUT_FILE"
echo "    echo \"$key\"" >> "$OUT_FILE"
echo "  fi" >> "$OUT_FILE"
echo "}" >> "$OUT_FILE"
