#!/bin/bash
#
# database_manager.sh - Sistem îmbunătățit pentru gestionarea bazelor de date
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

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/author_info.sh"
source "$SCRIPT_DIR/dependency_manager.sh"
source "$SCRIPT_DIR/error_handler.sh"
source "$SCRIPT_DIR/state_manager.sh"

# Initialize error handling
setup_error_handlers
DEBUG_MODE=true

# Constante pentru configurare
readonly DB_CONFIG_DIR="/etc/stack/database"
readonly DB_ROOT_PASS_FILE="/root/.stack_db_root_pass"
readonly SUPPORTED_DATABASES=("mariadb" "mysql")
export SUPPORTED_DATABASES

# Inițializează configurarea bazei de date
init_database_config() {
    sudo mkdir -p "$DB_CONFIG_DIR"
    sudo chmod 700 "$DB_CONFIG_DIR"
}

# Detectează tipul de bază de date instalat
detect_database_type() {
    if systemctl is-active --quiet mariadb 2>/dev/null; then
        echo "mariadb"
    elif systemctl is-active --quiet mysql 2>/dev/null; then
        echo "mysql"
    elif command -v mariadb >/dev/null 2>&1; then
        echo "mariadb"
    elif command -v mysql >/dev/null 2>&1; then
        echo "mysql"
    else
        echo "none"
    fi
}

# Verifică dacă baza de date este funcțională
is_database_healthy() {
    local db_type
    db_type="$(detect_database_type)"
    
    case "$db_type" in
        "mariadb"|"mysql")
            # Verifică dacă serviciul rulează
            if ! systemctl is-active --quiet "$db_type" 2>/dev/null; then
                log_debug "Database service $db_type is not running"
                return 1
            fi
            
            # Verifică dacă răspunde la ping
            if ! mysqladmin ping >/dev/null 2>&1; then
                log_debug "Database is not responding to ping"
                return 1
            fi
            
            # Verifică dacă root poate accesa
            if ! test_root_access; then
                log_debug "Root access test failed"
                return 1
            fi
            
            return 0
            ;;
        *)
            log_debug "No supported database detected"
            return 1
            ;;
    esac
}

# Testează accesul root la baza de date
test_root_access() {
    local root_pass=""
    
    # Încearcă să obțină parola root
    if [[ -f "$DB_ROOT_PASS_FILE" ]]; then
        root_pass="$(sudo cat "$DB_ROOT_PASS_FILE" 2>/dev/null)"
    fi
    
    # Testează accesul fără parolă (unix_socket)
    if sudo mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
        log_debug "Root access successful without password (unix_socket)"
        return 0
    fi
    
    # Testează accesul cu parolă
    if [[ -n "$root_pass" ]] && mysql -u root -p"$root_pass" -e "SELECT 1;" >/dev/null 2>&1; then
        log_debug "Root access successful with stored password"
        return 0
    fi
    
    log_debug "Root access failed"
    return 1
}

# Generează și setează o parolă sigură pentru root
setup_root_password() {
    local db_type
    db_type="$(detect_database_type)"
    local new_password
    new_password="$(generate_secure_password)"
    
    case "$db_type" in
        "mariadb")
            setup_mariadb_root_password "$new_password"
            ;;
        "mysql")
            setup_mysql_root_password "$new_password"
            ;;
        *)
            log_error "Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# Configurează parola root pentru MariaDB
setup_mariadb_root_password() {
    local password="$1"
    local escaped_pass
    escaped_pass="$(printf "%s" "$password" | sed "s/'/''/g")"
    
    log_info "Setting up MariaDB root password"
    
    # Încearcă diferite metode de autentificare
    local auth_methods=(
        "sudo mysql -u root"
        "mysql -u root"
    )
    
    local current_pass=""
    if [[ -f "$DB_ROOT_PASS_FILE" ]]; then
        current_pass="$(sudo cat "$DB_ROOT_PASS_FILE" 2>/dev/null)"
        auth_methods+=("mysql -u root -p$current_pass")
    fi
    
    local success=false
    for auth_method in "${auth_methods[@]}"; do
        log_debug "Trying authentication method: $auth_method"
        
        if $auth_method -e "SELECT 1;" >/dev/null 2>&1; then
            log_debug "Authentication successful, setting password"
            
            # Încearcă să seteze parola
            if $auth_method -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$escaped_pass';" 2>/dev/null; then
                success=true
                break
            elif $auth_method -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$escaped_pass');" 2>/dev/null; then
                success=true
                break
            fi
        fi
    done
    
    if [[ "$success" == "true" ]]; then
        # Salvează parola
        echo "$password" | sudo tee "$DB_ROOT_PASS_FILE" >/dev/null
        sudo chmod 600 "$DB_ROOT_PASS_FILE"
        
        # Flush privileges
        mysql -u root -p"$password" -e "FLUSH PRIVILEGES;" 2>/dev/null || true
        
        log_info "MariaDB root password set successfully"
        return 0
    else
        log_error "Failed to set MariaDB root password"
        return 1
    fi
}

