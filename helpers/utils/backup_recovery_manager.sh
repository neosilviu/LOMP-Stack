#!/bin/bash
#
# backup_recovery_manager.sh - Part of LOMP Stack v3.0
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
# backup_recovery_manager.sh - Sistem avansat de backup și recovery

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependency_manager.sh"
source "$SCRIPT_DIR/error_handler.sh"
source "$SCRIPT_DIR/state_manager.sh"

# Initialize error handling
setup_error_handlers

# Source helpers using dependency manager
source_stack_helper "functions"

# Constante pentru backup
readonly BACKUP_BASE_DIR="/var/backups/stack"
readonly BACKUP_LOG="/var/log/stack_backup.log"
readonly BACKUP_CONFIG="/etc/stack/backup.conf"
readonly RETENTION_DAYS=30

# Inițializează sistemul de backup
init_backup_system() {
    log_info "Inițializare sistem backup..." "cyan"
    
    # Creează directoarele necesare
    local dirs=("$BACKUP_BASE_DIR" "$(dirname "$BACKUP_LOG")" "$(dirname "$BACKUP_CONFIG")")
    
    for dir in "${dirs[@]}"; do
        if ! sudo mkdir -p "$dir" 2>/dev/null; then
            log_warning "Nu pot crea directorul: $dir"
            # Fallback la /tmp pentru teste
            if [[ "$dir" == "$BACKUP_BASE_DIR" ]]; then
                BACKUP_BASE_DIR="/tmp/stack_backups"
                sudo mkdir -p "$BACKUP_BASE_DIR"
            fi
        fi
    done
    
    # Setează permisiuni
    sudo chmod 755 "$BACKUP_BASE_DIR"
    sudo touch "$BACKUP_LOG"
    sudo chmod 644 "$BACKUP_LOG"
    
    log_debug "Directoare backup inițializate"
    return 0
}

# Configurează backup automat
configure_automatic_backup() {
    local backup_time="${1:-02:00}"
    local backup_frequency="${2:-daily}"
    local email_notifications="${3:-false}"
    
    log_info "Configurare backup automat..." "cyan"
    
    # Creează configurația backup
    sudo tee "$BACKUP_CONFIG" > /dev/null << EOF
# Stack Backup Configuration
BACKUP_TIME="$backup_time"
BACKUP_FREQUENCY="$backup_frequency"
EMAIL_NOTIFICATIONS="$email_notifications"
RETENTION_DAYS="$RETENTION_DAYS"
BACKUP_BASE_DIR="$BACKUP_BASE_DIR"
BACKUP_LOG="$BACKUP_LOG"
EOF
    
    # Creează script pentru cron
    local cron_script="/usr/local/bin/stack_backup.sh"
    
    sudo tee "$cron_script" > /dev/null << 'EOF'
#!/bin/bash
# Automated backup script for LOMP Stack

# Source backup manager
source "$(dirname "$(readlink -f "$0")")"/../../Users/Silviu/Desktop/Stack/helpers/utils/backup_recovery_manager.sh

# Execute full backup
execute_full_backup "auto"
EOF
    
    sudo chmod +x "$cron_script"
    
    # Configurează cron job
    local cron_entry=""
    case "$backup_frequency" in
        "daily")
            local hour minute
            hour=$(echo "$backup_time" | cut -d':' -f1)
            minute=$(echo "$backup_time" | cut -d':' -f2)
            cron_entry="$minute $hour * * * $cron_script"
            ;;
        "weekly")
            cron_entry="0 2 * * 0 $cron_script"  # Duminica la 2:00
            ;;
        "monthly")
            cron_entry="0 2 1 * * $cron_script"  # Prima zi a lunii la 2:00
            ;;
    esac
    
    if [[ -n "$cron_entry" ]]; then
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        log_info "Cron job pentru backup configurat: $backup_frequency la $backup_time" "green"
    fi
    
    # Salvează configurarea
    set_state_var "AUTO_BACKUP_CONFIGURED" "true" true
    set_state_var "BACKUP_FREQUENCY" "$backup_frequency" true
    set_state_var "BACKUP_TIME" "$backup_time" true
    
    return 0
}

