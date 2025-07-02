#!/bin/bash
#==============================================================================
# LOMP Stack v3.0 - System Update Manager
# 
# Comprehensive system update script for all LOMP Stack components
# 
# Author: Silviu Ilie
# Email: neosilviu@gmail.com
# Company: aemdPC
# License: MIT
# Version: 3.0
# 
# Description: Updates all main installed components (webserver, PHP, DB, 
# WordPress, WP-CLI, Redis, security, monitoring) with proper logging
# and web interface integration support.
#==============================================================================

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/functions.sh" 2>/dev/null || echo "Warning: functions.sh not found"
source "$SCRIPT_DIR/lang.sh" 2>/dev/null || echo "Warning: lang.sh not found"
source "$SCRIPT_DIR/author_info.sh" 2>/dev/null || echo "Warning: author_info.sh not found"

# Configuration
AUTO_MODE=false
LOG_FILE="/var/log/lomp_update.log"
UPDATE_LOCK="/tmp/lomp_update.lock"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to show help
show_help() {
    echo "LOMP Stack v3.0 - System Update Manager"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --auto       Run in automatic mode (non-interactive)"
    echo "  --log-file   Specify custom log file path"
    echo "  --help       Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Interactive mode"
    echo "  $0 --auto            # Automatic mode for web interface"
    echo "  $0 --auto --log-file /tmp/update.log"
}

