# shellcheck shell=bash
# php_actions.sh - Funcții generice pentru acțiuni de start/stop/restart/status pentru PHP și lsphp
# Descărcare și instalare automată PHP din sursă pentru versiunile care nu există în apt

. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/functions.sh"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/lang.sh"

download_and_install_php_from_source() {
  local version="$1"
  color_echo yellow "$(tr_lang descarca_instaleaza_php) $version (source) ..."
  local url="https://www.php.net/distributions/php-${version}.tar.gz"
  local build_dir="/usr/local/src/php-$version"
  sudo mkdir -p "$build_dir"
  cd /usr/local/src || return 1
  sudo wget -O "php-$version.tar.gz" "$url"
  sudo tar -xzf "php-$version.tar.gz"
  cd "php-$version" || return 1
  sudo apt-get update
  sudo apt-get install -y build-essential libxml2-dev libsqlite3-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev libzip-dev libonig-dev libssl-dev pkg-config bison re2c autoconf
  sudo ./configure --prefix=/usr/local/php$version --with-config-file-path=/usr/local/php$version/etc --enable-fpm --with-zlib --enable-mbstring --with-curl --with-openssl --enable-intl --with-zip --with-pdo-mysql --with-mysqli --enable-bcmath --enable-gd --with-jpeg --with-webp --with-freetype
  sudo make -j"$(nproc)"
  sudo make install
  sudo ln -sf /usr/local/php$version/bin/php /usr/local/bin/php$version
  color_echo green "PHP $version $(tr_lang instalat_din_sursa) (/usr/local/php$version)"
}

# Robust lsphp binary finder
find_lsphp_binary() {
  local version="$1"
  # Strict OLS/LSWS: /usr/local/lsws/lsphp<version>/bin/lsphp (no dot)
  if [[ -n "$version" ]]; then
    local bin_path="/usr/local/lsws/lsphp${version//./}/bin/lsphp"
    if [[ -x "$bin_path" ]]; then
      echo "$bin_path"
      return 0
    fi
    # Accept also with dot (rare)
    bin_path="/usr/local/lsws/lsphp$version/bin/lsphp"
    if [[ -x "$bin_path" ]]; then
      echo "$bin_path"
      return 0
    fi
    # Strict: check only if folder matches version
    for d in /usr/local/lsws/lsphp*/bin; do
      if [[ "$d" =~ lsphp([0-9.]+) ]] && [[ "${BASH_REMATCH[1]}" == "$version" || "${BASH_REMATCH[1]}" == "${version//./}" ]]; then
        if [[ -x "$d/lsphp" ]]; then
          echo "$d/lsphp"
          return 0
        fi
      fi
    done
  fi
  # Accept also lsphp without version if only one exists and no version requested
  if [[ -z "$version" ]]; then
    local only_bin=""
    local count=0
    for d in /usr/local/lsws/lsphp*/bin; do
      if [[ -x "$d/lsphp" ]]; then
        only_bin="$d/lsphp"
        ((count++))
      fi
    done
    if [[ $count -eq 1 ]]; then
      echo "$only_bin"
      return 0
    fi
  fi
  # Fallback to /usr/local/bin/lsphp$version
  if [[ -n "$version" && -x "/usr/local/bin/lsphp$version" ]]; then
    echo "/usr/local/bin/lsphp$version"
    return 0
  fi
  # Fallback to PATH
  if [[ -n "$version" ]] && command -v lsphp$version >/dev/null 2>&1; then
    command -v lsphp$version
    return 0
  fi
  # Fallback to /usr/bin/lsphp$version
  if [[ -n "$version" && -x "/usr/bin/lsphp$version" ]]; then
    echo "/usr/bin/lsphp$version"
    return 0
  fi
  return 1
}

# Descărcare și instalare automată lsphp din sursă pentru versiunile care nu există în apt
download_and_install_lsphp_from_source() {
  local version="$1"
  color_echo yellow "$(tr_lang descarca_instaleaza_php) lsphp $version (source) ..."
  local url="https://www.litespeedtech.com/packages/lsphp8/lsphp${version//./}-src.tar.gz"
  local build_dir="/usr/local/src/lsphp-$version"
  sudo mkdir -p "$build_dir"
  cd /usr/local/src || return 1
  # Verifică dacă sursa există înainte de download
  if ! curl -sfI "$url" | grep -q '200 OK'; then
    color_echo red "[EROARE] Sursa pentru lsphp $version nu există la $url. Verifică versiunea sau instalează din pachet."
    return 1
  fi
  sudo wget -O "lsphp-$version.tar.gz" "$url"
  if ! sudo tar -xzf "lsphp-$version.tar.gz"; then
    color_echo red "[EROARE] Arhiva lsphp-$version.tar.gz nu a putut fi dezarhivată. Download eșuat sau corupt."
    return 1
  fi
  cd "lsphp-${version//./}" || { color_echo red "[EROARE] Directorul sursă lsphp-${version//./} nu există după dezarhivare."; return 1; }
  sudo apt-get update
  sudo apt-get install -y build-essential libxml2-dev libsqlite3-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev libzip-dev libonig-dev libssl-dev pkg-config bison re2c autoconf
  sudo ./configure --prefix=/usr/local/lsphp$version --with-config-file-path=/usr/local/lsphp$version/etc --enable-fpm --with-zlib --enable-mbstring --with-curl --with-openssl --enable-intl --with-zip --with-pdo-mysql --with-mysqli --enable-bcmath --enable-gd --with-jpeg --with-webp --with-freetype
  sudo make -j"$(nproc)"
  sudo make install
  sudo ln -sf /usr/local/lsphp$version/bin/lsphp /usr/local/bin/lsphp$version
  color_echo green "lsphp $version $(tr_lang instalat_din_sursa) (/usr/local/lsphp$version)"
}

