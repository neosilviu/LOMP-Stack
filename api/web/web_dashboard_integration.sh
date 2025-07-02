#!/bin/bash
#
# web_dashboard_integration.sh - Part of LOMP Stack v3.0
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

#########################################################################
# LOMP Stack v3.0 - Web Dashboard Integration
# Integrate web dashboard with main stack management
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="$(cd "$(dirname "${SCRIPT_DIR}")" && pwd)"
STACK_ROOT="$(cd "$(dirname "${API_DIR}")" && pwd)"

# Source main functions
source "${STACK_ROOT}/helpers/utils/functions.sh"

# Dashboard configuration
DASHBOARD_DIR="${API_DIR}/web"
DASHBOARD_SCRIPT="${DASHBOARD_DIR}/admin_dashboard.py"
DASHBOARD_PS1="${DASHBOARD_DIR}/dashboard.ps1"
DASHBOARD_SH="${DASHBOARD_DIR}/dashboard.sh"

#########################################################################
# Print Functions
#########################################################################
print_dashboard_info() { color_echo cyan "[WEB-DASHBOARD] $*"; }
print_dashboard_success() { color_echo green "[WEB-DASHBOARD] $*"; }
print_dashboard_warning() { color_echo yellow "[WEB-DASHBOARD] $*"; }
print_dashboard_error() { color_echo red "[WEB-DASHBOARD] $*"; }

#########################################################################
# Check Dashboard Status
#########################################################################
check_dashboard_status() {
    print_dashboard_info "Checking web dashboard status..."
    
    local pid_file="${DASHBOARD_DIR}/dashboard.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            print_dashboard_success "Dashboard is running (PID: $pid)"
            print_dashboard_info "Dashboard URL: http://localhost:5000"
            return 0
        else
            print_dashboard_warning "Stale PID file found, removing..."
            rm -f "$pid_file"
        fi
    fi
    
    print_dashboard_warning "Dashboard is not running"
    return 1
}

#########################################################################
# Start Dashboard
#########################################################################
start_dashboard() {
    print_dashboard_info "Starting LOMP Stack Web Dashboard..."
    
    # Check if already running
    if check_dashboard_status >/dev/null 2>&1; then
        print_dashboard_warning "Dashboard is already running"
        return 0
    fi
    
    # Check if Python is available
    if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
        print_dashboard_error "Python is not installed or not in PATH"
        print_dashboard_info "Please install Python 3.7+ and try again"
        return 1
    fi
    
    # Use appropriate launcher based on OS
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows - use PowerShell script
        if [[ -f "$DASHBOARD_PS1" ]]; then
            print_dashboard_info "Using PowerShell launcher..."
            powershell -ExecutionPolicy Bypass -File "$DASHBOARD_PS1" start
        else
            print_dashboard_error "PowerShell launcher not found: $DASHBOARD_PS1"
            return 1
        fi
    else
        # Linux/macOS - use bash script or direct Python
        if [[ -f "$DASHBOARD_SH" ]]; then
            print_dashboard_info "Using bash launcher..."
            bash "$DASHBOARD_SH" start
        elif [[ -f "$DASHBOARD_SCRIPT" ]]; then
            print_dashboard_info "Starting dashboard directly..."
            cd "$DASHBOARD_DIR" || return 1
            
            # Install dependencies if needed
            if [[ -f "requirements.txt" ]]; then
                print_dashboard_info "Installing dependencies..."
                python3 -m pip install -r requirements.txt >/dev/null 2>&1 || {
                    python -m pip install -r requirements.txt >/dev/null 2>&1
                }
            fi
            
            # Start dashboard in background
            nohup python3 "$DASHBOARD_SCRIPT" > dashboard.log 2>&1 &
            echo $! > dashboard.pid
            
            print_dashboard_success "Dashboard started successfully!"
            print_dashboard_info "Dashboard URL: http://localhost:5000"
            print_dashboard_info "Default Login: admin / admin123"
            print_dashboard_warning "Please change the default password after first login!"
        else
            print_dashboard_error "Dashboard script not found: $DASHBOARD_SCRIPT"
            return 1
        fi
    fi
}

#########################################################################
# Stop Dashboard
#########################################################################
stop_dashboard() {
    print_dashboard_info "Stopping LOMP Stack Web Dashboard..."
    
    local pid_file="${DASHBOARD_DIR}/dashboard.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            print_dashboard_info "Stopping dashboard process (PID: $pid)..."
            kill "$pid" 2>/dev/null
            
            # Wait for process to stop
            local count=0
            while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                sleep 1
                count=$((count + 1))
            done
            
            if kill -0 "$pid" 2>/dev/null; then
                print_dashboard_warning "Force killing dashboard process..."
                kill -9 "$pid" 2>/dev/null
            fi
            
            print_dashboard_success "Dashboard stopped successfully"
        else
            print_dashboard_warning "Dashboard process not found (PID: $pid)"
        fi
        
        rm -f "$pid_file"
    else
        print_dashboard_warning "Dashboard is not running (no PID file found)"
    fi
    
    # Also try to use platform-specific stop
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        if [[ -f "$DASHBOARD_PS1" ]]; then
            powershell -ExecutionPolicy Bypass -File "$DASHBOARD_PS1" stop 2>/dev/null
        fi
    else
        if [[ -f "$DASHBOARD_SH" ]]; then
            bash "$DASHBOARD_SH" stop 2>/dev/null
        fi
    fi
}

