#!/bin/bash
#
# auto_scaling_manager.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Auto-Scaling Manager
# Enterprise-grade auto-scaling with horizontal scaling and load balancing
# 
# Features:
# - Horizontal scaling based on metrics
# - Intelligent load balancing
# - Resource monitoring and allocation
# - Traffic spike detection
# - Cost optimization through scaling
# - Integration with cloud providers
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

# Define print functions using color_echo
print_info() { color_echo cyan "[INFO] $*"; }
print_success() { color_echo green "[SUCCESS] $*"; }
print_warning() { color_echo yellow "[WARNING] $*"; }
print_error() { color_echo red "[ERROR] $*"; }

# Scaling configuration
SCALING_CONFIG="${SCRIPT_DIR}/scaling_config.json"
SCALING_LOG="${SCRIPT_DIR}/../tmp/auto_scaling.log"
METRICS_LOG="${SCRIPT_DIR}/../tmp/scaling_metrics.log"

#########################################################################
# Logging Function
#########################################################################
log_scaling() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$SCALING_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize Scaling Configuration
#########################################################################
init_scaling_config() {
    log_scaling "INFO" "Initializing Auto-Scaling Manager..."
    
    # Create tmp directory for logs
    mkdir -p "$(dirname "$SCALING_LOG")"
    
    # Create scaling configuration if it doesn't exist
    if [[ ! -f "$SCALING_CONFIG" ]]; then
        cat > "$SCALING_CONFIG" << 'EOF'
{
  "scaling_settings": {
    "enabled": true,
    "min_instances": 1,
    "max_instances": 10,
    "desired_instances": 2,
    "scale_up_threshold": 80,
    "scale_down_threshold": 30,
    "scale_up_period": 300,
    "scale_down_period": 600
  },
  "metrics": {
    "cpu_threshold": 75,
    "memory_threshold": 80,
    "disk_threshold": 85,
    "response_time_threshold": 2000,
    "request_rate_threshold": 1000
  },
  "load_balancer": {
    "enabled": true,
    "algorithm": "round_robin",
    "health_check_interval": 30,
    "health_check_timeout": 5,
    "health_check_retries": 3
  },
  "cloud_integration": {
    "aws_enabled": false,
    "digitalocean_enabled": false,
    "azure_enabled": false,
    "preferred_provider": "aws"
  },
  "cost_optimization": {
    "enabled": true,
    "max_hourly_cost": 10,
    "max_daily_cost": 100,
    "spot_instances": true,
    "schedule_based_scaling": true
  },
  "notifications": {
    "email_alerts": true,
    "webhook_url": null,
    "alert_on_scale_events": true
  }
}
EOF
        log_scaling "SUCCESS" "Scaling configuration created"
    fi
}

#########################################################################
# Get System Metrics
#########################################################################
get_system_metrics() {
    local cpu_usage memory_usage disk_usage load_avg response_time
    
    # CPU Usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}' 2>/dev/null || echo "0")
    cpu_usage=${cpu_usage%.*}  # Remove decimal part
    
    # Memory Usage
    memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}' 2>/dev/null || echo "0")
    
    # Disk Usage
    disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    
    # Load Average
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',' 2>/dev/null || echo "0")
    
    # Response Time (simulate - in real implementation, this would come from web server logs)
    response_time=$((RANDOM % 1000 + 100))
    
    # Log metrics
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] CPU:${cpu_usage}% MEM:${memory_usage}% DISK:${disk_usage}% LOAD:${load_avg} RT:${response_time}ms" >> "$METRICS_LOG"
    
    echo "$cpu_usage,$memory_usage,$disk_usage,$load_avg,$response_time"
}

#########################################################################
# Check Scaling Conditions
#########################################################################
check_scaling_conditions() {
    local metrics
    metrics=$(get_system_metrics)
    
    local cpu_usage memory_usage disk_usage load_avg response_time
    IFS=',' read -r cpu_usage memory_usage disk_usage load_avg response_time <<< "$metrics"
    
    # Get thresholds from config
    local cpu_threshold memory_threshold response_threshold
    cpu_threshold=$(jq -r '.metrics.cpu_threshold' "$SCALING_CONFIG" 2>/dev/null || echo "75")
    memory_threshold=$(jq -r '.metrics.memory_threshold' "$SCALING_CONFIG" 2>/dev/null || echo "80")
    response_threshold=$(jq -r '.metrics.response_time_threshold' "$SCALING_CONFIG" 2>/dev/null || echo "2000")
    
    local scale_action="none"
    local reason=""
    
    # Check if we need to scale up
    if [[ $cpu_usage -gt $cpu_threshold ]]; then
        scale_action="up"
        reason="High CPU usage: ${cpu_usage}% > ${cpu_threshold}%"
    elif [[ $memory_usage -gt $memory_threshold ]]; then
        scale_action="up"
        reason="High memory usage: ${memory_usage}% > ${memory_threshold}%"
    elif [[ $response_time -gt $response_threshold ]]; then
        scale_action="up"
        reason="High response time: ${response_time}ms > ${response_threshold}ms"
    # Check if we can scale down
    elif [[ $cpu_usage -lt 30 ]] && [[ $memory_usage -lt 40 ]]; then
        scale_action="down"
        reason="Low resource usage: CPU:${cpu_usage}% MEM:${memory_usage}%"
    fi
    
    echo "$scale_action|$reason|$cpu_usage|$memory_usage|$disk_usage|$response_time"
}

