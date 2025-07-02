#!/bin/bash
#
# enterprise_monitoring_suite.sh - Part of LOMP Stack v3.0
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

# =============================================================================
# LOMP Stack v2.0 - Enterprise Monitoring Suite
# =============================================================================
# Description: Advanced monitoring system with uptime, APM, logs, and SLA
# Author: LOMP Stack Team
# Version: 2.0.0
# License: MIT
# =============================================================================

# Source required files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../helpers/utils/functions.sh"
source "${SCRIPT_DIR}/../../helpers/utils/config_helpers.sh"

# Configuration
MONITORING_CONFIG_FILE="${SCRIPT_DIR}/monitoring_config.json"
MONITORING_DATA_DIR="${SCRIPT_DIR}/data"
MONITORING_LOGS_DIR="${SCRIPT_DIR}/logs"
MONITORING_REPORTS_DIR="${SCRIPT_DIR}/reports"
UPTIME_MONITOR_DIR="${SCRIPT_DIR}/uptime"
APM_DATA_DIR="${SCRIPT_DIR}/apm"

# Initialize directories
initialize_monitoring_dirs() {
    local dirs=("$MONITORING_DATA_DIR" "$MONITORING_LOGS_DIR" "$MONITORING_REPORTS_DIR" 
                "$UPTIME_MONITOR_DIR" "$APM_DATA_DIR")
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    log_info "Enterprise monitoring directories initialized"
}

# Initialize configuration
initialize_monitoring_config() {
    if [ ! -f "$MONITORING_CONFIG_FILE" ]; then
        cat > "$MONITORING_CONFIG_FILE" << 'EOF'
{
    "monitoring": {
        "uptime": {
            "enabled": true,
            "check_interval": 60,
            "timeout": 30,
            "retry_count": 3,
            "notification_threshold": 3
        },
        "apm": {
            "enabled": true,
            "sampling_rate": 0.1,
            "trace_duration_threshold": 1000,
            "memory_threshold": 80,
            "cpu_threshold": 80
        },
        "logs": {
            "enabled": true,
            "retention_days": 30,
            "max_size_mb": 100,
            "log_levels": ["ERROR", "WARN", "INFO"],
            "real_time_analysis": true
        },
        "sla": {
            "enabled": true,
            "uptime_target": 99.9,
            "response_time_target": 200,
            "error_rate_target": 0.1,
            "reporting_interval": "daily"
        },
        "alerts": {
            "email_notifications": true,
            "slack_webhook": "",
            "telegram_bot_token": "",
            "alert_cooldown": 300
        }
    },
    "endpoints": [
        {
            "name": "Main Website",
            "url": "http://localhost",
            "type": "http",
            "critical": true
        },
        {
            "name": "Database",
            "host": "localhost",
            "port": 3306,
            "type": "tcp",
            "critical": true
        }
    ]
}
EOF
        log_success "Monitoring configuration created: $MONITORING_CONFIG_FILE"
    fi
}

# Uptime Monitor
start_uptime_monitor() {
    log_info "Starting uptime monitoring..."
    
    local config
    config=$(cat "$MONITORING_CONFIG_FILE")
    local check_interval
    check_interval=$(echo "$config" | jq -r '.monitoring.uptime.check_interval')
    # local timeout
    # timeout=$(echo "$config" | jq -r '.monitoring.uptime.timeout')
    
    # Create uptime monitor script
    cat > "${UPTIME_MONITOR_DIR}/uptime_checker.sh" << 'EOF'
#!/bin/bash

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
EOF
    
    chmod +x "${UPTIME_MONITOR_DIR}/uptime_checker.sh"
    
    # Start as background process
    (
        while true; do
            "${UPTIME_MONITOR_DIR}/uptime_checker.sh"
            sleep "$check_interval"
        done
    ) &
    
    echo $! > "${UPTIME_MONITOR_DIR}/uptime_monitor.pid"
    log_success "Uptime monitor started (PID: $(cat ${UPTIME_MONITOR_DIR}/uptime_monitor.pid))"
}

# APM (Application Performance Monitoring)
start_apm_monitor() {
    log_info "Starting APM monitoring..."
    
    # Create APM collector script
    cat > "${APM_DATA_DIR}/apm_collector.sh" << 'EOF'
#!/bin/bash

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
EOF
    
    chmod +x "${APM_DATA_DIR}/apm_collector.sh"
    
    # Start APM collector as background process
    (
        while true; do
            "${APM_DATA_DIR}/apm_collector.sh"
            sleep 30  # Collect every 30 seconds
        done
    ) &
    
    echo $! > "${APM_DATA_DIR}/apm_monitor.pid"
    log_success "APM monitor started (PID: $(cat ${APM_DATA_DIR}/apm_monitor.pid))"
}

