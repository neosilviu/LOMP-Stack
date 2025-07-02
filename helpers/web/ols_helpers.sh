#!/bin/bash
#
# ols_helpers.sh - Part of LOMP Stack v3.0
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
# ols_helpers.sh - Helper pentru instalare și configurare OpenLiteSpeed + lsphp pentru WordPress

# Setează parola admin OLS și o salvează într-un fișier info
set_ols_admin_password() {
  local admin_user="admin"
  local admin_pass
  admin_pass=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
  echo -e "$admin_user\n$admin_pass\n$admin_pass" | sudo /usr/local/lsws/admin/misc/admpass.sh >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    color_echo green "[OK] Parola admin OLS a fost setată."
    # Salvează parola într-un fișier info pentru raportare
    echo "OLS_ADMIN_USER=$admin_user" | sudo tee /etc/ols_admin_info >/dev/null
    echo "OLS_ADMIN_PASS=$admin_pass" | sudo tee -a /etc/ols_admin_info >/dev/null
    sudo chmod 600 /etc/ols_admin_info
  else
    color_echo red "[EROARE] Nu am putut seta parola admin OLS!"
  fi
}
#!/bin/bash
# ols_helpers.sh - Helper pentru instalare și configurare OpenLiteSpeed + lsphp pentru WordPress

# Instalează OpenLiteSpeed (ultima stabilă)
install_ols_latest() {
  color_echo yellow "[OLS] Instalare OpenLiteSpeed..."
  wget -O - https://repo.litespeed.sh | sudo bash
  sudo apt install -y openlitespeed
}

# Configurează vhost OLS pentru WordPress
configure_ols_vhost_wordpress() {
  local user="$1"
  local domain="$2"
  color_echo yellow "[OLS] Configurare vhost WordPress pentru $user/$domain..."
  sudo mkdir -p /usr/local/lsws/conf/vhosts/$domain
  cat <<EOF | sudo tee /usr/local/lsws/conf/vhosts/$domain/vhconf.conf
  docRoot                   /home/$user/www/$domain
  vhDomain                  $domain
  vhAliases                 *
  adminEmails               admin@$domain

  index  {
    useServer               0
    indexFiles              index.php, index.html
  }

  errorlog /usr/local/lsws/logs/${domain}_error.log {
    useServer               0
    logLevel                WARN
    rollingSize             10M
  }

  accesslog /usr/local/lsws/logs/${domain}_access.log {
    useServer               0
    rollingSize             10M
  }

  scriptHandler  {
    add                     lsapi:lsphp index.php
  }

  extProcessor lsphp {
    type                    lsapi
    address                 uds://tmp/lshttpd/lsphp.sock
    maxConns                35
    env                     PHP_LSAPI_CHILDREN=35
    initTimeout             60
    retryTimeout            0
    persistConn             1
    respBuffer              0
    autoStart               1
    path                    /usr/bin/lsphp
    backlog                 100
    instances               1
    priority                0
    memSoftLimit            2047M
    memHardLimit            2047M
    procSoftLimit           400
    procHardLimit           500
  }

  rewrite  {
    enable                  1
    autoLoadHtaccess        1
  }

  vhssl  {
    enable                  0
  }
EOF
  sudo /usr/local/lsws/bin/lswsctrl restart
}

# Optimizări PHP ini pentru WordPress
optimize_lsphp_ini_wordpress() {
  local user="$1"
  local domain="$2"
  color_echo yellow "[OLS] Optimizare lsphp ini pentru WordPress ($user/$domain)..."
  PHP_INI="/usr/local/lsws/lsphp*/etc/php.ini"
  sudo sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^post_max_size.*/post_max_size = 64M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^memory_limit.*/memory_limit = 256M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^max_execution_time.*/max_execution_time = 120/' $PHP_INI 2>/dev/null || true
  sudo /usr/local/lsws/bin/lswsctrl restart
}
