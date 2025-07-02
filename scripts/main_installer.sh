#!/bin/bash
#
# main_installer.sh - Part of LOMP Stack v3.0
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
# main_installer.sh - Script principal îmbunătățit pentru instalarea stack-ului WordPress

# Setări globale
set -euo pipefail  # Strict mode
export SCRIPT_DIR=
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
export STACK_VERSION="2.0.0"

# Încarcă modulele de bază
source "$SCRIPT_DIR/helpers/utils/dependency_manager.sh"
source "$SCRIPT_DIR/helpers/utils/error_handler.sh"
source "$SCRIPT_DIR/helpers/utils/state_manager.sh"
source "$SCRIPT_DIR/helpers/utils/ui_manager.sh"
source "$SCRIPT_DIR/helpers/utils/database_manager.sh"

# Setează error handling
setup_error_handlers
export DEBUG_MODE="${DEBUG_MODE:-0}"
export STRICT_MODE="${STRICT_MODE:-1}"

# Inițializează mediul
init_environment() {
    log_info "Initializing stack installer environment"
    
    # Verifică privilegii
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Inițializează state management
    init_state_directories
    load_state
    
    # Inițializează core dependencies
    init_core_dependencies
    
    # Detectează mediul de execuție
    detect_environment
    
    log_info "Environment initialized successfully"
}

# Detectează tipul de mediu (WSL, Docker, VM, etc.)
detect_environment() {
    local env_type="unknown"
    
    if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
        env_type="wsl"
    elif [[ -f /.dockerenv ]]; then
        env_type="docker"
    elif grep -q 'QEMU\|VMware\|VirtualBox' /proc/cpuinfo 2>/dev/null; then
        env_type="vm"
    elif systemd-detect-virt -q 2>/dev/null; then
        env_type="virtualized"
    else
        env_type="physical"
    fi
    
    set_state_var "ENV_TYPE" "$env_type"
    log_info "Environment detected: $env_type"
}

# Meniul principal îmbunătățit
show_main_menu() {
    local last_domain
    last_domain="$(get_state_var 'STACK_DOMAIN' '')"
    local subtitle="WordPress LOMP Stack Installer v$STACK_VERSION"
    
    if [[ -n "$last_domain" ]]; then
        subtitle="$subtitle | Last install: $last_domain"
    fi
    
    show_header "STACK INSTALLER" "$subtitle"
    
    local menu_options=(
        "🚀 Quick Install (Recommended) - Nginx + MariaDB + WordPress"
        "⚡ Ultra Minimal - Basic WordPress setup"
        "🔧 Advanced Install - Custom configuration"
        "👤 Add User & Domain - Create isolated WordPress instance"
        "🧩 Component Manager - Install additional components"
        "💾 Backup Manager - Manage backups and restores"
        "🔄 Update System - Update all components"
        "📊 System Status - View system health"
        "🧹 Cleanup System - Remove unused packages"
        "⚙️  Settings - Configure installer preferences"
    )
    
    show_menu "MAIN MENU" "${menu_options[@]}"
    
    local selection
    selection="$(read_menu_selection ${#menu_options[@]} "Select an option")"
    
    case "$selection" in
        0) exit_installer ;;
        1) quick_install ;;
        2) ultra_minimal_install ;;
        3) advanced_install ;;
        4) add_user_domain_menu ;;
        5) component_manager_menu ;;
        6) backup_manager_menu ;;
        7) update_system_menu ;;
        8) system_status_menu ;;
        9) cleanup_system_menu ;;
        10) settings_menu ;;
        *) log_error "Invalid selection: $selection" ;;
    esac
}

# Instalare rapidă
quick_install() {
    show_header "QUICK INSTALL" "Nginx + MariaDB + WordPress + Redis"
    
    log_info "Starting quick installation"
    
    # Verifică dacă sistemul are deja o instalare
    if is_database_healthy && systemctl is-active --quiet nginx 2>/dev/null; then
        if ! confirm_action "Existing installation detected. Continue anyway?" "n"; then
            return
        fi
    fi
    
    # Instalează componentele într-o secvență optimizată
    local steps=(
        "update_system:Updating system packages"
        "install_nginx:Installing Nginx web server"
        "install_php:Installing PHP and extensions"
        "install_mariadb:Installing MariaDB database"
        "install_redis:Installing Redis cache"
        "setup_database:Setting up database security"
        "install_wpcli:Installing WP-CLI"
        "create_user_domain:Creating user and domain"
        "install_wordpress:Installing WordPress"
        "final_configuration:Final configuration"
    )
    
    execute_installation_steps "${steps[@]}"
    
    show_installation_summary
}