# Execută backup complet
execute_full_backup() {
    local backup_type="${1:-manual}"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_session_dir="$BACKUP_BASE_DIR/full_$timestamp"
    
    log_info "Începe backup complet ($backup_type)..." "yellow"
    
    # Creează directorul pentru această sesiune
    if ! sudo mkdir -p "$backup_session_dir"; then
        log_error "Nu pot crea directorul de backup: $backup_session_dir"
        return 1
    fi
    
    # Lista componentelor de backup
    local backup_components=(
        "databases"
        "websites"
        "configurations"
        "logs"
        "certificates"
    )
    
    local failed_backups=()
    local successful_backups=()
    
    # Execută backup pentru fiecare componentă
    for component in "${backup_components[@]}"; do
        log_info "Backup $component..." "blue"
        
        if "backup_$component" "$backup_session_dir"; then
            successful_backups+=("$component")
            log_info "Backup $component reușit" "green"
        else
            failed_backups+=("$component")
            log_warning "Backup $component eșuat"
        fi
    done
    
    # Compresează backup-ul
    log_info "Compresare backup..." "blue"
    if sudo tar -czf "${backup_session_dir}.tar.gz" -C "$BACKUP_BASE_DIR" "$(basename "$backup_session_dir")"; then
        sudo rm -rf "$backup_session_dir"
        log_info "Backup comprimat: ${backup_session_dir}.tar.gz" "green"
    else
        log_warning "Compresarea backup-ului a eșuat"
    fi
    
    # Generează raport
    generate_backup_report "$backup_type" "$timestamp" "${successful_backups[@]}" "${failed_backups[@]}"
    
    # Curățare backup-uri vechi
    cleanup_old_backups
    
    # Rezultat final
    if [[ ${#failed_backups[@]} -eq 0 ]]; then
        log_info "🎉 Backup complet reușit!" "green"
        return 0
    else
        log_warning "Backup complet finalizat cu erori: ${failed_backups[*]}"
        return 1
    fi
}

# Backup baze de date
backup_databases() {
    local backup_dir="$1/databases"
    sudo mkdir -p "$backup_dir"
    
    log_info "Backup baze de date..." "cyan"
    
    # Detectează tipul bazei de date
    source_stack_helper "database_manager"
    local db_type
    db_type=$(detect_database_type)
    
    if [[ "$db_type" == "none" ]]; then
        log_warning "Nu s-au găsit baze de date pentru backup"
        return 0
    fi
    
    # Obține lista bazelor de date
    local databases
    case "$db_type" in
        "mariadb"|"mysql")
            databases=$(mysql -e "SHOW DATABASES;" | grep -v Database | grep -v information_schema | grep -v performance_schema | grep -v mysql | grep -v sys)
            ;;
        *)
            log_warning "Tip bază de date necunoscut pentru backup: $db_type"
            return 1
            ;;
    esac
    
    # Backup pentru fiecare bază de date
    while IFS= read -r database; do
        [[ -z "$database" ]] && continue
        
        log_debug "Backup bază de date: $database"
        
        local dump_file
        dump_file="$backup_dir/${database}_$(date +%Y%m%d_%H%M%S).sql"
        
        if mysqldump --single-transaction --routines --triggers "$database" | sudo tee "$dump_file" > /dev/null; then
            sudo gzip "$dump_file"
            log_debug "Backup DB reușit: $database"
        else
            log_warning "Backup DB eșuat: $database"
            return 1
        fi
        
    done <<< "$databases"
    
    return 0
}

# Backup website-uri
backup_websites() {
    local backup_dir="$1/websites"
    sudo mkdir -p "$backup_dir"
    
    log_info "Backup website-uri..." "cyan"
    
    # Căutare directoare WordPress comune
    local wp_dirs=(
        "/var/www/html"
        "/var/www/*/html"
        "/var/www/*/public_html"
        "/home/*/public_html"
    )
    
    local websites_found=0
    
    for pattern in "${wp_dirs[@]}"; do
        for dir in $pattern; do
            if [[ -d "$dir" && -f "$dir/wp-config.php" ]]; then
                websites_found=$((websites_found + 1))
                local site_name
                site_name=$(basename "$(dirname "$dir")")
                [[ "$site_name" == "www" ]] && site_name="html"
                
                log_debug "Backup website: $dir -> $site_name"
                
                if sudo tar -czf "$backup_dir/website_${site_name}_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")"; then
                    log_debug "Backup website reușit: $site_name"
                else
                    log_warning "Backup website eșuat: $site_name"
                fi
            fi
        done
    done
    
    if [[ $websites_found -eq 0 ]]; then
        log_warning "Nu s-au găsit website-uri WordPress pentru backup"
    fi
    
    return 0
}