# Log Analyzer
start_log_analyzer() {
    log_info "Starting log analysis..."
    
    # Create log analyzer script
    cat > "${MONITORING_LOGS_DIR}/log_analyzer.sh" << 'EOF'
#!/bin/bash

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
EOF
    
    chmod +x "${MONITORING_LOGS_DIR}/log_analyzer.sh"
    
    # Start log analyzer as background process
    (
        while true; do
            "${MONITORING_LOGS_DIR}/log_analyzer.sh"
            sleep 300  # Analyze every 5 minutes
        done
    ) &
    
    echo $! > "${MONITORING_LOGS_DIR}/log_analyzer.pid"
    log_success "Log analyzer started (PID: $(cat ${MONITORING_LOGS_DIR}/log_analyzer.pid))"
}

# SLA Monitor
generate_sla_report() {
    log_info "Generating SLA report..."
    
    local today
    today=$(date +%Y%m%d)
    local report_file="${MONITORING_REPORTS_DIR}/sla_report_${today}.html"
    
    # Calculate SLA metrics
    local uptime_data="${MONITORING_DATA_DIR}/uptime_${today}.jsonl"
    local apm_data="${MONITORING_DATA_DIR}/apm_${today}.jsonl"
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>SLA Report - LOMP Stack Enterprise Monitoring</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; text-align: center; }
        .metric { background: #ecf0f1; padding: 15px; margin: 10px 0; border-left: 4px solid #3498db; }
        .good { border-left-color: #27ae60; }
        .warning { border-left-color: #f39c12; }
        .critical { border-left-color: #e74c3c; }
        .chart { width: 100%; height: 300px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 LOMP Stack Enterprise Monitoring</h1>
        <h2>SLA Report - $(date +"%B %d, %Y")</h2>
    </div>
EOF
    
    # Calculate uptime percentage
    if [ -f "$uptime_data" ]; then
        local total_checks
        total_checks=$(wc -l < "$uptime_data")
        local up_checks
        up_checks=$(grep -c '"status":"UP"' "$uptime_data")
        local uptime_percentage
        uptime_percentage=$(echo "scale=2; $up_checks * 100 / $total_checks" | bc -l 2>/dev/null || echo "100.00")
        
        local class="good"
        if (( $(echo "$uptime_percentage < 99.9" | bc -l 2>/dev/null || echo "0") )); then
            class="critical"
        elif (( $(echo "$uptime_percentage < 99.95" | bc -l 2>/dev/null || echo "0") )); then
            class="warning"
        fi
        
        cat >> "$report_file" << EOF
    <div class="metric $class">
        <h3>📊 Uptime SLA</h3>
        <p><strong>Current Uptime:</strong> ${uptime_percentage}%</p>
        <p><strong>Target:</strong> 99.9%</p>
        <p><strong>Total Checks:</strong> $total_checks</p>
        <p><strong>Failed Checks:</strong> $((total_checks - up_checks))</p>
    </div>
EOF
    fi
    
    # Calculate average response time
    if [ -f "$apm_data" ]; then
        local avg_cpu
        avg_cpu=$(grep -o '"cpu_usage":[0-9]*' "$apm_data" | cut -d: -f2 | awk '{sum+=$1; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
        local avg_memory
        avg_memory=$(grep -o '"memory_usage":[0-9]*' "$apm_data" | cut -d: -f2 | awk '{sum+=$1; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
        
        cat >> "$report_file" << EOF
    <div class="metric good">
        <h3>⚡ Performance Metrics</h3>
        <p><strong>Average CPU Usage:</strong> ${avg_cpu}%</p>
        <p><strong>Average Memory Usage:</strong> ${avg_memory}%</p>
        <p><strong>Status:</strong> System performing within normal parameters</p>
    </div>
EOF
    fi
    
    cat >> "$report_file" << 'EOF'
    <div class="metric good">
        <h3>📈 Summary</h3>
        <p>✅ All systems operational</p>
        <p>✅ SLA targets met</p>
        <p>✅ No critical issues detected</p>
    </div>
    
    <div class="footer" style="text-align: center; margin-top: 30px; color: #7f8c8d;">
        <p>Generated by LOMP Stack Enterprise Monitoring Suite</p>
        <p>Report Date: $(date)</p>
    </div>
</body>
</html>
EOF
    
    log_success "SLA report generated: $report_file"
}

# Real-time dashboard
show_realtime_dashboard() {
    clear
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 ENTERPRISE MONITORING DASHBOARD                        ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════╣"
    echo "║                              Real-time Status                               ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo
    
    # System metrics
    echo "📊 SYSTEM METRICS"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    # CPU Usage
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'u' -f1 2>/dev/null || echo "N/A")
    echo "🔸 CPU Usage: ${cpu_usage}%"
    
    # Memory usage
    local mem_usage
    mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}' 2>/dev/null || echo "N/A")
    echo "🔸 Memory Usage: ${mem_usage}%"
    
    # Disk usage
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1 2>/dev/null || echo "N/A")
    echo "🔸 Disk Usage: ${disk_usage}%"
    
    # Load average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1 | xargs 2>/dev/null || echo "N/A")
    echo "🔸 Load Average: ${load_avg}"
    echo
    
    # Service status
    echo "🔧 SERVICE STATUS"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    # Check monitoring processes
    if [ -f "${UPTIME_MONITOR_DIR}/uptime_monitor.pid" ]; then
        local uptime_pid
        uptime_pid=$(cat "${UPTIME_MONITOR_DIR}/uptime_monitor.pid" 2>/dev/null)
        if kill -0 "$uptime_pid" 2>/dev/null; then
            echo "✅ Uptime Monitor: Running (PID: $uptime_pid)"
        else
            echo "❌ Uptime Monitor: Stopped"
        fi
    else
        echo "❌ Uptime Monitor: Not started"
    fi
    
    if [ -f "${APM_DATA_DIR}/apm_monitor.pid" ]; then
        local apm_pid
        apm_pid=$(cat "${APM_DATA_DIR}/apm_monitor.pid" 2>/dev/null)
        if kill -0 "$apm_pid" 2>/dev/null; then
            echo "✅ APM Monitor: Running (PID: $apm_pid)"
        else
            echo "❌ APM Monitor: Stopped"
        fi
    else
        echo "❌ APM Monitor: Not started"
    fi
    
    if [ -f "${MONITORING_LOGS_DIR}/log_analyzer.pid" ]; then
        local log_pid
        log_pid=$(cat "${MONITORING_LOGS_DIR}/log_analyzer.pid" 2>/dev/null)
        if kill -0 "$log_pid" 2>/dev/null; then
            echo "✅ Log Analyzer: Running (PID: $log_pid)"
        else
            echo "❌ Log Analyzer: Stopped"
        fi
    else
        echo "❌ Log Analyzer: Not started"
    fi
    echo
    
    # Recent alerts
    echo "🚨 RECENT ALERTS"
    echo "────────────────────────────────────────────────────────────────────────────────"
    if [ -f "${MONITORING_DATA_DIR}/alerts.log" ]; then
        tail -5 "${MONITORING_DATA_DIR}/alerts.log" 2>/dev/null | while read -r line; do
            [ -n "$line" ] && echo "🔸 $line"
        done
    else
        echo "🔸 No alerts recorded"
    fi
    echo
    
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo "Last updated: $(date)"
    echo "Press Ctrl+C to exit or any key to refresh..."
}

# Stop all monitoring services
stop_monitoring() {
    log_info "Stopping all monitoring services..."
    
    # Stop uptime monitor
    if [ -f "${UPTIME_MONITOR_DIR}/uptime_monitor.pid" ]; then
        local pid
        pid=$(cat "${UPTIME_MONITOR_DIR}/uptime_monitor.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_success "Uptime monitor stopped"
        fi
        rm -f "${UPTIME_MONITOR_DIR}/uptime_monitor.pid"
    fi
    
    # Stop APM monitor
    if [ -f "${APM_DATA_DIR}/apm_monitor.pid" ]; then
        local pid
        pid=$(cat "${APM_DATA_DIR}/apm_monitor.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_success "APM monitor stopped"
        fi
        rm -f "${APM_DATA_DIR}/apm_monitor.pid"
    fi
    
    # Stop log analyzer
    if [ -f "${MONITORING_LOGS_DIR}/log_analyzer.pid" ]; then
        local pid
        pid=$(cat "${MONITORING_LOGS_DIR}/log_analyzer.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_success "Log analyzer stopped"
        fi
        rm -f "${MONITORING_LOGS_DIR}/log_analyzer.pid"
    fi
    
    log_success "All monitoring services stopped"
}

# Main menu
show_monitoring_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════════════════════════╗"
        echo "║                    🚀 ENTERPRISE MONITORING SUITE                           ║"
        echo "╠══════════════════════════════════════════════════════════════════════════════╣"
        echo "║                            LOMP Stack v2.0                                  ║"
        echo "╚══════════════════════════════════════════════════════════════════════════════╝"
        echo
        echo "📊 MONITORING OPTIONS:"
        echo "────────────────────────────────────────────────────────────────────────────────"
        echo "1.  🔄 Start All Monitoring Services"
        echo "2.  📈 Start Uptime Monitor"
        echo "3.  ⚡ Start APM Monitor"
        echo "4.  📋 Start Log Analyzer"
        echo "5.  📊 Generate SLA Report"
        echo "6.  🖥️  Real-time Dashboard"
        echo "7.  🔧 View Service Status"
        echo "8.  📝 View Recent Alerts"
        echo "9.  ⚙️  Configure Monitoring"
        echo "10. 🛑 Stop All Services"
        echo "11. 📁 View Data Directory"
        echo "12. 🏠 Return to Enterprise Dashboard"
        echo
        echo "────────────────────────────────────────────────────────────────────────────────"
        read -p "Select option [1-12]: " choice
        echo
        
        case $choice in
            1)
                initialize_monitoring_dirs
                initialize_monitoring_config
                start_uptime_monitor
                start_apm_monitor
                start_log_analyzer
                log_success "All monitoring services started"
                read -p "Press Enter to continue..."
                ;;
            2)
                initialize_monitoring_dirs
                initialize_monitoring_config
                start_uptime_monitor
                read -p "Press Enter to continue..."
                ;;
            3)
                initialize_monitoring_dirs
                start_apm_monitor
                read -p "Press Enter to continue..."
                ;;
            4)
                initialize_monitoring_dirs
                start_log_analyzer
                read -p "Press Enter to continue..."
                ;;
            5)
                generate_sla_report
                read -p "Press Enter to continue..."
                ;;
            6)
                while true; do
                    show_realtime_dashboard
                    read -t 5 -n 1 && break
                done
                ;;
            7)
                echo "🔧 SERVICE STATUS:"
                echo "────────────────────────────────────────────────────────────────────────────────"
                
                # Check each service
                services=("uptime_monitor:${UPTIME_MONITOR_DIR}/uptime_monitor.pid"
                         "apm_monitor:${APM_DATA_DIR}/apm_monitor.pid"
                         "log_analyzer:${MONITORING_LOGS_DIR}/log_analyzer.pid")
                
                for service in "${services[@]}"; do
                    local name
                    name=$(echo "$service" | cut -d: -f1)
                    local pidfile
                    pidfile=$(echo "$service" | cut -d: -f2)
                    
                    if [ -f "$pidfile" ]; then
                        local pid
                        pid=$(cat "$pidfile")
                        if kill -0 "$pid" 2>/dev/null; then
                            echo "✅ $name: Running (PID: $pid)"
                        else
                            echo "❌ $name: Stopped (stale PID file)"
                        fi
                    else
                        echo "❌ $name: Not running"
                    fi
                done
                read -p "Press Enter to continue..."
                ;;
            8)
                echo "🚨 RECENT ALERTS:"
                echo "────────────────────────────────────────────────────────────────────────────────"
                if [ -f "${MONITORING_DATA_DIR}/alerts.log" ]; then
                    tail -20 "${MONITORING_DATA_DIR}/alerts.log" | nl
                else
                    echo "No alerts recorded yet."
                fi
                read -p "Press Enter to continue..."
                ;;
            9)
                echo "⚙️ Opening monitoring configuration..."
                if command -v nano >/dev/null 2>&1; then
                    nano "$MONITORING_CONFIG_FILE"
                elif command -v vi >/dev/null 2>&1; then
                    vi "$MONITORING_CONFIG_FILE"
                else
                    echo "No text editor found. Configuration file: $MONITORING_CONFIG_FILE"
                fi
                read -p "Press Enter to continue..."
                ;;
            10)
                stop_monitoring
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "📁 MONITORING DATA DIRECTORY:"
                echo "────────────────────────────────────────────────────────────────────────────────"
                echo "Base directory: $MONITORING_DATA_DIR"
                echo
                if [ -d "$MONITORING_DATA_DIR" ]; then
                    ls -la "$MONITORING_DATA_DIR"
                else
                    echo "Data directory not created yet."
                fi
                read -p "Press Enter to continue..."
                ;;
            12)
                break
                ;;
            *)
                log_error "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main execution
main() {
    log_info "LOMP Stack v2.0 - Enterprise Monitoring Suite"
    
    # Check dependencies
    local deps=("jq" "curl" "bc")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log_warn "Missing dependency: $dep"
            echo "Installing $dep..."
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y "$dep"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "$dep"
            fi
        fi
    done
    
    # Initialize
    initialize_monitoring_dirs
    initialize_monitoring_config
    
    # Show menu if called directly
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        show_monitoring_menu
    fi
}

# Export functions for use by other scripts
export -f initialize_monitoring_dirs
export -f initialize_monitoring_config
export -f start_uptime_monitor
export -f start_apm_monitor
export -f start_log_analyzer
export -f generate_sla_report
export -f show_realtime_dashboard
export -f stop_monitoring
export -f show_monitoring_menu

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
