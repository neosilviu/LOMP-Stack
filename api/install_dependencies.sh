#!/bin/bash
#
# install_dependencies.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - API Dependencies Installer
# Install all required dependencies for the API Management System
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

print_info() { color_echo cyan "[INSTALL] $*"; }
print_success() { color_echo green "[SUCCESS] $*"; }
print_error() { color_echo red "[ERROR] $*"; }

#########################################################################
# Install Python3 and pip3
#########################################################################
install_python_deps() {
    print_info "Installing Python dependencies..."
    
    # Update package list
    sudo apt-get update -y
    
    # Install Python3 and pip3
    sudo apt-get install -y python3 python3-pip python3-venv
    
    # Install required Python packages
    pip3 install --user flask flask-jwt-extended flask-limiter flask-cors requests
    
    print_success "Python dependencies installed"
}

#########################################################################
# Install Node.js and npm
#########################################################################
install_nodejs() {
    print_info "Installing Node.js..."
    
    # Install Node.js from NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Install PM2 for process management
    sudo npm install -g pm2
    
    print_success "Node.js and PM2 installed"
}

#########################################################################
# Install System Dependencies
#########################################################################
install_system_deps() {
    print_info "Installing system dependencies..."
    
    sudo apt-get update -y
    sudo apt-get install -y curl jq openssl sqlite3
    
    print_success "System dependencies installed"
}

#########################################################################
# Main Installation
#########################################################################
main() {
    print_info "Starting API dependencies installation..."
    
    install_system_deps
    install_python_deps
    install_nodejs
    
    print_success "All dependencies installed successfully!"
    print_info "You can now run the API Management System"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
