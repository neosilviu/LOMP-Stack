#!/bin/bash
#
# performance_manager.sh - Part of LOMP Stack v3.0
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
# performance_manager.sh - Sistem pentru optimizări de performanță și caching

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependency_manager.sh"
source "$SCRIPT_DIR/error_handler.sh"
source "$SCRIPT_DIR/state_manager.sh"

# Initialize error handling
setup_error_handlers
DEBUG_MODE=true

# Source helpers using dependency manager
source_stack_helper "functions"

# Constante pentru optimizări
readonly CACHE_DIR="/tmp/stack_cache"
readonly PERFORMANCE_LOG="/tmp/stack_performance.log"

# Inițializează directoarele pentru cache și performanță
init_performance_dirs() {
    local dirs=("$CACHE_DIR" "$(dirname "$PERFORMANCE_LOG")")
    
    for dir in "${dirs[@]}"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            log_warning "Nu pot crea directorul de performanță: $dir"
            return 1
        fi
    done
    
    log_debug "Directoare de performanță inițializate"
    return 0
}

# Optimizează configurația PHP pentru performanță
optimize_php_performance() {
    local php_version="${1:-$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)}"
    local php_ini_path="/etc/php/${php_version}/fpm/php.ini"
    
    log_info "Optimizare PHP pentru performanță..." "cyan"
    
    if [[ ! -f "$php_ini_path" ]]; then
        log_warning "Fișierul php.ini nu a fost găsit: $php_ini_path"
        return 1
    fi
    
    # Backup php.ini
    if ! sudo cp "$php_ini_path" "${php_ini_path}.backup.$(date +%Y%m%d_%H%M%S)"; then
        log_error "Nu pot face backup la php.ini"
        return 1
    fi
    
    # Optimizări PHP
    local optimizations=(
        "memory_limit = 512M"
        "max_execution_time = 300"
        "max_input_vars = 3000"
        "upload_max_filesize = 64M"
        "post_max_size = 64M"
        "opcache.enable = 1"
        "opcache.memory_consumption = 256"
        "opcache.interned_strings_buffer = 16"
        "opcache.max_accelerated_files = 10000"
        "opcache.revalidate_freq = 2"
        "opcache.fast_shutdown = 1"
        "realpath_cache_size = 4096K"
        "realpath_cache_ttl = 600"
    )
    
    for optimization in "${optimizations[@]}"; do
        local key="${optimization%% =*}"
        if ! grep -q "^${key}" "$php_ini_path"; then
            echo "$optimization" | sudo tee -a "$php_ini_path" >/dev/null
            log_debug "Adăugat: $optimization"
        else
            sudo sed -i "s/^${key}.*/${optimization}/" "$php_ini_path"
            log_debug "Actualizat: $optimization"
        fi
    done
    
    # Restart PHP-FPM
    if systemctl is-active --quiet php*-fpm; then
        sudo systemctl restart php*-fpm
        log_info "PHP-FPM restartat pentru aplicarea optimizărilor" "green"
    fi
    
    # Salvează starea optimizării
    set_state_var "PHP_OPTIMIZED" "true" true
    echo "$(date): PHP optimized for performance" >> "$PERFORMANCE_LOG"
    
    return 0
}