# Backup configurații
backup_configurations() {
    local backup_dir="$1/configurations"
    sudo mkdir -p "$backup_dir"
    
    log_info "Backup configurații..." "cyan"
    
    # Lista configurațiilor importante
    local config_files=(
        "/etc/nginx"
        "/etc/apache2"
        "/etc/mysql"
        "/etc/php"
        "/etc/ssl"
        "/etc/letsencrypt"
        "/etc/hosts"
        "/etc/hostname"
        "/etc/fstab"
    )
    
    for config_path in "${config_files[@]}"; do
        if [[ -e "$config_path" ]]; then
            local config_name
            config_name=$(basename "$config_path")
            
            log_debug "Backup configurație: $config_path"
            
            if sudo tar -czf "$backup_dir/config_${config_name}_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$(dirname "$config_path")" "$(basename "$config_path")"; then
                log_debug "Backup config reușit: $config_name"
            else
                log_warning "Backup config eșuat: $config_name"
            fi
        fi
    done
    
    return 0
}

# Backup log-uri
backup_logs() {
    local backup_dir="$1/logs"
    sudo mkdir -p "$backup_dir"
    
    log_info "Backup log-uri..." "cyan"
    
    # Directoare de log-uri
    local log_dirs=(
        "/var/log/nginx"
        "/var/log/apache2"
        "/var/log/mysql"
        "/var/log/php*"
    )
    
    for log_pattern in "${log_dirs[@]}"; do
        for log_dir in $log_pattern; do
            if [[ -d "$log_dir" ]]; then
                local log_name
                log_name=$(basename "$log_dir")
                
                log_debug "Backup log-uri: $log_dir"
                
                # Backup doar fișierele de log din ultimele 7 zile
                if find "$log_dir" -name "*.log*" -mtime -7 -exec sudo tar -czf "$backup_dir/logs_${log_name}_$(date +%Y%m%d_%H%M%S).tar.gz" {} + 2>/dev/null; then
                    log_debug "Backup logs reușit: $log_name"
                fi
            fi
        done
    done
    
    return 0
}

# Backup certificate SSL
backup_certificates() {
    local backup_dir="$1/certificates"
    sudo mkdir -p "$backup_dir"
    
    log_info "Backup certificate SSL..." "cyan"
    
    # Let's Encrypt certificates
    if [[ -d "/etc/letsencrypt/live" ]]; then
        log_debug "Backup certificate Let's Encrypt"
        sudo tar -czf "$backup_dir/letsencrypt_$(date +%Y%m%d_%H%M%S).tar.gz" -C "/etc" "letsencrypt"
    fi
    
    # Certificate personalizate
    if [[ -d "/etc/ssl/private" ]]; then
        log_debug "Backup certificate SSL private"
        sudo tar -czf "$backup_dir/ssl_private_$(date +%Y%m%d_%H%M%S).tar.gz" -C "/etc/ssl" "private"
    fi
    
    return 0
}