# Configurează parola root pentru MySQL
setup_mysql_root_password() {
    local password="$1"
    
    log_info "Setting up MySQL root password"
    
    if sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$password';" 2>/dev/null; then
        echo "$password" | sudo tee "$DB_ROOT_PASS_FILE" >/dev/null
        sudo chmod 600 "$DB_ROOT_PASS_FILE"
        
        mysql -u root -p"$password" -e "FLUSH PRIVILEGES;" 2>/dev/null || true
        
        log_info "MySQL root password set successfully"
        return 0
    else
        log_error "Failed to set MySQL root password"
        return 1
    fi
}

# Securizează instalarea bazei de date
secure_database_installation() {
    local db_type
    db_type="$(detect_database_type)"
    
    if [[ "$db_type" == "none" ]]; then
        log_error "No database detected for security setup"
        return 1
    fi
    
    log_info "Securing $db_type installation"
    
    # Asigură parola root
    if ! test_root_access; then
        log_warn "Root access not working, attempting to set up password"
        setup_root_password || return 1
    fi
    
    # Obține parola root pentru operațiuni
    local root_pass=""
    if [[ -f "$DB_ROOT_PASS_FILE" ]]; then
        root_pass="$(sudo cat "$DB_ROOT_PASS_FILE")"
    fi
    
    local mysql_cmd="mysql -u root"
    if [[ -n "$root_pass" ]]; then
        mysql_cmd="mysql -u root -p$root_pass"
    fi
    
    # Operațiuni de securizare
    log_info "Removing anonymous users"
    $mysql_cmd -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || log_warn "Failed to remove anonymous users"
    
    log_info "Removing remote root access"
    $mysql_cmd -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || log_warn "Failed to remove remote root access"
    
    log_info "Removing test database"
    $mysql_cmd -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || log_warn "Failed to remove test database"
    
    log_info "Removing test database privileges"
    $mysql_cmd -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null || log_warn "Failed to remove test database privileges"
    
    log_info "Flushing privileges"
    $mysql_cmd -e "FLUSH PRIVILEGES;" 2>/dev/null || log_warn "Failed to flush privileges"
    
    log_info "Database security setup completed"
    return 0
}

# Creează o bază de date și utilizator izolat
create_isolated_database() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    
    if [[ -z "$db_name" || -z "$db_user" || -z "$db_password" ]]; then
        log_error "Database name, user, and password are required"
        return 1
    fi
    
    log_info "Creating isolated database: $db_name"
    
    # Obține credentialele root
    local root_pass=""
    if [[ -f "$DB_ROOT_PASS_FILE" ]]; then
        root_pass="$(sudo cat "$DB_ROOT_PASS_FILE")"
    fi
    
    local mysql_cmd="mysql -u root"
    if [[ -n "$root_pass" ]]; then
        mysql_cmd="mysql -u root -p$root_pass"
    fi
    
    # Verifică și creează baza de date
    if ! $mysql_cmd -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;" 2>/dev/null; then
        log_error "Failed to create database: $db_name"
        return 1
    fi
    
    # Creează utilizatorul
    if ! $mysql_cmd -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';" 2>/dev/null; then
        log_error "Failed to create user: $db_user"
        return 1
    fi
    
    # Setează privilegiile
    if ! $mysql_cmd -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';" 2>/dev/null; then
        log_error "Failed to grant privileges to user: $db_user"
        return 1
    fi
    
    # Flush privileges
    $mysql_cmd -e "FLUSH PRIVILEGES;" 2>/dev/null || log_warn "Failed to flush privileges"
    
    log_info "Database $db_name created successfully with user $db_user"
    
    # Salvează informațiile în state
    set_state_var "DB_NAME" "$db_name"
    set_state_var "DB_USER" "$db_user"
    set_state_var "DB_HOST" "localhost"
    
    return 0
}

# Generează o parolă sigură
generate_secure_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' </dev/urandom | head -c 16
}

# Testează conexiunea la o bază de date specifică
test_database_connection() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    local db_host="${4:-localhost}"
    
    if mysql -h "$db_host" -u "$db_user" -p"$db_password" "$db_name" -e "SELECT 1;" >/dev/null 2>&1; then
        log_info "Database connection test successful for $db_user@$db_host/$db_name"
        return 0
    else
        log_error "Database connection test failed for $db_user@$db_host/$db_name"
        return 1
    fi
}

# Funcție pentru afișarea informațiilor despre script
show_database_manager_info() {
    cat << EOF

═══════════════════════════════════════════════════════════════════════════════
                        DATABASE MANAGER - LOMP Stack v3.0
═══════════════════════════════════════════════════════════════════════════════

This database manager provides comprehensive database management for LOMP Stack.

Features:
• Automatic database type detection (MySQL/MariaDB)
• Secure root password management
• Database health monitoring
• Isolated database creation
• Connection testing and validation
• Security hardening

Author: $AUTHOR_NAME <$AUTHOR_EMAIL>
Company: $AUTHOR_COMPANY
Support: $SUPPORT_URL

═══════════════════════════════════════════════════════════════════════════════
EOF
}

# Afișează informații despre management baze de date în modul debug
if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
    log_debug "Database Manager loaded - LOMP Stack v$PROJECT_VERSION by $AUTHOR_NAME"
fi

# Export funcții pentru utilizare globală
export -f detect_database_type is_database_healthy test_root_access
export -f setup_root_password secure_database_installation create_isolated_database
export -f generate_secure_password test_database_connection
export -f show_database_manager_info