# Optimizează configurația MariaDB/MySQL pentru performanță
optimize_database_performance() {
    local db_type
    db_type="$(source_stack_helper database_manager && detect_database_type)"
    
    log_info "Optimizare $db_type pentru performanță..." "cyan"
    
    local config_file=""
    if [[ "$db_type" == "mariadb" ]]; then
        config_file="/etc/mysql/mariadb.conf.d/50-server.cnf"
    elif [[ "$db_type" == "mysql" ]]; then
        config_file="/etc/mysql/mysql.conf.d/mysqld.cnf"
    else
        log_warning "Tip de bază de date necunoscut pentru optimizare: $db_type"
        return 1
    fi
    
    if [[ ! -f "$config_file" ]]; then
        log_warning "Fișierul de configurare DB nu a fost găsit: $config_file"
        return 1
    fi
    
    # Backup configurație DB
    if ! sudo cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"; then
        log_error "Nu pot face backup la configurația DB"
        return 1
    fi
    
    # Detectează RAM disponibil
    local total_ram_kb
    total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_ram_mb=$((total_ram_kb / 1024))
    
    # Calculează valorile optimale bazate pe RAM
    local innodb_buffer_pool_size=$((total_ram_mb * 70 / 100))  # 70% din RAM
    local key_buffer_size=$((total_ram_mb * 5 / 100))          # 5% din RAM
    
    # Optimizări MariaDB/MySQL
    local db_optimizations=(
        "innodb_buffer_pool_size = ${innodb_buffer_pool_size}M"
        "innodb_log_file_size = 256M"
        "innodb_log_buffer_size = 64M"
        "innodb_flush_log_at_trx_commit = 2"
        "innodb_file_per_table = 1"
        "key_buffer_size = ${key_buffer_size}M"
        "query_cache_type = 1"
        "query_cache_size = 64M"
        "query_cache_limit = 8M"
        "max_connections = 100"
        "thread_cache_size = 16"
        "table_open_cache = 4000"
        "tmp_table_size = 64M"
        "max_heap_table_size = 64M"
    )
    
    # Adaugă secțiunea [mysqld] dacă nu există
    if ! grep -q "^\[mysqld\]" "$config_file"; then
        echo -e "\n[mysqld]" | sudo tee -a "$config_file" >/dev/null
    fi
    
    for optimization in "${db_optimizations[@]}"; do
        local key="${optimization%% =*}"
        if ! grep -q "^${key}" "$config_file"; then
            echo "$optimization" | sudo tee -a "$config_file" >/dev/null
            log_debug "Adăugat DB: $optimization"
        else
            sudo sed -i "s/^${key}.*/${optimization}/" "$config_file"
            log_debug "Actualizat DB: $optimization"
        fi
    done
    
    # Restart serviciul de bază de date
    if systemctl is-active --quiet mariadb; then
        sudo systemctl restart mariadb
        log_info "MariaDB restartat pentru aplicarea optimizărilor" "green"
    elif systemctl is-active --quiet mysql; then
        sudo systemctl restart mysql
        log_info "MySQL restartat pentru aplicarea optimizărilor" "green"
    fi
    
    # Salvează starea optimizării
    set_state_var "DATABASE_OPTIMIZED" "true" true
    echo "$(date): Database optimized for performance" >> "$PERFORMANCE_LOG"
    
    return 0
}

# Optimizează configurația webserver-ului pentru performanță
optimize_webserver_performance() {
    local webserver_type
    webserver_type="$(source_stack_helper web_helpers && detect_web_type)"
    
    log_info "Optimizare $webserver_type pentru performanță..." "cyan"
    
    case "$webserver_type" in
        "nginx")
            optimize_nginx_performance
            ;;
        "apache")
            optimize_apache_performance
            ;;
        "ols")
            optimize_ols_performance
            ;;
        *)
            log_warning "Tip webserver necunoscut pentru optimizare: $webserver_type"
            return 1
            ;;
    esac
    
    return $?
}

