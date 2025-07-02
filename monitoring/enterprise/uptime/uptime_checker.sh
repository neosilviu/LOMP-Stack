#!/bin/bash
#
# uptime_checker.sh - Part of LOMP Stack v3.0
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../monitoring_config.json"
DATA_DIR="${SCRIPT_DIR}/../data"

check_endpoint() {
    local name="$1"
    local url="$2"
    local type="$3"
    local timestamp=$(date +%s)
    local status="UP"
    local response_time=0
    
    if [ "$type" = "http" ]; then
        local start_time=$(date +%s%3N)
        if curl -s --max-time 30 "$url" > /dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            response_time=$((end_time - start_time))
        else
            status="DOWN"
        fi
    elif [ "$type" = "tcp" ]; then
        local host=$(echo "$url" | cut -d: -f1)
        local port=$(echo "$url" | cut -d: -f2)
        if timeout 10 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
            response_time=50  # TCP check is fast
        else
            status="DOWN"
        fi
    fi
    
    # Log result
    echo "{\"timestamp\":$timestamp,\"name\":\"$name\",\"status\":\"$status\",\"response_time\":$response_time}" >> "${DATA_DIR}/uptime_$(date +%Y%m%d).jsonl"
    
    # Check for alerts
    if [ "$status" = "DOWN" ]; then
        echo "ALERT: $name is DOWN at $(date)" >> "${DATA_DIR}/alerts.log"
    fi
}

# Read endpoints and check them
if [ -f "$CONFIG_FILE" ]; then
    endpoints=$(cat "$CONFIG_FILE" | jq -r '.endpoints[] | "\(.name)|\(.url)|\(.type)"')
    while IFS='|' read -r name url type; do
        check_endpoint "$name" "$url" "$type"
    done <<< "$endpoints"
fi
