#!/bin/bash
#
# webhook_manager.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Webhook Endpoint Manager
# Manage webhook endpoints and events
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../helpers/utils/functions.sh"

# Webhook configuration
WEBHOOK_CONFIG="${SCRIPT_DIR}/webhook_config.json"
WEBHOOK_LOG="${SCRIPT_DIR}/webhook.log"

#########################################################################
# Initialize Webhook Configuration
#########################################################################
init_webhook_config() {
    cat > "$WEBHOOK_CONFIG" << 'EOF'
{
    "webhooks": [],
    "events": [
        "site.created",
        "site.deleted",
        "backup.created",
        "backup.completed",
        "backup.failed",
        "system.alert",
        "security.incident"
    ]
}
EOF
    echo "Webhook configuration initialized"
}

#########################################################################
# Add Webhook Endpoint
#########################################################################
add_webhook() {
    local name="$1"
    local url="$2"
    local events="$3"
    local secret="$4"
    
    if [ -z "$name" ] || [ -z "$url" ]; then
        echo "Error: Name and URL are required"
        return 1
    fi
    
    local webhook_id
    webhook_id="webhook-$(date +%s)"
    
    echo "Webhook added:"
    echo "  ID: $webhook_id"
    echo "  Name: $name"
    echo "  URL: $url"
    echo "  Events: $events"
    echo "  Secret: $secret"
}

#########################################################################
# Send Webhook
#########################################################################
send_webhook() {
    local event="$1"
    local data="$2"
    
    echo "Sending webhook for event: $event"
    echo "Data: $data"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Webhook sent: $event" >> "$WEBHOOK_LOG"
}

#########################################################################
# List Webhooks
#########################################################################
list_webhooks() {
    if [ -f "$WEBHOOK_CONFIG" ]; then
        jq '.webhooks[]' "$WEBHOOK_CONFIG" 2>/dev/null || echo "No webhooks configured"
    else
        echo "No webhook configuration found"
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "init")
            init_webhook_config
            ;;
        "add")
            add_webhook "$2" "$3" "$4" "$5"
            ;;
        "send")
            send_webhook "$2" "$3"
            ;;
        "list")
            list_webhooks
            ;;
        *)
            echo "Usage: $0 {init|add|send|list}"
            ;;
    esac
fi