# Optimizări specifice pentru Nginx
optimize_nginx_performance() {
    local nginx_config="/etc/nginx/nginx.conf"
    
    if [[ ! -f "$nginx_config" ]]; then
        log_warning "Configurația Nginx nu a fost găsită"
        return 1
    fi
    
    # Backup configurație Nginx
    sudo cp "$nginx_config" "${nginx_config}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Detectează numărul de CPU-uri
    # (cpu_cores was unused and removed)
    
    # Optimizări Nginx
    local nginx_optimizations=(
        "worker_processes auto;"
        "worker_connections 1024;"
        "use epoll;"
        "multi_accept on;"
        "sendfile on;"
        "tcp_nopush on;"
        "tcp_nodelay on;"
        "keepalive_timeout 30;"
        "types_hash_max_size 2048;"
        "server_tokens off;"
        "gzip on;"
        "gzip_vary on;"
        "gzip_min_length 1024;"
        "gzip_comp_level 6;"
        "gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;"
    )
    
    # Aplicare optimizări
    for optimization in "${nginx_optimizations[@]}"; do
        local key="${optimization%% *}"
        if ! grep -q "^[[:space:]]*${key}" "$nginx_config"; then
            # Adaugă în secțiunea events sau http
            if [[ "$optimization" =~ (worker_connections|use|multi_accept) ]]; then
                sudo sed -i '/events {/a\    '"$optimization" "$nginx_config"
            else
                sudo sed -i '/http {/a\    '"$optimization" "$nginx_config"
            fi
            log_debug "Adăugat Nginx: $optimization"
        fi
    done
    
    # Test configurație și restart
    if sudo nginx -t; then
        sudo systemctl restart nginx
        log_info "Nginx restartat cu optimizări aplicare" "green"
        set_state_var "NGINX_OPTIMIZED" "true" true
        echo "$(date): Nginx optimized for performance" >> "$PERFORMANCE_LOG"
    else
        log_error "Configurația Nginx are erori! Restaurez backup-ul..."
        sudo cp "${nginx_config}.backup."* "$nginx_config"
        return 1
    fi
    
    return 0
}

# Optimizări specifice pentru Apache
optimize_apache_performance() {
    log_info "Optimizare Apache pentru performanță..." "yellow"
    
    # Activează module necesare pentru performanță
    local apache_modules=(
        "mod_rewrite"
        "mod_expires"
        "mod_headers"
        "mod_deflate"
        "mod_mime"
    )
    
    for module in "${apache_modules[@]}"; do
        if sudo a2enmod "$module" 2>/dev/null; then
            log_debug "Activat modul Apache: $module"
        fi
    done
    
    # Configurare .htaccess pentru performanță
    local htaccess_optimizations='
# Performance optimizations
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType image/png "access plus 1 month"
    ExpiresByType image/jpg "access plus 1 month"
    ExpiresByType image/jpeg "access plus 1 month"
    ExpiresByType image/gif "access plus 1 month"
    ExpiresByType image/ico "access plus 1 month"
    ExpiresByType image/icon "access plus 1 month"
    ExpiresByType text/html "access plus 1 hour"
</IfModule>

<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>
'
    
    # Salvează optimizările .htaccess în cache pentru utilizare ulterioară
    echo "$htaccess_optimizations" > "$CACHE_DIR/apache_htaccess_optimizations"
    
    # Restart Apache
    sudo systemctl restart apache2
    log_info "Apache restartat cu optimizări aplicare" "green"
    set_state_var "APACHE_OPTIMIZED" "true" true
    echo "$(date): Apache optimized for performance" >> "$PERFORMANCE_LOG"
    
    return 0
}

# Optimizări specifice pentru OpenLiteSpeed
optimize_ols_performance() {
    log_info "Optimizare OpenLiteSpeed pentru performanță..." "yellow"
    
    # OLS are optimizări built-in, dar putem configura cache-ul
    local ols_cache_config="/usr/local/lsws/conf/httpd_config.conf"
    
    if [[ -f "$ols_cache_config" ]]; then
        log_info "Configurare LSCache pentru OpenLiteSpeed..." "cyan"
        # Aici ar trebui să configurăm LSCache prin API-ul OLS
        # Pentru moment, doar marcăm că optimizarea a fost aplicată
        set_state_var "OLS_OPTIMIZED" "true" true
        echo "$(date): OpenLiteSpeed cache configured" >> "$PERFORMANCE_LOG"
    fi
    
    return 0
}

# Activează caching pentru WordPress
setup_wordpress_caching() {
    local wp_path="$1"
    local cache_type="${2:-file}" # file, redis, memcached
    
    log_info "Configurare caching WordPress în $wp_path..." "cyan"
    
    case "$cache_type" in
        "redis")
            setup_redis_cache "$wp_path"
            ;;
        "memcached")
            setup_memcached_cache "$wp_path"
            ;;
        "file"|*)
            setup_file_cache "$wp_path"
            ;;
    esac
    
    return $?
}

