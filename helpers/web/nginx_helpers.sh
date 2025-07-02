#!/bin/bash
#
# nginx_helpers.sh - Part of LOMP Stack v3.0
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
# nginx_helpers.sh - Helper pentru instalare și configurare Nginx + PHP pentru WordPress

# Instalează Nginx (ultima stabilă)
install_nginx_latest() {
  color_echo yellow "[NGINX] Instalare Nginx..."
  sudo apt install -y nginx
}

# Instalează PHP (ultima stabilă) cu extensii WordPress
install_php_wordpress() {
  color_echo yellow "[NGINX] Instalare PHP + extensii WordPress..."
  sudo apt install -y php php-fpm php-mysql php-xml php-curl php-gd php-mbstring php-zip php-bcmath php-imagick php-intl php-soap php-redis
}

# Configurează Nginx pentru WordPress
configure_nginx_wordpress() {
  color_echo yellow "[NGINX] Configurare vhost WordPress..."
  sudo tee /etc/nginx/sites-available/wordpress <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        # Folosește automat sock-ul versiunii PHP-FPM instalate
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }
}
EOF
  sudo ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress
  sudo rm -f /etc/nginx/sites-enabled/default
  sudo nginx -t && sudo systemctl reload nginx
}

# Optimizări PHP ini pentru WordPress
optimize_php_ini_wordpress() {
  color_echo yellow "[NGINX] Optimizare PHP ini pentru WordPress..."
  PHP_INI="/etc/php/*/fpm/php.ini"
  sudo sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^post_max_size.*/post_max_size = 64M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^memory_limit.*/memory_limit = 256M/' $PHP_INI 2>/dev/null || true
  sudo sed -i 's/^max_execution_time.*/max_execution_time = 120/' $PHP_INI 2>/dev/null || true
  sudo systemctl restart php*-fpm
}