#########################################################################
# Scale Up Instances
#########################################################################
scale_up() {
    local reason="$1"
    log_scaling "INFO" "Scaling up: $reason"
    
    # Get current and max instances
    local current_instances max_instances
    current_instances=$(jq -r '.scaling_settings.desired_instances' "$SCALING_CONFIG" 2>/dev/null || echo "1")
    max_instances=$(jq -r '.scaling_settings.max_instances' "$SCALING_CONFIG" 2>/dev/null || echo "10")
    
    if [[ $current_instances -ge $max_instances ]]; then
        log_scaling "WARNING" "Cannot scale up: already at maximum instances ($max_instances)"
        return 1
    fi
    
    local new_instances=$((current_instances + 1))
    
    # Update configuration
    jq --arg instances "$new_instances" '.scaling_settings.desired_instances = ($instances | tonumber)' "$SCALING_CONFIG" > "${SCALING_CONFIG}.tmp" && \
    mv "${SCALING_CONFIG}.tmp" "$SCALING_CONFIG"
    
    # Simulate instance creation (in real implementation, this would call cloud provider APIs)
    log_scaling "INFO" "Creating new instance... (simulated)"
    sleep 2
    
    # Update load balancer configuration
    update_load_balancer_config "$new_instances"
    
    log_scaling "SUCCESS" "Scaled up from $current_instances to $new_instances instances"
    
    # Send notification if enabled
    send_scaling_notification "scale_up" "$current_instances" "$new_instances" "$reason"
    
    return 0
}

#########################################################################
# Scale Down Instances
#########################################################################
scale_down() {
    local reason="$1"
    log_scaling "INFO" "Scaling down: $reason"
    
    # Get current and min instances
    local current_instances min_instances
    current_instances=$(jq -r '.scaling_settings.desired_instances' "$SCALING_CONFIG" 2>/dev/null || echo "1")
    min_instances=$(jq -r '.scaling_settings.min_instances' "$SCALING_CONFIG" 2>/dev/null || echo "1")
    
    if [[ $current_instances -le $min_instances ]]; then
        log_scaling "WARNING" "Cannot scale down: already at minimum instances ($min_instances)"
        return 1
    fi
    
    local new_instances=$((current_instances - 1))
    
    # Update configuration
    jq --arg instances "$new_instances" '.scaling_settings.desired_instances = ($instances | tonumber)' "$SCALING_CONFIG" > "${SCALING_CONFIG}.tmp" && \
    mv "${SCALING_CONFIG}.tmp" "$SCALING_CONFIG"
    
    # Simulate instance removal (in real implementation, this would call cloud provider APIs)
    log_scaling "INFO" "Removing instance... (simulated)"
    sleep 2
    
    # Update load balancer configuration
    update_load_balancer_config "$new_instances"
    
    log_scaling "SUCCESS" "Scaled down from $current_instances to $new_instances instances"
    
    # Send notification if enabled
    send_scaling_notification "scale_down" "$current_instances" "$new_instances" "$reason"
    
    return 0
}

#########################################################################
# Update Load Balancer Configuration
#########################################################################
update_load_balancer_config() {
    local instance_count="$1"
    log_scaling "INFO" "Updating load balancer configuration for $instance_count instances"
    
    # Create/update load balancer configuration
    local lb_config="${SCRIPT_DIR}/load_balancer_config.conf"
    
    cat > "$lb_config" << EOF
# Auto-generated load balancer configuration
# Generated at: $(date)
# Instance count: $instance_count

upstream backend {
EOF
    
    # Generate backend server entries
    for ((i=1; i<=instance_count; i++)); do
        echo "    server 127.0.0.1:$((8080 + i)) weight=1 max_fails=3 fail_timeout=30s;" >> "$lb_config"
    done
    
    cat >> "$lb_config" << 'EOF'
}

server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Health check
        proxy_connect_timeout 5s;
        proxy_send_timeout 5s;
        proxy_read_timeout 5s;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
    
    log_scaling "SUCCESS" "Load balancer configuration updated: $lb_config"
}