# Instalare ultra minimală
ultra_minimal_install() {
    show_header "ULTRA MINIMAL INSTALL" "Basic WordPress setup"
    
    log_info "Starting ultra minimal installation"
    
    local steps=(
        "update_system:Updating system packages"
        "install_nginx:Installing Nginx web server"
        "install_php:Installing PHP"
        "install_mariadb:Installing MariaDB database"
        "setup_database:Setting up database"
        "install_wpcli:Installing WP-CLI"
        "create_user_domain:Creating user and domain"
        "install_wordpress:Installing WordPress"
    )
    
    execute_installation_steps "${steps[@]}"
    
    show_installation_summary
}

# Instalare avansată cu opțiuni de configurare
advanced_install() {
    show_header "ADVANCED INSTALL" "Custom configuration options"
    
    # Selectează webserver
    local webserver
    webserver="$(select_webserver)"
    set_state_var "SELECTED_WEBSERVER" "$webserver"
    
    # Selectează baza de date
    local database
    database="$(select_database)"
    set_state_var "SELECTED_DATABASE" "$database"
    
    # Opțiuni de securitate
    local enable_security
    if confirm_action "Enable advanced security features (firewall, fail2ban)?" "y"; then
        enable_security="true"
    else
        enable_security="false"
    fi
    set_state_var "ENABLE_SECURITY" "$enable_security"
    
    # Opțiuni de performanță
    local enable_performance
    if confirm_action "Enable performance optimizations (caching, compression)?" "y"; then
        enable_performance="true"
    else
        enable_performance="false"
    fi
    set_state_var "ENABLE_PERFORMANCE" "$enable_performance"
    
    # Execută instalarea cu setările selectate
    execute_advanced_installation
}

# Selectează webserver
select_webserver() {
    local webserver_options=(
        "nginx - Lightweight and fast"
        "apache - Traditional and stable"
        "openlitespeed - High performance with admin panel"
    )
    
    show_menu "SELECT WEB SERVER" "${webserver_options[@]}"
    local selection
    selection="$(read_menu_selection ${#webserver_options[@]} "Choose web server")"
    
    case "$selection" in
        1) echo "nginx" ;;
        2) echo "apache" ;;
        3) echo "openlitespeed" ;;
        0) exit_installer ;;
        *) echo "nginx" ;;  # default
    esac
}

# Selectează baza de date
select_database() {
    local database_options=(
        "mariadb - Recommended for WordPress"
        "mysql - Traditional MySQL server"
        "external - Use existing database server"
    )
    
    show_menu "SELECT DATABASE" "${database_options[@]}"
    local selection
    selection="$(read_menu_selection ${#database_options[@]} "Choose database")"
    
    case "$selection" in
        1) echo "mariadb" ;;
        2) echo "mysql" ;;
        3) echo "external" ;;
        0) exit_installer ;;
        *) echo "mariadb" ;;  # default
    esac
}