#########################################################################
# Restart Dashboard
#########################################################################
restart_dashboard() {
    print_dashboard_info "Restarting LOMP Stack Web Dashboard..."
    stop_dashboard
    sleep 2
    start_dashboard
}

#########################################################################
# Install Dashboard Dependencies
#########################################################################
install_dashboard() {
    print_dashboard_info "Installing web dashboard dependencies..."
    
    # Check if dashboard directory exists
    if [[ ! -d "$DASHBOARD_DIR" ]]; then
        print_dashboard_error "Dashboard directory not found: $DASHBOARD_DIR"
        return 1
    fi
    
    cd "$DASHBOARD_DIR" || return 1
    
    # Use appropriate installer based on OS
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows - use PowerShell script
        if [[ -f "$DASHBOARD_PS1" ]]; then
            powershell -ExecutionPolicy Bypass -File "$DASHBOARD_PS1" install
        else
            print_dashboard_error "PowerShell installer not found"
            return 1
        fi
    else
        # Linux/macOS - use pip directly
        if [[ -f "requirements.txt" ]]; then
            print_dashboard_info "Installing Python dependencies..."
            python3 -m pip install -r requirements.txt || {
                python -m pip install -r requirements.txt
            }
            print_dashboard_success "Dependencies installed successfully"
        else
            print_dashboard_error "requirements.txt not found"
            return 1
        fi
    fi
}

#########################################################################
# Open Dashboard in Browser
#########################################################################
open_dashboard() {
    print_dashboard_info "Opening dashboard in browser..."
    
    local url="http://localhost:5000"
    
    # Check if dashboard is running
    if ! check_dashboard_status >/dev/null 2>&1; then
        print_dashboard_warning "Dashboard is not running. Starting it now..."
        start_dashboard || return 1
        sleep 3
    fi
    
    # Open browser based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open "$url"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$url"
        elif command -v firefox >/dev/null 2>&1; then
            firefox "$url" &
        elif command -v google-chrome >/dev/null 2>&1; then
            google-chrome "$url" &
        else
            print_dashboard_info "Please open your browser and navigate to: $url"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows
        start "$url"
    else
        print_dashboard_info "Please open your browser and navigate to: $url"
    fi
}

#########################################################################
# Dashboard Menu
#########################################################################
show_dashboard_menu() {
    echo ""
    color_echo magenta "🌐 LOMP Stack v3.0 - Web Dashboard Management"
    color_echo magenta "=============================================="
    echo ""
    
    check_dashboard_status
    
    echo ""
    color_echo cyan "Available Actions:"
    echo "1. Start Dashboard"
    echo "2. Stop Dashboard"
    echo "3. Restart Dashboard"
    echo "4. Install Dependencies"
    echo "5. Open in Browser"
    echo "6. Check Status"
    echo "7. View Dashboard Logs"
    echo "0. Return to Main Menu"
    echo ""
    
    read -p "Select an option [0-7]: " choice
    
    case $choice in
        1)
            start_dashboard
            ;;
        2)
            stop_dashboard
            ;;
        3)
            restart_dashboard
            ;;
        4)
            install_dashboard
            ;;
        5)
            open_dashboard
            ;;
        6)
            check_dashboard_status
            ;;
        7)
            view_dashboard_logs
            ;;
        0)
            return 0
            ;;
        *)
            print_dashboard_error "Invalid option: $choice"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_dashboard_menu
}

#########################################################################
# View Dashboard Logs
#########################################################################
view_dashboard_logs() {
    print_dashboard_info "Viewing dashboard logs..."
    
    local log_file="${DASHBOARD_DIR}/dashboard.log"
    
    if [[ -f "$log_file" ]]; then
        echo ""
        color_echo cyan "=== Dashboard Logs ==="
        tail -50 "$log_file"
        echo ""
        color_echo cyan "======================"
    else
        print_dashboard_warning "No log file found: $log_file"
    fi
}

#########################################################################
# Main Execution
#########################################################################

# If script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-menu}" in
        "start")
            start_dashboard
            ;;
        "stop")
            stop_dashboard
            ;;
        "restart")
            restart_dashboard
            ;;
        "status")
            check_dashboard_status
            ;;
        "install")
            install_dashboard
            ;;
        "open")
            open_dashboard
            ;;
        "logs")
            view_dashboard_logs
            ;;
        "menu")
            show_dashboard_menu
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|install|open|logs|menu}"
            echo ""
            echo "Commands:"
            echo "  start    - Start the web dashboard"
            echo "  stop     - Stop the web dashboard"
            echo "  restart  - Restart the web dashboard"
            echo "  status   - Check dashboard status"
            echo "  install  - Install dependencies"
            echo "  open     - Open dashboard in browser"
            echo "  logs     - View dashboard logs"
            echo "  menu     - Show interactive menu"
            ;;
    esac
fi
