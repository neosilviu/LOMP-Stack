# shellcheck shell=bash
# php_packages_menu.sh - Meniu și funcții pentru gestionarea pachetelor PHP/lsphp opționale
# DEBUG: Confirmăm că fișierul este sursat corect și funcția va fi definită

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/lang.sh"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/php_actions.sh"


# Liste de versiuni și extensii suportate
PHP_VERSIONS=(8.4 8.3 8.2 8.1 8.0 7.4)
LSPHP_VERSIONS=(8.4 8.3 8.2 8.1 8.0 7.4)
PHP_EXTENSIONS=(bcmath bz2 calendar cgi cli common core ctype curl dba dom enchant exif ffi fileinfo filter ftp gd gettext gmp iconv igbinary imagick imap intl json ldap mbstring memcached mongodb msgpack mysql mysqlnd oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird pdo_mysql pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix propro pspell readline redis relay shmop simplexml snmp soap sockets sodium solr sqlite3 sysvmsg sysvsem sysvshm tidy tokenizer xdebug xml xmlreader xmlrpc xmlwriter xsl yaml zip zlib)

# Import robust lsphp binary finder
if ! declare -f find_lsphp_binary >/dev/null; then
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/php_actions.sh"
fi

select_php_version() {
  local installed=() available=() all=("${PHP_VERSIONS[@]}")
  for v in "${all[@]}"; do
    if command -v php$v >/dev/null 2>&1; then
      installed+=("$v")
    else
      available+=("$v")
    fi
  done
  echo
  echo "================ LISTA VERSIUNI PHP ================"
  local idx=1
  if [[ ${#installed[@]} -gt 0 ]]; then
    echo "-- $(tr_lang versiuni_instalate) --"
    for v in "${installed[@]}"; do
      echo "  $idx. $v $(tr_lang instalat)"; ((idx++));
    done
  else
    echo "$(tr_lang nicio_versiune_php_instalata)"
  fi
  if [[ ${#available[@]} -gt 0 ]]; then
    echo "-- $(tr_lang versiuni_disponibile_pentru_instalare) --"
    for v in "${available[@]}"; do
      echo "  $idx. $v $(tr_lang descarca_si_instaleaza)"; ((idx++));
    done
  fi
  echo "  0. $(tr_lang inapoi)"
  echo
  read -p "$(tr_lang selecteaza_php_version_multi)" sel
  # Permite selectare multiplă pentru instalare
  local selected_versions=()
  for idx_sel in $sel; do
    if [[ "$idx_sel" =~ ^[0-9]+$ ]] && (( idx_sel >= 1 && idx_sel < idx )); then
      if (( idx_sel <= ${#installed[@]} )); then
        selected_versions+=("${installed[$((idx_sel-1))]}")
      else
        local av_idx=$((idx_sel-1-${#installed[@]}))
        download_and_install_php_from_source "${available[$av_idx]}"
        selected_versions+=("${available[$av_idx]}")
      fi
    fi
  done
  if [[ ${#selected_versions[@]} -gt 0 ]]; then
    echo "${selected_versions[*]}"
    return
  fi
  echo ""
  return
}

select_lsphp_version() {
  local installed=() available=() all=("${LSPHP_VERSIONS[@]}")
  for v in "${all[@]}"; do
    if find_lsphp_binary "$v" >/dev/null 2>&1; then
      installed+=("$v")
    else
      available+=("$v")
    fi
  done
  echo
  echo "================ LISTA VERSIUNI LSPHP ================"
  local idx=1
  if [[ ${#installed[@]} -gt 0 ]]; then
    echo "-- $(tr_lang versiuni_instalate) --"
    for v in "${installed[@]}"; do
      echo "  $idx. $v $(tr_lang instalat)"; ((idx++));
    done
  else
    echo "$(tr_lang nicio_versiune_lsphp_instalata)"
  fi
  if [[ ${#available[@]} -gt 0 ]]; then
    echo "-- $(tr_lang versiuni_disponibile_pentru_instalare) --"
    for v in "${available[@]}"; do
      echo "  $idx. $v $(tr_lang descarca_si_instaleaza)"; ((idx++));
    done
  fi
  echo "  0. $(tr_lang inapoi)"
  echo
  read -p "$(tr_lang selecteaza_lsphp_version_multi)" sel
  # Permite selectare multiplă pentru instalare
  local selected_versions=()
  for idx_sel in $sel; do
    if [[ "$idx_sel" =~ ^[0-9]+$ ]] && (( idx_sel >= 1 && idx_sel < idx )); then
      if (( idx_sel <= ${#installed[@]} )); then
        selected_versions+=("${installed[$((idx_sel-1))]}")
      else
        local av_idx=$((idx_sel-1-${#installed[@]}))
        download_and_install_lsphp_from_source "${available[$av_idx]}"
        selected_versions+=("${available[$av_idx]}")
      fi
    fi
  done
  if [[ ${#selected_versions[@]} -gt 0 ]]; then
    echo "${selected_versions[*]}"
    return
  fi
  echo ""
  return
}

select_php_extensions() {
  local php_version="$1"
  local ext_list=()
  local sel ext_selected=()
  # Detectează pachetele disponibile pentru versiunea selectată
  if [[ -n "$php_version" ]]; then
    if command -v apt >/dev/null 2>&1; then
      local search_result
      search_result=$(apt-cache search "^php$php_version-" | awk '{print $1}')
      echo "[DEBUG] apt-cache search ^php$php_version-: $search_result" >&2
      if [[ -n "$search_result" ]]; then
        mapfile -t ext_list < <(echo "$search_result" | sed "s/^php$php_version-//" | sort)
      else
        # fallback la lista statică dacă nu găsește nimic
        ext_list=("${PHP_EXTENSIONS[@]}")
        echo "[DEBUG] Fallback la lista statică de extensii" >&2
      fi
    fi
  fi
  if [[ ${#ext_list[@]} -eq 0 ]]; then
    color_echo red "$(tr_lang nicio_extensie_disponibila)"
    read -p "$(tr_lang apasa_enter_pentru_a_continua)"
    return 1
  fi
  echo "[DEBUG] EXTENSII DISPONIBILE PENTRU PHP $php_version: ${ext_list[*]}" >&2
  for i in "${!ext_list[@]}"; do
    echo " $((i+1)). ${ext_list[$i]}" >&2
  done
  color_echo red   " 0. $(tr_lang fara_extensii)"
  read -p "$(tr_lang selecteaza_extensii_php)" sel
  if [[ "$sel" == "0" ]]; then
    return 1
  fi
  for idx in $sel; do
    if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#ext_list[@]} )); then
      ext_selected+=("${ext_list[$((idx-1))]}")
    fi
  done
  echo "${ext_selected[*]}"
}

select_lsphp_extensions() {
  local lsphp_version="$1"
  local ext_list=()
  local sel ext_selected=()
  # Detectează pachetele disponibile pentru versiunea selectată
  if [[ -n "$lsphp_version" ]]; then
    if command -v apt >/dev/null 2>&1; then
      local search_result
      # Folosește wsl dacă rulezi din PowerShell
      if grep -qi microsoft /proc/version 2>/dev/null && ! grep -qE '/bin/(bash|sh)' <<< "$SHELL"; then
        search_result=$(wsl --exec bash -c "apt-cache search '^lsphp$lsphp_version-'" | awk '{print $1}')
      else
        search_result=$(apt-cache search "^lsphp$lsphp_version-" | awk '{print $1}')
      fi
      echo "[DEBUG] RAW search_result: $search_result" >&2
      # Normalize line endings and remove empty lines
      search_result=$(echo "$search_result" | tr -d '\r' | grep .)
      if [[ -n "$search_result" ]]; then
        mapfile -t ext_list < <(echo "$search_result" | sed "s/^lsphp$lsphp_version-//" | sort)
      fi
      echo "[DEBUG] ext_list: ${ext_list[*]}" >&2
    fi
  fi
  if [[ ${#ext_list[@]} -eq 0 ]]; then
    color_echo red "$(tr_lang nicio_extensie_disponibila)"
    read -p "$(tr_lang apasa_enter_pentru_a_continua)"
    return 1
  fi
  echo "[DEBUG] EXTENSII DISPONIBILE PENTRU LSPHP $lsphp_version: ${ext_list[*]}" >&2
  for i in "${!ext_list[@]}"; do
    echo " $((i+1)). ${ext_list[$i]}" >&2
  done
  color_echo red   " 0. $(tr_lang fara_extensii)"
  read -p "$(tr_lang selecteaza_extensii_php)" sel
  if [[ "$sel" == "0" ]]; then
    return 1
  fi
  for idx in $sel; do
    if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#ext_list[@]} )); then
      ext_selected+=("${ext_list[$((idx-1))]}")
    fi
  done
  echo "${ext_selected[*]}"
}

show_php_packages_menu() {
  # Detectează ce webserver rulează și ce tip de PHP e activ
  local has_ols=0 has_apache=0 has_nginx=0
  if pgrep -x lsws >/dev/null 2>&1 || command -v /usr/local/lsws/bin/lswsctrl >/dev/null 2>&1 || command -v lswsctrl >/dev/null 2>&1; then
    has_ols=1
  elif pgrep -x apache2 >/dev/null 2>&1 || pgrep -x httpd >/dev/null 2>&1; then
    has_apache=1
  elif pgrep -x nginx >/dev/null 2>&1; then
    has_nginx=1
  fi

  while true; do
    local php_current_version=""
    if command -v php >/dev/null 2>&1; then
      php_current_version=$(php -v 2>/dev/null | head -n1 | awk '{print $2}')
    fi
    color_echo magenta "\n╔════════════════════════════════════════════════════════════════════════════════════╗"
    color_echo magenta   "║           🧩  $(tr_lang meniu_pachete_php_lsphp_optionale)                        ║"
    color_echo magenta   "╚════════════════════════════════════════════════════════════════════════════════════╝"
    if [[ -n "$php_current_version" ]]; then
      color_echo cyan "$(tr_lang versiune_php_instalata): $php_current_version"
    fi
    # Detectează și afișează versiunile lsphp instalate (doar dacă OLS este activ)
    if [[ $has_ols -eq 1 ]]; then
      local installed_lsphp=()
      for v in "${LSPHP_VERSIONS[@]}"; do
        if find_lsphp_binary "$v" >/dev/null 2>&1; then
          installed_lsphp+=("$v")
        fi
      done
      if [[ ${#installed_lsphp[@]} -gt 0 ]]; then
        color_echo cyan "Versiuni lsphp instalate: ${installed_lsphp[*]}"
      else
        color_echo yellow "Nicio versiune lsphp detectată."
      fi
    fi

    if [[ $has_ols -eq 1 ]]; then
      color_echo yellow    " 1. $(tr_lang schimbare_versiune_lsphp)"
      color_echo yellow    " 2. $(tr_lang adauga_extensii_lsphp)"
      color_echo yellow    " 3. Elimină extensii lsphp"
    elif [[ $has_apache -eq 1 || $has_nginx -eq 1 ]]; then
      color_echo yellow    " 1. $(tr_lang schimbare_versiune_php)"
      color_echo yellow    " 2. $(tr_lang adauga_extensii_php)"
      color_echo yellow    " 3. Elimină extensii PHP"
    else
      color_echo red "[WARN] Nu a fost detectat niciun webserver activ (OLS, Apache, nginx). Opțiunile PHP/lsphp sunt dezactivate."
      color_echo red " 0. $(tr_lang inapoi)"
      read -p "$(tr_lang apasa_enter_pentru_a_continua)"
      return 0
    fi
    color_echo red       " 0. $(tr_lang inapoi)"
    color_echo none      "────────────────────────────────────────────────────────────────────────────────────"
    read -p "$(tr_lang alege_opt_pkg)" pkg_opt
    case $pkg_opt in
      1)
        # Instalează DOAR binarul (fără extensii)
        if [[ $has_ols -eq 1 ]]; then
          select_lsphp_version
          read -r lsphp_ver
          if [[ -n "$lsphp_ver" ]]; then
            install_php_package lsphp "$lsphp_ver" ""
          else
            color_echo red "$(tr_lang versiune_invalida_sau_anulat)"
          fi
        else
          select_php_version
          read -r php_ver
          if [[ -n "$php_ver" ]]; then
            install_php_package php "$php_ver" ""
          else
            color_echo red "$(tr_lang versiune_invalida_sau_anulat)"
          fi
        fi
        ;;
      2)
        # Instalează DOAR extensii pentru o versiune deja instalată
        if [[ $has_ols -eq 1 ]]; then
          # Afișează doar versiunile lsphp instalate
          local installed_lsphp=()
          for v in "${LSPHP_VERSIONS[@]}"; do
            if find_lsphp_binary "$v" >/dev/null 2>&1; then
              installed_lsphp+=("$v")
            fi
          done
          if [[ ${#installed_lsphp[@]} -eq 0 ]]; then
            color_echo red "Nu există nicio versiune lsphp instalată. Instalează mai întâi binarul!"
            continue
          fi
          echo "Selectează versiunea lsphp pentru extensii:"
          local idx=1
          for v in "${installed_lsphp[@]}"; do
            echo "  $idx. $v"; ((idx++));
          done
          echo "  0. $(tr_lang inapoi)"
          read -p "Număr: " sel_idx
          if [[ ! "$sel_idx" =~ ^[0-9]+$ ]] || (( sel_idx < 1 || sel_idx > ${#installed_lsphp[@]} )); then
            continue
          fi
          lsphp_ver="${installed_lsphp[$((sel_idx-1))]}"
          php_ext=$(select_lsphp_extensions "$lsphp_ver")
          if [[ -z "$php_ext" ]]; then
            color_echo yellow "Nu există extensii disponibile sau selectate pentru această versiune lsphp!"
            continue
          fi
          install_php_package lsphp "$lsphp_ver" "$php_ext"
        else
          # Afișează doar versiunile PHP instalate
          local installed_php=()
          for v in "${PHP_VERSIONS[@]}"; do
            if command -v php$v >/dev/null 2>&1; then
              installed_php+=("$v")
            fi
          done
          if [[ ${#installed_php[@]} -eq 0 ]]; then
            color_echo red "Nu există nicio versiune PHP instalată. Instalează mai întâi binarul!"
            continue
          fi
          echo "Selectează versiunea PHP pentru extensii:"
          local idx=1
          for v in "${installed_php[@]}"; do
            echo "  $idx. $v"; ((idx++));
          done
          echo "  0. $(tr_lang inapoi)"
          read -p "Număr: " sel_idx
          if [[ ! "$sel_idx" =~ ^[0-9]+$ ]] || (( sel_idx < 1 || sel_idx > ${#installed_php[@]} )); then
            continue
          fi
          php_ver="${installed_php[$((sel_idx-1))]}"
          php_ext=$(select_php_extensions "$php_ver")
          if [[ -z "$php_ext" ]]; then
            color_echo yellow "Nu există extensii disponibile sau selectate pentru această versiune PHP!"
            continue
          fi
          install_php_package php "$php_ver" "$php_ext"
        fi
        ;;
      3)
        # Elimină extensii pentru o versiune deja instalată
        if [[ $has_ols -eq 1 ]]; then
          local installed_lsphp=()
          for v in "${LSPHP_VERSIONS[@]}"; do
            if find_lsphp_binary "$v" >/dev/null 2>&1; then
              installed_lsphp+=("$v")
            fi
          done
          if [[ ${#installed_lsphp[@]} -eq 0 ]]; then
            color_echo red "Nu există nicio versiune lsphp instalată. Instalează mai întâi binarul!"
            continue
          fi
          echo "Selectează versiunea lsphp pentru eliminare extensii:"
          local idx=1
          for v in "${installed_lsphp[@]}"; do
            echo "  $idx. $v"; ((idx++));
          done
          echo "  0. $(tr_lang inapoi)"
          read -p "Număr: " sel_idx
          if [[ ! "$sel_idx" =~ ^[0-9]+$ ]] || (( sel_idx < 1 || sel_idx > ${#installed_lsphp[@]} )); then
            continue
          fi
          lsphp_ver="${installed_lsphp[$((sel_idx-1))]}"
          # Listare extensii instalate lsphp
          local ext_list=()
          if grep -qi microsoft /proc/version 2>/dev/null && ! grep -qE '/bin/(bash|sh)' <<< "$SHELL"; then
            mapfile -t ext_list < <(wsl --exec bash -c "dpkg -l | grep '^ii' | grep 'lsphp$lsphp_ver-' | awk '{print \\\$2}' | sed 's/^lsphp$lsphp_ver-//'")
          else
            mapfile -t ext_list < <(dpkg -l | grep '^ii' | grep "lsphp$lsphp_ver-" | awk '{print $2}' | sed "s/^lsphp$lsphp_ver-//")
          fi
          if [[ ${#ext_list[@]} -eq 0 ]]; then
            color_echo yellow "Nu există extensii lsphp instalate pentru această versiune!"
            continue
          fi
          echo "Extensii lsphp$lsphp_ver instalate:"
          local i=1
          for ext in "${ext_list[@]}"; do
            echo "  $i. $ext"; ((i++));
          done
          echo "  0. $(tr_lang inapoi)"
          read -p "Selectează extensiile de eliminat (ex: 1 3 5): " sel
          local selected_ext=()
          for idx in $sel; do
            if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx < i )); then
              selected_ext+=("${ext_list[$((idx-1))]}")
            fi
          done
          if [[ ${#selected_ext[@]} -eq 0 ]]; then
            color_echo yellow "Nicio extensie selectată pentru eliminare."
            continue
          fi
          remove_php_package lsphp "$lsphp_ver" "${selected_ext[*]}"
        else
          local installed_php=()
          for v in "${PHP_VERSIONS[@]}"; do
            if command -v php$v >/dev/null 2>&1; then
              installed_php+=("$v")
            fi
          done
          if [[ ${#installed_php[@]} -eq 0 ]]; then
            color_echo red "Nu există nicio versiune PHP instalată. Instalează mai întâi binarul!"
            continue
          fi
          echo "Selectează versiunea PHP pentru eliminare extensii:"
          local idx=1
          for v in "${installed_php[@]}"; do
            echo "  $idx. $v"; ((idx++));
          done
          echo "  0. $(tr_lang inapoi)"
          read -p "Număr: " sel_idx
          if [[ ! "$sel_idx" =~ ^[0-9]+$ ]] || (( sel_idx < 1 || sel_idx > ${#installed_php[@]} )); then
            continue
          fi
          php_ver="${installed_php[$((sel_idx-1))]}"
          # Listare extensii instalate PHP
          local ext_list=()
          mapfile -t ext_list < <(dpkg -l | grep '^ii' | grep "php$php_ver-" | awk '{print $2}' | sed "s/^php$php_ver-//")
          if [[ ${#ext_list[@]} -eq 0 ]]; then
            color_echo yellow "Nu există extensii PHP instalate pentru această versiune!"
            continue
          fi
          echo "Extensii php$php_ver instalate:"
          local i=1
          for ext in "${ext_list[@]}"; do
            echo "  $i. $ext"; ((i++));
          done
          echo "  0. $(tr_lang inapoi)"
          read -p "Selectează extensiile de eliminat (ex: 1 3 5): " sel
          local selected_ext=()
          for idx in $sel; do
            if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx < i )); then
              selected_ext+=("${ext_list[$((idx-1))]}")
            fi
          done
          if [[ ${#selected_ext[@]} -eq 0 ]]; then
            color_echo yellow "Nicio extensie selectată pentru eliminare."
            continue
          fi
          remove_php_package php "$php_ver" "${selected_ext[*]}"
        fi
        ;;
      0|*) return 0;;
    esac
    read -p "$(tr_lang apasa_enter_pentru_a_continua)"
  done
}