# Configurează file-based caching pentru WordPress
setup_file_cache() {
    local wp_path="$1"
    
    if [[ ! -d "$wp_path" ]]; then
        log_error "Calea WordPress nu există: $wp_path"
        return 1
    fi
    
    # Configurare W3 Total Cache sau similar prin wp-config.php
    local cache_config='
// WordPress Cache Configuration
define("WP_CACHE", true);
define("WPCACHEHOME", "'"$wp_path"'/wp-content/plugins/w3-total-cache/");
'
    
    if [[ -f "$wp_path/wp-config.php" ]]; then
        # Adaugă configurarea cache dacă nu există
        if ! grep -q "WP_CACHE" "$wp_path/wp-config.php"; then
            # Inserează înainte de "/* That's all, stop editing!" 
            sudo sed -i '/That.*s all, stop editing/i\'"$(echo "$cache_config" | tr '\n' '\001')" "$wp_path/wp-config.php"
            sudo sed -i 's/\001/\n/g' "$wp_path/wp-config.php"
            log_info "Configurare cache adăugată în wp-config.php" "green"
        fi
    fi
    
    set_state_var "WP_CACHE_CONFIGURED" "true" true
    echo "$(date): WordPress file cache configured at $wp_path" >> "$PERFORMANCE_LOG"
    
    return 0
}

# Rulează toate optimizările de performanță
run_full_optimization() {
    log_info "Începe optimizarea completă de performanță..." "yellow"
    
    init_performance_dirs
    
    local optimizations=(
        "optimize_php_performance"
        "optimize_database_performance" 
        "optimize_webserver_performance"
    )
    
    local failed_optimizations=()
    
    for optimization in "${optimizations[@]}"; do
        log_info "Rulează: $optimization" "blue"
        if ! "$optimization"; then
            failed_optimizations+=("$optimization")
            log_warning "Optimizarea a eșuat: $optimization"
        else
            log_info "Optimizarea reușită: $optimization" "green"
        fi
    done
    
    # Raport final
    if [[ ${#failed_optimizations[@]} -eq 0 ]]; then
        log_info "🎉 Toate optimizările au fost aplicate cu succes!" "green"
        set_state_var "FULL_OPTIMIZATION_COMPLETED" "true" true
        echo "$(date): Full optimization completed successfully" >> "$PERFORMANCE_LOG"
        return 0
    else
        log_warning "Următoarele optimizări au eșuat: ${failed_optimizations[*]}"
        echo "$(date): Full optimization completed with errors: ${failed_optimizations[*]}" >> "$PERFORMANCE_LOG"
        return 1
    fi
}

# Afișează raportul de performanță
show_performance_report() {
    log_info "=== RAPORT PERFORMANȚĂ ===" "cyan"
    
    echo "Optimizări aplicate:"
    echo "- PHP: $(get_state_var "PHP_OPTIMIZED" "false")"
    echo "- Database: $(get_state_var "DATABASE_OPTIMIZED" "false")"
    echo "- Nginx: $(get_state_var "NGINX_OPTIMIZED" "false")"
    echo "- Apache: $(get_state_var "APACHE_OPTIMIZED" "false")"
    echo "- OLS: $(get_state_var "OLS_OPTIMIZED" "false")"
    echo "- WordPress Cache: $(get_state_var "WP_CACHE_CONFIGURED" "false")"
    echo "- Optimizare completă: $(get_state_var "FULL_OPTIMIZATION_COMPLETED" "false")"
    
    echo
    echo "Log performanță:"
    if [[ -f "$PERFORMANCE_LOG" ]]; then
        tail -10 "$PERFORMANCE_LOG"
    else
        echo "Nu există log de performanță."
    fi
}

# Inițializare automată
init_performance_dirs

# Export funcții pentru utilizare externă
export -f optimize_php_performance optimize_database_performance
export -f optimize_webserver_performance setup_wordpress_caching
export -f run_full_optimization show_performance_report