# Detectează dacă lsphp a fost instalat din sursă (nu există pachet apt lsphp$version)
is_lsphp_from_source() {
  local version="$1"
  if dpkg -l | grep -q "lsphp$version"; then
    return 1  # există pachet, deci nu e din sursă
  fi
  # Dacă binarul există dar nu e pachet, e din sursă
  if [[ -x "/usr/local/lsphp$version/bin/lsphp" ]]; then
    return 0
  fi
  return 1
}

# Usage: php_service_action <tip> <actiune> [versiune]
# tip: php | lsphp
# actiune: start | stop | restart | status
# versiune: 8.1 | 8.0 | etc (opțional)
php_service_action() {
  local php_type="$1" action="$2" version="$3"
  local msg_key svc services
  case "$php_type" in
    php)
      msg_key="php_${action}"
      if [[ -n "$version" ]]; then
        svc="php${version}-fpm"
        color_echo yellow "$(tr_lang $msg_key) ($svc)"
        sudo service "$svc" "$action" && return 0
      else
        services=(php8.1-fpm php8.0-fpm php-fpm)
      fi
      ;;
    lsphp|olsphp|openlitespeed)
      msg_key="olsphp_${action}"
      if [[ -n "$version" ]]; then
        svc="lsphp${version//./}-fpm"
        color_echo yellow "$(tr_lang $msg_key) ($svc)"
        sudo service "$svc" "$action" && return 0
      else
        services=(lsphp81-fpm lsphp80-fpm lsphp-fpm)
      fi
      ;;
    *)
      color_echo red "[PHP] Tip serviciu necunoscut ($php_type)"; return 1;;
  esac
  color_echo yellow "$(tr_lang $msg_key)"
  for svc in "${services[@]}"; do
    sudo service "$svc" "$action" && return 0
  done
  return 1
}

# Instalare pachete PHP sau LSPHP
# Usage: install_php_package <tip> <versiune> <extensii>
# tip: php | lsphp
# versiune: 8.1 | 8.0 | etc (opțional)
# extensii: lista separată prin spațiu (ex: curl mbstring)
install_php_package() {
  local php_type="$1" version="$2" extensions="$3"
  local pkg_base ext pkg_name
  case "$php_type" in
    php)
      pkg_base="php"
      ;;
    lsphp|olsphp|openlitespeed)
      pkg_base="lsphp"
      ;;
    *)
      color_echo red "[PHP] Tip necunoscut pentru instalare ($php_type)"; return 1;;
  esac
  if [[ -n "$version" ]]; then
    pkg_name="${pkg_base}${version}"
  else
    pkg_name="$pkg_base"
  fi
  color_echo yellow "[PHP] Instalare $pkg_name și extensii: $extensions"
  sudo apt-get update
  local ext_pkgs=""
  for ext in $extensions; do
    ext_pkgs+=" ${pkg_name}-$ext"
  done
  # Pentru lsphp instalat din sursă, nu încerca să instalezi extensii cu apt
  if [[ "$php_type" =~ ^lsphp && -n "$version" ]]; then
    if is_lsphp_from_source "$version"; then
      color_echo yellow "[PHP] lsphp$version a fost instalat din sursă. Sari peste instalarea extensiilor cu apt."
      sudo apt-get install -y "$pkg_name" || true
      return 0
    fi
  fi
  sudo apt-get install -y "$pkg_name" $ext_pkgs
}

# Eliminare pachete PHP sau LSPHP
# Usage: remove_php_package <tip> <versiune> <extensii>
remove_php_package() {
  local php_type="$1" version="$2" extensions="$3"
  local pkg_base ext pkg_name
  case "$php_type" in
    php)
      pkg_base="php"
      ;;
    lsphp|olsphp|openlitespeed)
      pkg_base="lsphp"
      ;;
    *)
      color_echo red "[PHP] Tip necunoscut pentru eliminare ($php_type)"; return 1;;
  esac
  if [[ -n "$version" ]]; then
    pkg_name="${pkg_base}${version}"
  else
    pkg_name="$pkg_base"
  fi
  color_echo yellow "[PHP] Eliminare $pkg_name și extensii: $extensions"
  local ext_pkgs=""
  for ext in $extensions; do
    ext_pkgs+=" ${pkg_name}-$ext"
  done
  sudo apt-get remove -y "$pkg_name" $ext_pkgs
}

# Listează versiunile PHP instalate
list_installed_php_versions() {
  local versions=()
  for v in "${PHP_VERSIONS[@]}"; do
    if command -v php$v >/dev/null 2>&1 || (command -v php >/dev/null 2>&1 && php -v 2>/dev/null | grep -q "$v"); then
      versions+=("$v")
    fi
  done
  echo "${versions[@]}"
}

# Listează versiunile PHP disponibile pentru instalare (dar neinstalate)
list_available_php_versions() {
  local available=()
  for v in "${PHP_VERSIONS[@]}"; do
    if ! command -v php$v >/dev/null 2>&1 && ! (command -v php >/dev/null 2>&1 && php -v 2>/dev/null | grep -q "$v"); then
      available+=("$v")
    fi
  done
  echo "${available[@]}"
}
