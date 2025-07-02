#!/bin/bash
#
# log_analyzer.sh - Part of LOMP Stack v3.0
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
DATA_DIR="${SCRIPT_DIR}/../data"

analyze_logs() {
    local timestamp=$(date +%s)
    local log_files=("/var/log/nginx/error.log" "/var/log/apache2/error.log" "/var/log/mysql/error.log" "/var/log/syslog")
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            local log_name=$(basename "$log_file" .log)
            
            # Count errors in last hour
            local errors_last_hour=$(grep "$(date -d '1 hour ago' +'%Y-%m-%d %H')" "$log_file" 2>/dev/null | grep -i error | wc -l)
            
            # Count warnings in last hour
            local warnings_last_hour=$(grep "$(date -d '1 hour ago' +'%Y-%m-%d %H')" "$log_file" 2>/dev/null | grep -i warn | wc -l)
            
            # Save analysis
            echo "{\"timestamp\":$timestamp,\"log_source\":\"$log_name\",\"errors_last_hour\":$errors_last_hour,\"warnings_last_hour\":$warnings_last_hour}" >> "${DATA_DIR}/log_analysis_$(date +%Y%m%d).jsonl"
            
            # Alert on high error rates
            if [ "$errors_last_hour" -gt 10 ]; then
                echo "ALERT: High error rate in $log_file: $errors_last_hour errors in last hour" >> "${DATA_DIR}/alerts.log"
            fi
        fi
    done
}

# Run analysis
analyze_logs