# Logging function
log_message() {
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Progress function for web interface
report_progress() {
    local step="$1"
    local total="$2"
    local description="$3"
    local percentage=$((step * 100 / total))
    
    log_message "PROGRESS: $percentage% - $description"
    
    # Also output to stdout for web interface parsing
    echo "PROGRESS:$percentage:$description"
}

# Check for existing update process
check_update_lock() {
    if [[ -f "$UPDATE_LOCK" ]]; then
        local lock_pid
        lock_pid=$(cat "$UPDATE_LOCK" 2>/dev/null)
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_message "ERROR: Another update process is already running (PID: $lock_pid)"
            exit 1
        else
            log_message "INFO: Removing stale lock file"
            rm -f "$UPDATE_LOCK"
        fi
    fi
    
    # Create lock file
    echo $$ > "$UPDATE_LOCK"
}

# Cleanup function
cleanup() {
    rm -f "$UPDATE_LOCK"
    log_message "INFO: Update process completed"
}

# Set trap for cleanup
trap cleanup EXIT

# Start update process
main() {
    log_message "INFO: Starting LOMP Stack system update"
    
    if command -v print_author_header >/dev/null 2>&1; then
        print_author_header
    else
        echo "=============================================="
        echo "   LOMP Stack v3.0 - System Update"
        echo "=============================================="
    fi
    
    check_update_lock
    
    # Total steps for progress tracking
    local total_steps=10
    local current_step=0
    
    # Step 1: Update package lists
    ((current_step++))
    report_progress $current_step $total_steps "Updating package lists"
    if ! sudo apt update; then
        log_message "ERROR: Failed to update package lists"
        exit 1
    fi
    
    # Step 2: Upgrade system packages
    ((current_step++))
    report_progress $current_step $total_steps "Upgrading system packages"
    if $AUTO_MODE; then
        sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
    else
        sudo apt upgrade -y
    fi

# Actualizează webservere
if command -v openlitespeed >/dev/null 2>&1; then
  color_echo yellow "[OLS] Updating OpenLiteSpeed..."
  sudo apt install --only-upgrade -y openlitespeed
fi
if command -v nginx >/dev/null 2>&1; then
  color_echo yellow "[Nginx] Updating Nginx..."
  sudo apt install --only-upgrade -y nginx
fi
if command -v apache2 >/dev/null 2>&1; then
  color_echo yellow "[Apache] Updating Apache..."
  sudo apt install --only-upgrade -y apache2
fi

# Actualizează PHP și lsphp
sudo apt install --only-upgrade -y php* lsphp* || true

# Actualizează MariaDB/MySQL
if command -v mariadb >/dev/null 2>&1 || command -v mariadb-server >/dev/null 2>&1; then
  color_echo yellow "[MariaDB] Updating MariaDB..."
  sudo apt install --only-upgrade -y mariadb-server
fi
## Eliminat update MySQL, fallback la MariaDB (compatibil WordPress)

# Actualizează Redis
if command -v redis-server >/dev/null 2>&1; then
  color_echo yellow "[Redis] Updating Redis..."
  sudo apt install --only-upgrade -y redis-server php-redis
fi

# Actualizează WP-CLI
if command -v wp >/dev/null 2>&1; then
  color_echo yellow "[WP-CLI] Updating WP-CLI..."
  sudo wp cli update --yes || true
fi

# Actualizează WordPress (toate instalările din /var/www, /srv/www, /home/*/public_html, /tmp/wp_test_dir)
for wpdir in /var/www/* /srv/www/* /home/*/public_html /tmp/wp_test_dir; do
  if [ -d "$wpdir/wp-includes" ]; then
    color_echo yellow "[WordPress] Updating in $wpdir ..."
    sudo -u www-data wp core update --path="$wpdir" || true
    sudo -u www-data wp plugin update --all --path="$wpdir" || true
    sudo -u www-data wp theme update --all --path="$wpdir" || true
  fi
done

# Actualizează securitate și monitoring
sudo apt install --only-upgrade -y fail2ban netdata || true

color_echo green "[DONE] Toate componentele principale au fost actualizate!"

    # Step 3: Update web servers
    ((current_step++))
    report_progress $current_step $total_steps "Updating web servers"
    
    if command -v openlitespeed >/dev/null 2>&1; then
        log_message "INFO: Updating OpenLiteSpeed"
        sudo apt install --only-upgrade -y openlitespeed
    fi
    
    if command -v nginx >/dev/null 2>&1; then
        log_message "INFO: Updating Nginx"
        sudo apt install --only-upgrade -y nginx
    fi
    
    if command -v apache2 >/dev/null 2>&1; then
        log_message "INFO: Updating Apache"
        sudo apt install --only-upgrade -y apache2
    fi
    
    # Step 4: Update PHP
    ((current_step++))
    report_progress $current_step $total_steps "Updating PHP packages"
    log_message "INFO: Updating PHP and LSPHP packages"
    sudo apt install --only-upgrade -y php* lsphp* || true
    
    # Step 5: Update Database
    ((current_step++))
    report_progress $current_step $total_steps "Updating database server"
    
    if command -v mariadb >/dev/null 2>&1 || command -v mariadb-server >/dev/null 2>&1; then
        log_message "INFO: Updating MariaDB"
        sudo apt install --only-upgrade -y mariadb-server
    fi
    
    # Step 6: Update Redis
    ((current_step++))
    report_progress $current_step $total_steps "Updating Redis server"
    
    if command -v redis-server >/dev/null 2>&1; then
        log_message "INFO: Updating Redis"
        sudo apt install --only-upgrade -y redis-server php-redis
    fi
    
    # Step 7: Update WP-CLI
    ((current_step++))
    report_progress $current_step $total_steps "Updating WP-CLI"
    
    if command -v wp >/dev/null 2>&1; then
        log_message "INFO: Updating WP-CLI"
        sudo wp cli update --yes || true
    fi
    
    # Step 8: Update WordPress installations
    ((current_step++))
    report_progress $current_step $total_steps "Updating WordPress installations"
    
    local wp_updated=0
    for wpdir in /var/www/* /srv/www/* /home/*/public_html /tmp/wp_test_dir; do
        if [[ -d "$wpdir/wp-includes" ]]; then
            log_message "INFO: Updating WordPress in $wpdir"
            sudo -u www-data wp core update --path="$wpdir" 2>/dev/null || true
            sudo -u www-data wp plugin update --all --path="$wpdir" 2>/dev/null || true
            sudo -u www-data wp theme update --all --path="$wpdir" 2>/dev/null || true
            ((wp_updated++))
        fi
    done
    log_message "INFO: Updated $wp_updated WordPress installations"
    
    # Step 9: Update security and monitoring tools
    ((current_step++))
    report_progress $current_step $total_steps "Updating security and monitoring"
    
    log_message "INFO: Updating security and monitoring tools"
    sudo apt install --only-upgrade -y fail2ban netdata 2>/dev/null || true
    
    # Step 10: Update LOMP Stack components
    ((current_step++))
    report_progress $current_step $total_steps "Updating LOMP Stack components"
    
    # Update author info and other LOMP components if update script exists
    local author_update_script="$SCRIPT_DIR/update_author_info.sh"
    if [[ -f "$author_update_script" ]] && ! $AUTO_MODE; then
        log_message "INFO: Running author info update"
        echo "y" | bash "$author_update_script" >/dev/null 2>&1 || true
    fi
    
    # Restart services if needed
    log_message "INFO: Restarting updated services"
    for service in nginx apache2 php*-fpm mariadb mysql redis-server; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_message "INFO: Restarting $service"
            sudo systemctl restart "$service" 2>/dev/null || true
        fi
    done
    
    log_message "SUCCESS: All main components have been updated successfully!"
    
    if command -v print_author_footer >/dev/null 2>&1; then
        print_author_footer
    else
        echo "=============================================="
        echo "Update completed successfully!"
        echo "=============================================="
    fi
    
    return 0
}

# Function to show author info
show_author_info() {
    if command -v print_author_header >/dev/null 2>&1; then
        print_author_header
        echo
        echo "System Update Manager - Comprehensive LOMP Stack updates"
        echo "Updates all main components with proper logging and"
        echo "web interface integration support."
        echo
        print_author_footer
    else
        echo "=============================================="
        echo "   LOMP Stack v3.0 - System Update Manager"
        echo "=============================================="
        echo "Author: Silviu Ilie"
        echo "Email: neosilviu@gmail.com"
        echo "Company: aemdPC"
        echo "License: MIT"
        echo "Version: 3.0"
        echo "=============================================="
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Handle special commands
    if [[ "$1" == "--author-info" ]]; then
        show_author_info
        exit 0
    fi
    
    main "$@"
fi
