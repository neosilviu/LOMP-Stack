#!/bin/bash
#
# apm_collector.sh - Part of LOMP Stack v3.0
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

collect_system_metrics() {
    local timestamp=$(date +%s)
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'u' -f1)
    
    # Memory usage
    local mem_total=$(free | grep Mem | awk '{print $2}')
    local mem_used=$(free | grep Mem | awk '{print $3}')
    local mem_usage=$((mem_used * 100 / mem_total))
    
    # Disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)
    
    # Process count
    local process_count=$(ps aux | wc -l)
    
    # Network connections
    local tcp_connections=$(netstat -ant | grep ESTABLISHED | wc -l)
    
    # Save metrics
    echo "{\"timestamp\":$timestamp,\"cpu_usage\":$cpu_usage,\"memory_usage\":$mem_usage,\"disk_usage\":$disk_usage,\"load_avg\":$load_avg,\"process_count\":$process_count,\"tcp_connections\":$tcp_connections}" >> "${DATA_DIR}/apm_$(date +%Y%m%d).jsonl"
}

collect_web_metrics() {
    local timestamp=$(date +%s)
    
    # Analyze web server logs if they exist
    if [ -f "/var/log/nginx/access.log" ]; then
        local requests_last_minute=$(tail -1000 /var/log/nginx/access.log | awk -v since="$(date -d '1 minute ago' +'%d/%b/%Y:%H:%M')" '$4 > "["since' | wc -l)
        local avg_response_time=$(tail -1000 /var/log/nginx/access.log | awk '{print $10}' | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
        local error_rate=$(tail -1000 /var/log/nginx/access.log | awk '$9>=400' | wc -l)
        
        echo "{\"timestamp\":$timestamp,\"requests_per_minute\":$requests_last_minute,\"avg_response_time\":$avg_response_time,\"error_count\":$error_rate}" >> "${DATA_DIR}/web_metrics_$(date +%Y%m%d).jsonl"
    fi
}

# Collect metrics
collect_system_metrics
collect_web_metrics
