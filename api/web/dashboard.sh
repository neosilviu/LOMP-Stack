#!/bin/bash
#
# dashboard.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v3.0 - Web Dashboard Launcher
# Launch the web-based API administration dashboard
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../helpers/utils/functions.sh"

# Define print functions
print_info() { color_echo cyan "[WEB-DASHBOARD] $*"; }
print_success() { color_echo green "[WEB-DASHBOARD] $*"; }
print_warning() { color_echo yellow "[WEB-DASHBOARD] $*"; }
print_error() { color_echo red "[WEB-DASHBOARD] $*"; }

# Configuration
WEB_DIR="$SCRIPT_DIR"
REQUIREMENTS_FILE="$WEB_DIR/requirements.txt"
DASHBOARD_PORT="${DASHBOARD_PORT:-5000}"
DASHBOARD_HOST="${DASHBOARD_HOST:-0.0.0.0}"

#########################################################################
# Install Dependencies
#########################################################################
install_dependencies() {
    print_info "Installing web dashboard dependencies..."
    
    # Check if Python 3 is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."
        return 1
    fi
    
    # Check if pip is installed
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed. Installing pip..."
        sudo apt-get update
        sudo apt-get install -y python3-pip
    fi
    
    # Create requirements.txt if it doesn't exist
    if [ ! -f "$REQUIREMENTS_FILE" ]; then
        print_info "Creating requirements.txt..."
        cat > "$REQUIREMENTS_FILE" << 'EOF'
Flask==2.3.3
Flask-Limiter==3.5.0
Werkzeug==2.3.7
Jinja2==3.1.2
MarkupSafe==2.1.3
itsdangerous==2.1.2
click==8.1.7
blinker==1.6.3
limits==3.6.0
packaging==23.1
deprecated==1.2.14
wrapt==1.15.0
typing_extensions==4.8.0
EOF
    fi
    
    # Install Python packages
    print_info "Installing Python packages..."
    pip3 install -r "$REQUIREMENTS_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Dependencies installed successfully"
        return 0
    else
        print_error "Failed to install dependencies"
        return 1
    fi
}

#########################################################################
# Check Prerequisites
#########################################################################
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing_deps=0
    
    # Check Python 3
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        missing_deps=1
    else
        print_success "Python 3 found: $(python3 --version)"
    fi
    
    # Check pip3
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is required but not installed"
        missing_deps=1
    else
        print_success "pip3 found: $(pip3 --version | head -n1)"
    fi
    
    # Check if Flask is installed
    if ! python3 -c "import flask" 2>/dev/null; then
        print_warning "Flask is not installed"
        missing_deps=1
    else
        print_success "Flask is available"
    fi
    
    return $missing_deps
}

#########################################################################
# Initialize Database
#########################################################################
init_database() {
    print_info "Initializing admin database..."
    
    python3 -c "
import sys
sys.path.append('$WEB_DIR')
from admin_dashboard import init_admin_db
init_admin_db()
print('Admin database initialized successfully')
"
    
    if [ $? -eq 0 ]; then
        print_success "Database initialized"
    else
        print_error "Failed to initialize database"
        return 1
    fi
}

#########################################################################
# Start Dashboard
#########################################################################
start_dashboard() {
    print_info "Starting web dashboard..."
    print_info "Dashboard will be available at: http://${DASHBOARD_HOST}:${DASHBOARD_PORT}"
    print_info "Default login: admin / admin123"
    print_warning "Please change default credentials after first login!"
    
    cd "$WEB_DIR" || exit
    
    # Set Flask environment variables
    export FLASK_APP=admin_dashboard.py
    export FLASK_ENV=development
    export FLASK_DEBUG=1
    
    # Start the dashboard
    python3 admin_dashboard.py
}

#########################################################################
# Stop Dashboard
#########################################################################
stop_dashboard() {
    print_info "Stopping web dashboard..."
    
    # Find and kill Flask processes
    local pids
    pids=$(pgrep -f "admin_dashboard.py")
    
    if [ -n "$pids" ]; then
        echo "$pids" | xargs kill -TERM
        print_success "Dashboard stopped"
    else
        print_warning "No running dashboard processes found"
    fi
}

#########################################################################
# Show Dashboard Status
#########################################################################
show_status() {
    print_info "Web Dashboard Status:"
    echo "======================"
    
    # Check if dashboard is running
    local pids
    pids=$(pgrep -f "admin_dashboard.py")
    
    if [ -n "$pids" ]; then
        print_success "Dashboard is running (PID: $pids)"
        print_info "URL: http://${DASHBOARD_HOST}:${DASHBOARD_PORT}"
        print_info "Admin login: admin / admin123"
    else
        print_warning "Dashboard is not running"
    fi
    
    # Check dependencies
    echo ""
    print_info "Dependencies:"
    if command -v python3 &> /dev/null; then
        print_success "Python 3: $(python3 --version)"
    else
        print_error "Python 3: Not installed"
    fi
    
    if python3 -c "import flask" 2>/dev/null; then
        local flask_version
        flask_version=$(python3 -c "import flask; print(flask.__version__)" 2>/dev/null)
        print_success "Flask: $flask_version"
    else
        print_error "Flask: Not installed"
    fi
    
    if python3 -c "import flask_limiter" 2>/dev/null; then
        print_success "Flask-Limiter: Available"
    else
        print_error "Flask-Limiter: Not installed"
    fi
}

#########################################################################
# Show Help
#########################################################################
show_help() {
    echo "LOMP Stack v3.0 - Web Dashboard Manager"
    echo "======================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install    Install required dependencies"
    echo "  start      Start the web dashboard"
    echo "  stop       Stop the web dashboard"
    echo "  restart    Restart the web dashboard"
    echo "  status     Show dashboard status"
    echo "  init       Initialize database and dependencies"
    echo "  help       Show this help message"
    echo ""
    echo "Dashboard URL: http://${DASHBOARD_HOST}:${DASHBOARD_PORT}"
    echo "Default login: admin / admin123"
    echo ""
    echo "Examples:"
    echo "  $0 install    # Install dependencies"
    echo "  $0 init       # Initialize everything"
    echo "  $0 start      # Start dashboard"
    echo "  $0 status     # Check status"
}

#########################################################################
# Main Function
#########################################################################
main() {
    case "${1:-help}" in
        "install")
            install_dependencies
            ;;
        "start")
            if ! check_prerequisites; then
                print_error "Prerequisites not met. Run '$0 install' first."
                exit 1
            fi
            start_dashboard
            ;;
        "stop")
            stop_dashboard
            ;;
        "restart")
            stop_dashboard
            sleep 2
            start_dashboard
            ;;
        "status")
            show_status
            ;;
        "init")
            print_info "Initializing web dashboard..."
            install_dependencies && init_database
            if [ $? -eq 0 ]; then
                print_success "Initialization complete!"
                print_info "You can now start the dashboard with: $0 start"
            else
                print_error "Initialization failed"
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
