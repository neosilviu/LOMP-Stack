#!/bin/bash
#==============================================================================
# LOMP Stack v3.0 - State Manager
# 
# Centralized system for application state management
# 
# Author: Silviu Ilie
# Email: neosilviu@gmail.com
# Company: aemdPC
# License: MIT
# Version: 3.0
# 
# Description: Provides centralized state management functionality for 
# the LOMP Stack, including persistent and temporary state handling,
# backup/restore capabilities, and installation tracking.
#==============================================================================

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependency_manager.sh"
source "$SCRIPT_DIR/error_handler.sh"
source "$SCRIPT_DIR/author_info.sh"

# Initialize error handling
setup_error_handlers
DEBUG_MODE=true

# Configurare paths pentru state management - folosim paths mai flexibile
readonly STATE_DIR="${STATE_DIR:-/tmp/stack_state}"
readonly PERSISTENT_STATE_DIR="${PERSISTENT_STATE_DIR:-$HOME/.stack}"
readonly STATE_FILE="$PERSISTENT_STATE_DIR/installation_state.conf"
readonly TEMP_STATE_FILE="$STATE_DIR/stack_user_env"
readonly BACKUP_STATE_DIR="$PERSISTENT_STATE_DIR/backups"

# Asigură existența directoarelor de state
init_state_directories() {
    local dirs=("$STATE_DIR" "$PERSISTENT_STATE_DIR" "$BACKUP_STATE_DIR")
    
    for dir in "${dirs[@]}"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            log_warning "Nu pot crea directorul de stare: $dir"
            # Încearcă cu sudo dacă e nevoie
            if ! sudo mkdir -p "$dir" 2>/dev/null; then
                log_error "Eșec la crearea directorului: $dir"
                return 1
            fi
        fi
        log_debug "Director de stare inițializat: $dir"
    done
    
    # Setează permisiuni
    chmod 755 "$STATE_DIR" "$PERSISTENT_STATE_DIR" 2>/dev/null || true
    chmod 700 "$BACKUP_STATE_DIR" 2>/dev/null || true
    
    return 0
}

# Funcție pentru salvarea unei variabile în state
set_state_var() {
    local key="$1"
    local value="$2"
    local persistent="${3:-true}"  # true|false pentru persistență
    
    # Validare parametri
    if [[ -z "$key" ]]; then
        log_error "State key cannot be empty"
        return 1
    fi
    
    log_debug "Setare variabilă de stare: $key=$value (persistent=$persistent)"
    
    # Export în mediul curent
    export "$key"="$value"
    
    # Asigură că directoarele există
    init_state_directories || return 1
    
    # Salvare în fișierul temporar pentru sesiunea curentă
    if [[ -f "$TEMP_STATE_FILE" ]]; then
        # Elimină linia existentă dacă există
        sed -i "/^${key}=/d" "$TEMP_STATE_FILE" 2>/dev/null || true
    fi
    echo "${key}=${value}" >> "$TEMP_STATE_FILE"
    
    # Salvare persistentă dacă este cerută
    if [[ "$persistent" == "true" ]]; then
        if [[ -f "$STATE_FILE" ]]; then
            sed -i "/^${key}=/d" "$STATE_FILE" 2>/dev/null || true
        fi
        echo "${key}=${value}" >> "$STATE_FILE"
        log_debug "Variabilă salvată persistent: $key"
    fi
    
    return 0
}

# Funcție pentru obținerea unei variabile din state
get_state_var() {
    local key="$1"
    local default_value="${2:-}"
    
    # Încearcă din mediul curent
    if [[ -n "${!key:-}" ]]; then
        echo "${!key}"
        return 0
    fi
    
    # Încearcă din fișierul temporar
    if [[ -f "$TEMP_STATE_FILE" ]]; then
        local temp_value
        temp_value=$(grep "^${key}=" "$TEMP_STATE_FILE" 2>/dev/null | tail -1 | cut -d'=' -f2-)
        if [[ -n "$temp_value" ]]; then
            echo "$temp_value"
            return 0
        fi
    fi
    
    # Încearcă din fișierul persistent
    if [[ -f "$STATE_FILE" ]]; then
        local persistent_value
        persistent_value=$(sudo grep "^${key}=" "$STATE_FILE" 2>/dev/null | tail -1 | cut -d'=' -f2-)
        if [[ -n "$persistent_value" ]]; then
            echo "$persistent_value"
            return 0
        fi
    fi
    
    # Returnează valoarea default
    echo "$default_value"
}