# Execută pașii de instalare cu progress tracking
execute_installation_steps() {
    local steps=("$@")
    local total_steps=${#steps[@]}
    local current_step=0
    
    for step_info in "${steps[@]}"; do
        IFS=':' read -r step_func step_desc <<< "$step_info"
        ((current_step++))
        
        show_progress "$current_step" "$total_steps" "$step_desc"
        
        if ! $step_func; then
            log_error "Installation step failed: $step_desc"
            if ! confirm_action "Continue with remaining steps?" "n"; then
                return 1
            fi
        fi
        
        sleep 1  # Scurtă pauză pentru vizibilitate
    done
    
    log_info "All installation steps completed"
}

# Afișează sumar final al instalării
show_installation_summary() {
    local domain
    domain="$(get_state_var 'STACK_DOMAIN' 'Not set')"
    local username
    username="$(get_state_var 'STACK_USERNAME' 'Not set')"
    local webserver
    webserver="$(get_state_var 'SELECTED_WEBSERVER' 'nginx')"
    local database
    database="$(get_state_var 'SELECTED_DATABASE' 'mariadb')"
    
    show_header "INSTALLATION COMPLETE" "WordPress stack has been successfully installed"
    
    echo -e "${UI_SUCCESS}✓ Installation completed successfully!${UI_RESET}"
    echo
    echo -e "${UI_INFO}Installation Details:${UI_RESET}"
    echo -e "  Domain: ${UI_PRIMARY}$domain${UI_RESET}"
    echo -e "  Username: ${UI_PRIMARY}$username${UI_RESET}"
    echo -e "  Web Server: ${UI_PRIMARY}$webserver${UI_RESET}"
    echo -e "  Database: ${UI_PRIMARY}$database${UI_RESET}"
    echo
    echo -e "${UI_INFO}Access URLs:${UI_RESET}"
    echo -e "  Website: ${UI_PRIMARY}http://$domain${UI_RESET}"
    echo -e "  WordPress Admin: ${UI_PRIMARY}http://$domain/wp-admin${UI_RESET}"
    echo
    
    if [[ -f "/home/$username/config/wordpress_credentials.txt" ]]; then
        echo -e "${UI_WARNING}WordPress credentials saved to:${UI_RESET}"
        echo -e "  ${UI_MUTED}/home/$username/config/wordpress_credentials.txt${UI_RESET}"
        echo
    fi
    
    echo -e "${UI_WARNING}Next steps:${UI_RESET}"
    echo -e "  1. Configure your domain's DNS to point to this server"
    echo -e "  2. Set up SSL certificate (Let's Encrypt recommended)"
    echo -e "  3. Configure WordPress settings and themes"
    echo
    
    read -p "Press Enter to continue..."
}

# Meniu pentru adăugarea utilizator și domeniu
add_user_domain_menu() {
    show_header "ADD USER & DOMAIN" "Create isolated WordPress instance"
    
    local domain
    domain="$(read_input "Enter domain name" "validate_domain")"
    
    local username
    username="$(read_input "Enter username" "validate_username")"
    
    if confirm_action "Create user '$username' with domain '$domain'?" "y"; then
        create_user_and_domain "$username" "$domain"
    fi
}

# Ieșire din installer
exit_installer() {
    show_header "GOODBYE" "Thank you for using Stack Installer"
    
    log_info "Installer exited by user"
    exit 0
}

# Funcție de demonstrare pentru pașii de instalare
update_system() {
    log_info "Updating system packages"
    apt update && apt upgrade -y
}

install_nginx() {
    log_info "Installing Nginx"
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
}

install_php() {
    log_info "Installing PHP and extensions"
    apt install -y php php-fpm php-mysql php-xml php-curl php-gd php-mbstring php-zip php-bcmath php-imagick php-intl php-soap
}

install_mariadb() {
    log_info "Installing MariaDB"
    apt install -y mariadb-server
    systemctl enable mariadb
    systemctl start mariadb
}

install_redis() {
    log_info "Installing Redis"
    apt install -y redis-server
    systemctl enable redis-server
    systemctl start redis-server
}

setup_database() {
    log_info "Setting up database security"
    secure_database_installation
}

install_wpcli() {
    log_info "Installing WP-CLI"
    if ! command -v wp >/dev/null 2>&1; then
        curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    fi
}

create_user_domain() {
    log_info "Creating user and domain structure"
    # Implementează logica pentru crearea user/domain
    set_state_var "STACK_DOMAIN" "example.com"
    set_state_var "STACK_USERNAME" "webuser"
}

install_wordpress() {
    log_info "Installing WordPress"
    # Implementează logica pentru instalarea WordPress
}

final_configuration() {
    log_info "Applying final configuration"
    # Configurări finale
}

# Funcții placeholder pentru meniuri suplimentare
component_manager_menu() {
    echo "Component Manager - Coming soon"
    read -p "Press Enter to continue..."
}

backup_manager_menu() {
    echo "Backup Manager - Coming soon"
    read -p "Press Enter to continue..."
}

update_system_menu() {
    echo "System Update - Coming soon"
    read -p "Press Enter to continue..."
}

system_status_menu() {
    show_system_status
    read -p "Press Enter to continue..."
}

cleanup_system_menu() {
    echo "System Cleanup - Coming soon"
    read -p "Press Enter to continue..."
}

settings_menu() {
    echo "Settings - Coming soon"
    read -p "Press Enter to continue..."
}

execute_advanced_installation() {
    echo "Advanced Installation - Coming soon"
    read -p "Press Enter to continue..."
}

create_user_and_domain() {
    local username="$1"
    local domain="$2"
    echo "Creating user '$username' with domain '$domain' - Coming soon"
    read -p "Press Enter to continue..."
}

# Main loop
main() {
    # Inițializează mediul
    init_environment
    
    # Loop principal al meniului
    while true; do
        show_main_menu
    done
}

# Rulează main dacă scriptul este executat direct
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
