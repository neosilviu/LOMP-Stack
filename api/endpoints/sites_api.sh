#!/bin/bash
#
# sites_api.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Site Management API Endpoints
# REST API endpoints for WordPress site management
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../helpers/utils/functions.sh"

#########################################################################
# List All Sites
#########################################################################
api_list_sites() {
    echo "Content-Type: application/json"
    echo ""
    
    local sites
    sites=$(find /var/www -maxdepth 1 -type d -name "*.com" -o -name "*.org" -o -name "*.net" 2>/dev/null)
    
    echo "{"
    echo "  \"success\": true,"
    echo "  \"data\": {"
    echo "    \"sites\": ["
    
    local first=true
    for site in $sites; do
        local domain
        domain=$(basename "$site")
        
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        
        echo "      {"
        echo "        \"domain\": \"$domain\","
        echo "        \"path\": \"$site\","
        echo "        \"status\": \"active\""
        echo "      }"
    done
    
    echo "    ]"
    echo "  },"
    echo "  \"count\": $(echo "$sites" | wc -l)"
    echo "}"
}

#########################################################################
# Get Site Details
#########################################################################
api_get_site() {
    local domain="$1"
    
    echo "Content-Type: application/json"
    echo ""
    
    if [ -z "$domain" ]; then
        echo "{"
        echo "  \"error\": \"Domain parameter is required\""
        echo "}"
        return 1
    fi
    
    local site_path="/var/www/$domain"
    
    if [ ! -d "$site_path" ]; then
        echo "{"
        echo "  \"error\": \"Site not found\""
        echo "}"
        return 1
    fi
    
    echo "{"
    echo "  \"success\": true,"
    echo "  \"data\": {"
    echo "    \"domain\": \"$domain\","
    echo "    \"path\": \"$site_path\","
    echo "    \"status\": \"active\","
    echo "    \"created_at\": \"$(stat -c %y "$site_path" | cut -d' ' -f1)\""
    echo "  }"
    echo "}"
}

#########################################################################
# Create New Site
#########################################################################
api_create_site() {
    local domain="$1"
    local email="$2"
    
    echo "Content-Type: application/json"
    echo ""
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        echo "{"
        echo "  \"error\": \"Domain and email parameters are required\""
        echo "}"
        return 1
    fi
    
    # Simulate site creation (replace with actual implementation)
    echo "{"
    echo "  \"success\": true,"
    echo "  \"message\": \"Site $domain created successfully\","
    echo "  \"data\": {"
    echo "    \"domain\": \"$domain\","
    echo "    \"email\": \"$email\","
    echo "    \"created_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    echo "  }"
    echo "}"
}

#########################################################################
# Delete Site
#########################################################################
api_delete_site() {
    local domain="$1"
    
    echo "Content-Type: application/json"
    echo ""
    
    if [ -z "$domain" ]; then
        echo "{"
        echo "  \"error\": \"Domain parameter is required\""
        echo "}"
        return 1
    fi
    
    # Simulate site deletion (replace with actual implementation)
    echo "{"
    echo "  \"success\": true,"
    echo "  \"message\": \"Site $domain deleted successfully\""
    echo "}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "list")
            api_list_sites
            ;;
        "get")
            api_get_site "$2"
            ;;
        "create")
            api_create_site "$2" "$3"
            ;;
        "delete")
            api_delete_site "$2"
            ;;
        *)
            echo "Usage: $0 {list|get|create|delete}"
            ;;
    esac
fi