# Funcție pentru încărcarea tuturor variabilelor de state
load_state() {
    local source_persistent="${1:-true}"  # true|false
    
    # Încarcă din fișierul temporar
    if [[ -f "$TEMP_STATE_FILE" ]]; then
        while IFS='=' read -r key value; do
            [[ -n "$key" && ! "$key" =~ ^[[:space:]]*# ]] && export "$key"="$value"
        done < "$TEMP_STATE_FILE"
    fi
    
    # Încarcă din fișierul persistent dacă este cerut
    if [[ "$source_persistent" == "true" && -f "$STATE_FILE" ]]; then
        while IFS='=' read -r key value; do
            [[ -n "$key" && ! "$key" =~ ^[[:space:]]*# ]] && export "$key"="$value"
        done < <(sudo cat "$STATE_FILE")
    fi
}

# Funcție pentru salvarea stării complete a unei instalări
save_installation_state() {
    local domain="$1"
    local username="$2"
    local webserver="$3"
    local database="$4"
    
    # Timestamp pentru această instalare
    local timestamp
    timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
    
    # Salvează variabilele principale
    set_state_var "LAST_INSTALLATION_TIME" "$timestamp"
    set_state_var "STACK_DOMAIN" "$domain"
    set_state_var "STACK_USERNAME" "$username"
    set_state_var "STACK_WEBSERVER" "$webserver"
    set_state_var "STACK_DATABASE" "$database"
    
    # Salvează paths importante
    set_state_var "STACK_WEBROOT" "/home/$username/$domain"
    set_state_var "STACK_LOGS_DIR" "/home/$username/logs"
    set_state_var "STACK_CONFIG_DIR" "/home/$username/config"
    set_state_var "STACK_BACKUP_DIR" "/home/$username/backup"
    
    # Informații despre baza de date
    set_state_var "DB_NAME" "${username}_${domain}_db"
    set_state_var "DB_USER" "${username}_${domain}_user"
    set_state_var "DB_HOST" "localhost"
    
    # Status componente
    set_state_var "REDIS_INSTALLED" "$(systemctl is-active redis-server >/dev/null 2>&1 && echo 'true' || echo 'false')"
    set_state_var "WORDPRESS_INSTALLED" "true"
    
    echo "[INFO] Installation state saved for domain: $domain (user: $username)"
}

# Funcție pentru backup-ul stării
backup_state() {
    local backup_name="${1:-state_backup_$(date '+%Y%m%d_%H%M%S')}"
    
    init_state_directories
    
    if [[ -f "$STATE_FILE" ]]; then
        sudo cp "$STATE_FILE" "$BACKUP_STATE_DIR/$backup_name.conf"
        echo "[INFO] State backed up to: $BACKUP_STATE_DIR/$backup_name.conf"
    fi
    
    if [[ -f "$TEMP_STATE_FILE" ]]; then
        cp "$TEMP_STATE_FILE" "$BACKUP_STATE_DIR/$backup_name.temp"
        echo "[INFO] Temp state backed up to: $BACKUP_STATE_DIR/$backup_name.temp"
    fi
}

# Funcție pentru restore state din backup
restore_state() {
    local backup_name="$1"
    
    if [[ -f "$BACKUP_STATE_DIR/$backup_name.conf" ]]; then
        sudo cp "$BACKUP_STATE_DIR/$backup_name.conf" "$STATE_FILE"
        echo "[INFO] State restored from: $BACKUP_STATE_DIR/$backup_name.conf"
    fi
    
    if [[ -f "$BACKUP_STATE_DIR/$backup_name.temp" ]]; then
        cp "$BACKUP_STATE_DIR/$backup_name.temp" "$TEMP_STATE_FILE"
        echo "[INFO] Temp state restored from: $BACKUP_STATE_DIR/$backup_name.temp"
    fi
    
    load_state "true"
}

# Funcție pentru listarea backup-urilor de state
list_state_backups() {
    if [[ -d "$BACKUP_STATE_DIR" ]]; then
        echo "Available state backups:"
        ls -la "$BACKUP_STATE_DIR"/*.conf 2>/dev/null | awk '{print $9, $6, $7, $8}' || echo "No backups found"
    else
        echo "No backup directory found"
    fi
}

# Funcție pentru cleanup state vechi
cleanup_old_state() {
    local days="${1:-30}"  # Șterge backup-uri mai vechi de X zile
    
    if [[ -d "$BACKUP_STATE_DIR" ]]; then
        find "$BACKUP_STATE_DIR" -name "*.conf" -mtime +$days -delete 2>/dev/null || true
        find "$BACKUP_STATE_DIR" -name "*.temp" -mtime +$days -delete 2>/dev/null || true
        echo "[INFO] Cleaned up state backups older than $days days"
    fi
}

# Funcție pentru afișarea stării curente
show_current_state() {
    echo "=== CURRENT STACK STATE ==="
    echo "Last Installation: $(get_state_var 'LAST_INSTALLATION_TIME' 'Never')"
    echo "Domain: $(get_state_var 'STACK_DOMAIN' 'Not set')"
    echo "Username: $(get_state_var 'STACK_USERNAME' 'Not set')"
    echo "Webserver: $(get_state_var 'STACK_WEBSERVER' 'Not set')"
    echo "Database: $(get_state_var 'STACK_DATABASE' 'Not set')"
    echo "WordPress: $(get_state_var 'WORDPRESS_INSTALLED' 'false')"
    echo "Redis: $(get_state_var 'REDIS_INSTALLED' 'false')"
    echo "=========================="
}

# Funcție pentru afișarea informațiilor despre autor
show_author_info() {
    print_author_header
    echo
    echo "State Manager Module - Centralized application state management"
    echo "Provides persistent and temporary state handling, backup/restore"
    echo "capabilities, and installation tracking for the LOMP Stack."
    echo
    print_author_footer
}

# Export funcții pentru utilizare globală
export -f init_state_directories set_state_var get_state_var load_state
export -f save_installation_state backup_state restore_state list_state_backups
export -f cleanup_old_state show_current_state show_author_info