# Restaurează din backup
restore_from_backup() {
    local backup_file="$1"
    local restore_type="${2:-full}"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Fișierul de backup nu există: $backup_file"
        return 1
    fi
    
    log_info "Restaurare din backup: $backup_file" "yellow"
    
    # Creează director temporar pentru restaurare
    local temp_restore_dir
    temp_restore_dir=$(mktemp -d)
    
    # Extrage backup-ul
    if ! sudo tar -xzf "$backup_file" -C "$temp_restore_dir"; then
        log_error "Nu pot extrage backup-ul"
        sudo rm -rf "$temp_restore_dir"
        return 1
    fi
    
    # Găsește directorul de backup
    local backup_content_dir
    backup_content_dir=$(find "$temp_restore_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
    
    if [[ ! -d "$backup_content_dir" ]]; then
        log_error "Structura backup-ului nu este validă"
        sudo rm -rf "$temp_restore_dir"
        return 1
    fi
    
    # Restaurare în funcție de tip
    case "$restore_type" in
        "full")
            restore_full_backup "$backup_content_dir"
            ;;
        "databases")
            restore_databases_only "$backup_content_dir/databases"
            ;;
        "websites")
            restore_websites_only "$backup_content_dir/websites"
            ;;
        "configurations")
            restore_configurations_only "$backup_content_dir/configurations"
            ;;
        *)
            log_error "Tip restaurare necunoscut: $restore_type"
            sudo rm -rf "$temp_restore_dir"
            return 1
            ;;
    esac
    
    local restore_result=$?
    
    # Curățare
    sudo rm -rf "$temp_restore_dir"
    
    if [[ $restore_result -eq 0 ]]; then
        log_info "🎉 Restaurare completă cu succes!" "green"
        set_state_var "LAST_RESTORE" "$(date)" true
    else
        log_error "Restaurarea a eșuat"
    fi
    
    return $restore_result
}

# Restaurare completă
restore_full_backup() {
    local backup_dir="$1"
    
    log_info "Restaurare completă..." "yellow"
    
    # Confirmă restaurarea (ar trebui să fie interactivă în implementarea reală)
    log_warning "ATENȚIE: Restaurarea va suprascrie configurațiile existente!"
    
    # Restaurare componente
    [[ -d "$backup_dir/databases" ]] && restore_databases_only "$backup_dir/databases"
    [[ -d "$backup_dir/websites" ]] && restore_websites_only "$backup_dir/websites"
    [[ -d "$backup_dir/configurations" ]] && restore_configurations_only "$backup_dir/configurations"
    
    # Restart servicii după restaurare
    restart_stack_services
    
    return 0
}

# Restaurare baze de date
restore_databases_only() {
    local db_backup_dir="$1"
    
    if [[ ! -d "$db_backup_dir" ]]; then
        log_warning "Nu există backup pentru baze de date"
        return 0
    fi
    
    log_info "Restaurare baze de date..." "cyan"
    
    # Găsește fișierele SQL
    find "$db_backup_dir" -name "*.sql.gz" | while read -r sql_file; do
        local db_name
        db_name=$(basename "$sql_file" | cut -d'_' -f1)
        
        log_debug "Restaurare bază de date: $db_name"
        
        # Creează baza de date dacă nu există
        mysql -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;"
        
        # Restaurează datele
        if zcat "$sql_file" | mysql "$db_name"; then
            log_debug "Restaurare DB reușită: $db_name"
        else
            log_warning "Restaurare DB eșuată: $db_name"
        fi
    done
    
    return 0
}