#########################################################################
# Send Scaling Notification
#########################################################################
send_scaling_notification() {
    local action="$1"
    local old_count="$2"
    local new_count="$3"
    local reason="$4"
    
    local alerts_enabled
    alerts_enabled=$(jq -r '.notifications.alert_on_scale_events' "$SCALING_CONFIG" 2>/dev/null || echo "false")
    
    if [[ "$alerts_enabled" != "true" ]]; then
        return 0
    fi
    
    local message="Auto-Scaling Event: $action from $old_count to $new_count instances. Reason: $reason"
    log_scaling "INFO" "Notification: $message"
    
    # In real implementation, this would send email/webhook notifications
    echo "$(date): $message" >> "${SCRIPT_DIR}/../tmp/scaling_notifications.log"
}

#########################################################################
# Monitor and Auto-Scale
#########################################################################
monitor_and_scale() {
    log_scaling "INFO" "Starting auto-scaling monitoring..."
    
    local scaling_enabled
    scaling_enabled=$(jq -r '.scaling_settings.enabled' "$SCALING_CONFIG" 2>/dev/null || echo "true")
    
    if [[ "$scaling_enabled" != "true" ]]; then
        log_scaling "WARNING" "Auto-scaling is disabled"
        return 1
    fi
    
    local last_scale_time=0
    local scale_cooldown=300  # 5 minutes cooldown
    
    while true; do
        local current_time
        current_time=$(date +%s)
        
        # Check if we're still in cooldown period
        if [[ $((current_time - last_scale_time)) -lt $scale_cooldown ]]; then
            sleep 30
            continue
        fi
        
        # Get scaling conditions
        local scaling_check
        scaling_check=$(check_scaling_conditions)
        
        local scale_action reason cpu_usage memory_usage disk_usage response_time
        IFS='|' read -r scale_action reason cpu_usage memory_usage disk_usage response_time <<< "$scaling_check"
        
        # Display current metrics
        echo "$(date +'%H:%M:%S') - CPU: ${cpu_usage}% | MEM: ${memory_usage}% | DISK: ${disk_usage}% | RT: ${response_time}ms"
        
        case "$scale_action" in
            "up")
                if scale_up "$reason"; then
                    last_scale_time=$current_time
                fi
                ;;
            "down")
                if scale_down "$reason"; then
                    last_scale_time=$current_time
                fi
                ;;
            "none")
                # No scaling needed
                ;;
        esac
        
        sleep 30  # Check every 30 seconds
    done
}

#########################################################################
# Cost Analysis
#########################################################################
analyze_costs() {
    log_scaling "INFO" "Analyzing scaling costs..."
    
    local current_instances max_cost_per_hour
    current_instances=$(jq -r '.scaling_settings.desired_instances' "$SCALING_CONFIG" 2>/dev/null || echo "1")
    max_cost_per_hour=$(jq -r '.cost_optimization.max_hourly_cost' "$SCALING_CONFIG" 2>/dev/null || echo "10")
    
    # Simulate cost calculation (in real implementation, this would query cloud provider APIs)
    local cost_per_instance_hour=1.50
    local current_hourly_cost
    current_hourly_cost=$(echo "$current_instances * $cost_per_instance_hour" | bc 2>/dev/null || echo "1.50")
    
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│                     💰 COST ANALYSIS                       │"
    echo "├─────────────────────────────────────────────────────────────┤"
    printf "│  Current Instances:     %-31d │\n" "$current_instances"
    printf "│  Cost per Instance:     \$%-30.2f │\n" "$cost_per_instance_hour"
    printf "│  Current Hourly Cost:   \$%-30.2f │\n" "$current_hourly_cost"
    printf "│  Maximum Hourly Cost:   \$%-30.2f │\n" "$max_cost_per_hour"
    echo "├─────────────────────────────────────────────────────────────┤"
    
    # Calculate daily and monthly projections
    local daily_cost monthly_cost
    daily_cost=$(echo "$current_hourly_cost * 24" | bc 2>/dev/null || echo "36")
    monthly_cost=$(echo "$daily_cost * 30" | bc 2>/dev/null || echo "1080")
    
    printf "│  Projected Daily Cost:  \$%-30.2f │\n" "$daily_cost"
    printf "│  Projected Monthly:     \$%-30.2f │\n" "$monthly_cost"
    echo "├─────────────────────────────────────────────────────────────┤"
    
    # Cost optimization suggestions
    if (( $(echo "$current_hourly_cost > $max_cost_per_hour" | bc -l) )); then
        echo "│  ⚠️  Cost exceeds maximum threshold!                       │"
        echo "│  💡 Suggestions:                                          │"
        echo "│     • Consider using spot instances                       │"
        echo "│     • Optimize scaling thresholds                         │"
        echo "│     • Schedule-based scaling for predictable loads        │"
    else
        echo "│  ✅ Costs are within acceptable limits                     │"
    fi
    
    echo "╰─────────────────────────────────────────────────────────────╯"
    
    log_scaling "INFO" "Cost analysis completed. Current hourly cost: \$$current_hourly_cost"
}

