#!/bin/bash
#
# user_domain_helpers.sh - Part of LOMP Stack v3.0
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
# user_domain_helpers.sh - Funcții reutilizabile pentru izolare user, domeniu, pool, DB, vhost, config

# Creează user izolat
create_isolated_user() {
  local username="$1"
  sudo adduser --disabled-password --gecos "" "$username"
  sudo usermod -aG www-data "$username"
  sudo usermod -s /usr/sbin/nologin "$username"
  sudo usermod -L "$username"
  sudo passwd -l "$username"
  sudo chown root:root "/home/$username"
  sudo chmod 750 "/home/$username"
  sudo chmod 700 "/home/$username/.bash*" 2>/dev/null || true
}

# Creează root web izolat
create_isolated_webroot() {
  local username="$1" webroot="$2"
  sudo mkdir -p "$webroot"
  sudo chown -R "$username":www-data "$webroot"
  sudo chmod -R 750 "$webroot"
}

# Creează pool PHP-FPM izolat
create_php_fpm_pool() {
  local username="$1"
  local phpver
  phpver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
  local poolconf="/etc/php/$phpver/fpm/pool.d/$username.conf"
  sudo tee "$poolconf" > /dev/null <<EOF
[$username]
user = $username
group = www-data
listen = /run/php/php-fpm-$username.sock
listen.owner = $username
listen.group = www-data
pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s;
chdir = /
php_admin_value[open_basedir] = /home/$username:/tmp
EOF
  sudo systemctl reload php$phpver-fpm
}

# Creează vhost Nginx izolat
create_nginx_vhost() {
  local username="$1" domain="$2" webroot="$3"
  local realpath_root
  realpath_root=$(realpath "$webroot")
  # Dacă există tunel Cloudflare, nu asculta pe 443 și nu face redirect HTTPS
  if [[ "$STACK_CF_TUNNEL" == "1" ]]; then
    sudo tee /etc/nginx/sites-available/$domain > /dev/null <<EOF
server {
    listen 80;
    server_name $domain www.$domain *.$domain;
    root $webroot;
    index index.php index.html index.htm;
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm-$username.sock;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        fastcgi_param SCRIPT_FILENAME $realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF
  else
    sudo tee /etc/nginx/sites-available/$domain > /dev/null <<EOF
server {
    listen 80;
    server_name $domain www.$domain *.$domain;
    root $webroot;
    index index.php index.html index.htm;
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    # Redirect HTTP to HTTPS if cert exists
    if (-f /etc/letsencrypt/live/$domain/fullchain.pem) {
        return 301 https://\$host\$request_uri;
    }
    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm-$username.sock;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        fastcgi_param SCRIPT_FILENAME $realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
}
EOF
  fi
  sudo ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain
  sudo nginx -t && sudo systemctl reload nginx
}

# Creează vhost OLS izolat
create_ols_vhost() {
  local username="$1" domain="$2" webroot="$3"
  vhostconf="/usr/local/lsws/conf/vhosts/$domain/vhconf.conf"
  sudo mkdir -p "/usr/local/lsws/conf/vhosts/$domain"
  if [[ "$STACK_CF_TUNNEL" == "1" ]]; then
    sudo tee "$vhostconf" > /dev/null <<EOF
docRoot                   $webroot/
vhDomain                  $domain
vhAliases                 www.$domain *.$domain
adminEmails               admin@$domain
index  {
EOF
    # Nu adăugăm secțiuni SSL sau HSTS pentru tunel
    sudo /usr/local/lsws/bin/lswsctrl restart
    return
  fi
  sudo tee "$vhostconf" > /dev/null <<EOF
docRoot                   $webroot/
vhDomain                  $domain
vhAliases                 www.$domain *.$domain
adminEmails               admin@$domain
index  {
  useServer               0
  indexFiles              index.php, index.html
}
scriptHandler  {
  add                     lsapi:$username index.php
}
extProcessor $username {
  type                    lsapi
  address                 uds://tmp/lshttpd/$username.sock
  maxConns                10
  env                     PHP_LSAPI_CHILDREN=10
  initTimeout             60
  retryTimeout            0
  persistConn             1
  respBuffer              0
  autoStart               1
  path                    /usr/bin/lsphp
  backlog                 100
  instances               1
  priority                0
  memSoftLimit            512M
  memHardLimit            1024M
  procSoftLimit           50
  procHardLimit           60
  runOnStartUp            1
  user                    $username
  group                   www-data
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

# Creează DB MySQL/MariaDB izolată
create_isolated_db() {
  local dbname="$1" dbuser="$2" dbpass="$3"
  # Debug suplimentar: verifică dacă baza de date și userul există și are permisiuni
  color_echo cyan "[DEBUG] Verific existența bazei de date $dbname și permisiunile userului $dbuser..."
  if sudo mysql -e "SHOW DATABASES LIKE '$dbname';" | grep -q "$dbname"; then
    color_echo green "[OK] Baza de date $dbname există."
  else
    color_echo red "[EROARE] Baza de date $dbname NU există!"
  fi
  if sudo mysql -e "SELECT User, Host FROM mysql.user WHERE User='$dbuser';" | grep -q "$dbuser"; then
    color_echo green "[OK] Userul $dbuser există."
    color_echo cyan "[DEBUG] Permisiuni user $dbuser:"
    sudo mysql -e "SHOW GRANTS FOR '$dbuser'@'localhost';"
  else
    color_echo red "[EROARE] Userul $dbuser NU există!"
  fi
  sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`$dbname\`;"
  sudo mysql -e "CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
  sudo mysql -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '$dbuser'@'localhost';"
  sudo mysql -e "GRANT USAGE ON *.* TO '$dbuser'@'localhost';"
  sudo mysql -e "GRANT ALL PRIVILEGES ON \`$dbname\`.* TO '$dbuser'@'localhost';"
  sudo mysql -e "FLUSH PRIVILEGES;"
}

# Creează vhost Apache izolat
create_apache_vhost() {
  local username="$1" domain="$2" webroot="$3"
  local conf_file="/etc/apache2/sites-available/${domain}.conf"
  if [[ "$STACK_CF_TUNNEL" == "1" ]]; then
    sudo tee "$conf_file" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain *.$domain
    DocumentRoot $webroot
    ServerAdmin admin@$domain
    <Directory $webroot>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/apache2/${domain}_error.log
    CustomLog /var/log/apache2/${domain}_access.log combined
    # Security headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set X-XSS-Protection "1; mode=block"
    <IfModule mpm_itk_module>
        AssignUserID $username www-data
    </IfModule>
</VirtualHost>
EOF
  else
    sudo tee "$conf_file" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain *.$domain
    DocumentRoot $webroot
    ServerAdmin admin@$domain
    <Directory $webroot>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/apache2/${domain}_error.log
    CustomLog /var/log/apache2/${domain}_access.log combined
    # Security headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    <IfModule mpm_itk_module>
        AssignUserID $username www-data
    </IfModule>
</VirtualHost>
EOF
  fi
  sudo a2ensite "${domain}.conf"
  sudo systemctl reload apache2
}

# Creează folder de backup izolat pentru user
create_user_backup_dir() {
  local username="$1"
  local backup_dir="/home/$username/backup"
  sudo mkdir -p "$backup_dir"
  sudo chown -R "$username":www-data "$backup_dir"
  sudo chmod 750 "$backup_dir"
}
