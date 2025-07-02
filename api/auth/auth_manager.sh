#!/bin/bash
#
# auth_manager.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - API Authentication Module
# JWT and API Key authentication system
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../helpers/utils/functions.sh"

# Authentication configuration
JWT_SECRET_FILE="${SCRIPT_DIR}/jwt_secret.key"
API_KEYS_FILE="${SCRIPT_DIR}/api_keys.json"

#########################################################################
# Generate JWT Secret
#########################################################################
generate_jwt_secret() {
    openssl rand -base64 64 > "$JWT_SECRET_FILE"
    chmod 600 "$JWT_SECRET_FILE"
    echo "JWT secret generated successfully"
}

#########################################################################
# Create API Key
#########################################################################
create_api_key() {
    local name="$1"
    local permissions="$2"
    local rate_limit="${3:-100}"
    
    local key
    key="sk_live_$(openssl rand -hex 32)"
    
    echo "API Key created: $key"
    echo "Name: $name"
    echo "Permissions: $permissions"
    echo "Rate Limit: $rate_limit requests/minute"
}

#########################################################################
# Validate API Key
#########################################################################
validate_api_key() {
    local api_key="$1"
    
    if [ -f "$API_KEYS_FILE" ]; then
        jq -r ".api_keys[] | select(.key == \"$api_key\") | .active" "$API_KEYS_FILE" 2>/dev/null
    else
        echo "false"
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "generate-secret")
            generate_jwt_secret
            ;;
        "create-key")
            create_api_key "$2" "$3" "$4"
            ;;
        "validate")
            validate_api_key "$2"
            ;;
        *)
            echo "Usage: $0 {generate-secret|create-key|validate}"
            ;;
    esac
fi