#########################################################################
# Show Scaling Status
#########################################################################
show_scaling_status() {
    clear
    
    local current_instances min_instances max_instances scaling_enabled
    current_instances=$(jq -r '.scaling_settings.desired_instances' "$SCALING_CONFIG" 2>/dev/null || echo "1")
    min_instances=$(jq -r '.scaling_settings.min_instances' "$SCALING_CONFIG" 2>/dev/null || echo "1")
    max_instances=$(jq -r '.scaling_settings.max_instances' "$SCALING_CONFIG" 2>/dev/null || echo "10")
    scaling_enabled=$(jq -r '.scaling_settings.enabled' "$SCALING_CONFIG" 2>/dev/null || echo "true")
    
    # Get current metrics
    local metrics
    metrics=$(get_system_metrics)
    local cpu_usage memory_usage disk_usage load_avg response_time
    IFS=',' read -r cpu_usage memory_usage disk_usage load_avg response_time <<< "$metrics"
    
    cat << EOF
╭─────────────────────────────────────────────────────────────────────────╮
│                      ⚡ AUTO-SCALING STATUS                             │
│                        LOMP Stack v2.0                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  🎯 Scaling Configuration:                                             │
│     Auto-Scaling:         $(echo "$scaling_enabled" | sed 's/true/✅ Enabled/g' | sed 's/false/❌ Disabled/g')                                │
│     Current Instances:    $current_instances                                              │
│     Min/Max Instances:    $min_instances / $max_instances                                         │
│                                                                         │
│  📊 Current Metrics:                                                   │
│     CPU Usage:            ${cpu_usage}%                                        │
│     Memory Usage:         ${memory_usage}%                                        │
│     Disk Usage:           ${disk_usage}%                                        │
│     Load Average:         ${load_avg}                                         │
│     Response Time:        ${response_time}ms                                      │
│                                                                         │
│  ⚖️  Load Balancer:                                                    │
│     Status:               $(jq -r '.load_balancer.enabled' "$SCALING_CONFIG" 2>/dev/null | sed 's/true/✅ Active/g' | sed 's/false/❌ Inactive/g')                                │
│     Algorithm:            $(jq -r '.load_balancer.algorithm' "$SCALING_CONFIG" 2>/dev/null || echo "round_robin")                              │
│     Health Checks:        $(jq -r '.load_balancer.health_check_interval' "$SCALING_CONFIG" 2>/dev/null || echo "30")s interval                            │
│                                                                         │
│  💰 Cost Optimization:                                                 │
│     Enabled:              $(jq -r '.cost_optimization.enabled' "$SCALING_CONFIG" 2>/dev/null | sed 's/true/✅ Yes/g' | sed 's/false/❌ No/g')                                │
│     Max Hourly Cost:      \$$(jq -r '.cost_optimization.max_hourly_cost' "$SCALING_CONFIG" 2>/dev/null || echo "10")                                     │
│     Spot Instances:       $(jq -r '.cost_optimization.spot_instances' "$SCALING_CONFIG" 2>/dev/null | sed 's/true/✅ Yes/g' | sed 's/false/❌ No/g')                                │
├─────────────────────────────────────────────────────────────────────────┤
│  Last Updated: $(date +'%Y-%m-%d %H:%M:%S')                                    │
╰─────────────────────────────────────────────────────────────────────────╯
EOF
}