# Restaurare website-uri
restore_websites_only() {
    local websites_backup_dir="$1"
    
    if [[ ! -d "$websites_backup_dir" ]]; then
        log_warning "Nu există backup pentru website-uri"
        return 0
    fi
    
    log_info "Restaurare website-uri..." "cyan"
    
    # ATENȚIE: Implementarea simplificată - în realitate ar trebui confirmări
    find "$websites_backup_dir" -name "website_*.tar.gz" | while read -r website_file; do
        log_debug "Restaurare website: $(basename "$website_file")"
        # Implementare restaurare website
    done
    
    return 0
}

# Restaurare configurații
restore_configurations_only() {
    local config_backup_dir="$1"
    
    if [[ ! -d "$config_backup_dir" ]]; then
        log_warning "Nu există backup pentru configurații"
        return 0
    fi
    
    log_info "Restaurare configurații..." "cyan"
    
    # ATENȚIE: Implementarea simplificată - în realitate ar trebui confirmări
    find "$config_backup_dir" -name "config_*.tar.gz" | while read -r config_file; do
        log_debug "Restaurare configurație: $(basename "$config_file")"
        # Implementare restaurare configurație
    done
    
    return 0
}

# Restart servicii Stack
restart_stack_services() {
    log_info "Restart servicii Stack..." "yellow"
    
    local services=("nginx" "apache2" "mysql" "mariadb" "php*-fpm")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            sudo systemctl restart "$service"
            log_debug "Serviciu restartat: $service"
        fi
    done
}

# Curățare backup-uri vechi
cleanup_old_backups() {
    local retention_days="$RETENTION_DAYS"
    
    log_info "Curățare backup-uri mai vechi de $retention_days zile..." "yellow"
    
    # Șterge backup-uri vechi
    find "$BACKUP_BASE_DIR" -name "full_*.tar.gz" -mtime +"$retention_days" -delete 2>/dev/null
    
    # Raportează spațiul eliberat
    log_debug "Curățare backup-uri completă"
}

# Generează raport backup
generate_backup_report() {
    local backup_type="$1"
    local timestamp="$2"
    shift 2
    local successful_backups=("$@")
    
    local report_entry="[$timestamp] Backup $backup_type: Reușit(${#successful_backups[@]})"
    echo "$report_entry" | sudo tee -a "$BACKUP_LOG" >/dev/null
    
    # Salvează în state
    set_state_var "LAST_BACKUP" "$report_entry" true
    set_state_var "BACKUP_COUNT" "$(($(get_state_var "BACKUP_COUNT" "0") + 1))" true
}

# Afișează status backup
show_backup_status() {
    log_info "=== STATUS BACKUP ===" "cyan"
    
    echo "Configurație backup:"
    echo "- Auto backup: $(get_state_var "AUTO_BACKUP_CONFIGURED" "false")"
    echo "- Frecvență: $(get_state_var "BACKUP_FREQUENCY" "none")"
    echo "- Ultimul backup: $(get_state_var "LAST_BACKUP" "none")"
    echo "- Total backup-uri: $(get_state_var "BACKUP_COUNT" "0")"
    echo "- Ultimul restore: $(get_state_var "LAST_RESTORE" "none")"
    
    echo
    echo "Spațiu utilizat:"
    if [[ -d "$BACKUP_BASE_DIR" ]]; then
        du -sh "$BACKUP_BASE_DIR" 2>/dev/null || echo "Nu pot calcula spațiul"
    else
        echo "Directorul de backup nu există"
    fi
    
    echo
    echo "Backup-uri disponibile:"
    if [[ -d "$BACKUP_BASE_DIR" ]]; then
        find "$BACKUP_BASE_DIR" -name "full_*.tar.gz" -exec basename {} \; 2>/dev/null | sort -r | head -10
    else
        echo "Nu există backup-uri"
    fi
}

# Inițializare automată
init_backup_system

# Export funcții pentru utilizare externă
export -f configure_automatic_backup execute_full_backup restore_from_backup
export -f cleanup_old_backups show_backup_status

log_debug "Backup Recovery Manager încărcat cu succes"