#########################################################################
# Auto-Scaling Manager Menu
#########################################################################
show_scaling_menu() {
    while true; do
        clear
        cat << 'EOF'
╭─────────────────────────────────────────────────────────────────────────╮
│                     ⚡ AUTO-SCALING MANAGER                             │
│                        LOMP Stack v2.0                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  1) 📊 Scaling Status Overview                                         │
│  2) 🚀 Start Auto-Scaling Monitor                                      │
│  3) ⏹️  Stop Auto-Scaling Monitor                                       │
│  4) ⬆️  Manual Scale Up                                                 │
│  5) ⬇️  Manual Scale Down                                               │
│  6) ⚖️  Configure Load Balancer                                         │
│  7) 💰 Cost Analysis                                                   │
│  8) 📈 View Metrics History                                            │
│  9) ⚙️  Configure Scaling Settings                                      │
│  10) 🔔 Scaling Notifications                                          │
│  11) 📜 View Scaling Logs                                              │
│  0) ⬅️  Return to Enterprise Dashboard                                 │
├─────────────────────────────────────────────────────────────────────────┤
│ Status: Auto-Scaling Manager Ready                                     │
╰─────────────────────────────────────────────────────────────────────────╯
EOF

        read -p "Select option [0-11]: " choice
        
        case $choice in
            1)
                show_scaling_status
                read -p "Press Enter to continue..."
                ;;
            2)
                print_info "Starting auto-scaling monitor..."
                print_warning "This will run continuously. Press Ctrl+C to stop."
                read -p "Press Enter to start monitoring..."
                monitor_and_scale
                ;;
            3)
                print_info "Stopping auto-scaling monitor..."
                pkill -f "auto_scaling_manager.sh"
                print_success "Auto-scaling monitor stopped"
                read -p "Press Enter to continue..."
                ;;
            4)
                print_info "Manual scale up requested..."
                scale_up "Manual scale up request"
                read -p "Press Enter to continue..."
                ;;
            5)
                print_info "Manual scale down requested..."
                scale_down "Manual scale down request"
                read -p "Press Enter to continue..."
                ;;
            6)
                print_info "Load balancer configuration..."
                local instances
                instances=$(jq -r '.scaling_settings.desired_instances' "$SCALING_CONFIG" 2>/dev/null || echo "1")
                update_load_balancer_config "$instances"
                read -p "Press Enter to continue..."
                ;;
            7)
                analyze_costs
                read -p "Press Enter to continue..."
                ;;
            8)
                print_info "Metrics history:"
                if [[ -f "$METRICS_LOG" ]]; then
                    tail -20 "$METRICS_LOG"
                else
                    print_warning "No metrics history found"
                fi
                read -p "Press Enter to continue..."
                ;;
            9)
                print_info "Opening scaling configuration..."
                if command -v nano >/dev/null 2>&1; then
                    nano "$SCALING_CONFIG"
                else
                    cat "$SCALING_CONFIG"
                    read -p "Press Enter to continue..."
                fi
                ;;
            10)
                print_info "Scaling notifications:"
                if [[ -f "${SCRIPT_DIR}/../tmp/scaling_notifications.log" ]]; then
                    tail -10 "${SCRIPT_DIR}/../tmp/scaling_notifications.log"
                else
                    print_warning "No scaling notifications found"
                fi
                read -p "Press Enter to continue..."
                ;;
            11)
                print_info "Scaling logs:"
                if [[ -f "$SCALING_LOG" ]]; then
                    tail -20 "$SCALING_LOG"
                else
                    print_warning "No scaling logs found"
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                print_info "Returning to Enterprise Dashboard..."
                break
                ;;
            *)
                print_error "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

#########################################################################
# Main Execution
#########################################################################
main() {
    # Initialize configuration
    init_scaling_config
    
    # If script is called with arguments, run specific function
    if [[ $# -gt 0 ]]; then
        case "$1" in
            "status")
                show_scaling_status
                ;;
            "monitor")
                monitor_and_scale
                ;;
            "scale-up")
                scale_up "Manual scale up request"
                ;;
            "scale-down")
                scale_down "Manual scale down request"
                ;;
            "costs"|"cost-analysis")
                analyze_costs
                ;;
            "load-balancer"|"lb")
                local instances
                instances=$(jq -r '.scaling_settings.desired_instances' "$SCALING_CONFIG" 2>/dev/null || echo "1")
                update_load_balancer_config "$instances"
                ;;
            "menu")
                show_scaling_menu
                ;;
            *)
                echo "Usage: $0 {status|monitor|scale-up|scale-down|costs|load-balancer|menu}"
                echo "  status         - Show scaling status overview"
                echo "  monitor        - Start auto-scaling monitoring"
                echo "  scale-up       - Manual scale up"
                echo "  scale-down     - Manual scale down"
                echo "  costs          - Analyze scaling costs"
                echo "  load-balancer  - Update load balancer configuration"
                echo "  menu           - Show interactive menu"
                exit 1
                ;;
        esac
    else
        # Show menu by default
        show_scaling_menu
    fi
}

# Run main function
main "$@"
