#!/bin/bash
#
# monitoring_manager.sh - Part of LOMP Stack v3.0
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
# monitoring_manager.sh - Sistem avansat de monitoring și alerting

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependency_manager.sh"
source "$SCRIPT_DIR/error_handler.sh"
source "$SCRIPT_DIR/state_manager.sh"

# Initialize error handling
setup_error_handlers
DEBUG_MODE=true

# Source helpers using dependency manager
source_stack_helper "functions"

# Constante pentru monitoring
readonly MONITORING_DIR="/tmp/stack_monitoring"
readonly ALERTS_LOG="/tmp/stack_alerts.log"
readonly METRICS_LOG="/tmp/stack_metrics.log"
readonly MONITORING_STATE="$MONITORING_DIR/monitoring.state"
export MONITORING_STATE

# Praguri pentru alerting
readonly CPU_ALERT_THRESHOLD=80
readonly MEMORY_ALERT_THRESHOLD=85
readonly DISK_ALERT_THRESHOLD=90
readonly LOAD_ALERT_THRESHOLD=5.0

# Inițializează directoarele pentru monitoring
init_monitoring_dirs() {
    local dirs=("$MONITORING_DIR" "$(dirname "$ALERTS_LOG")" "$(dirname "$METRICS_LOG")")
    
    for dir in "${dirs[@]}"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            log_warning "Nu pot crea directorul de monitoring: $dir"
            return 1
        fi
    done
    
    log_debug "Directoare de monitoring inițializate"
    return 0
}

# Colectează metrici de sistem
collect_system_metrics() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CPU usage
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # Memory usage
    local memory_info
    memory_info=$(free | grep Mem)
    local total_memory
    total_memory=$(echo "$memory_info" | awk '{print $2}')
    local used_memory
    used_memory=$(echo "$memory_info" | awk '{print $3}')
    local memory_usage_percent=$(( (used_memory * 100) / total_memory ))
    
    # Disk usage
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    
    # Load average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)
    
    # Network connections
    local connections
    connections=$(ss -tuln | grep -c LISTEN)
    
    # Processes count
    local processes
    processes=$(ps aux | wc -l)
    
    # Log metrici
    local metrics_entry="$timestamp|CPU:${cpu_usage}%|MEM:${memory_usage_percent}%|DISK:${disk_usage}%|LOAD:${load_avg}|CONN:${connections}|PROC:${processes}"
    echo "$metrics_entry" >> "$METRICS_LOG"
    
    # Check pentru alerting
    check_system_alerts "$cpu_usage" "$memory_usage_percent" "$disk_usage" "$load_avg"
    
    return 0
}

# Verifică și trimite alerte pentru metrici
check_system_alerts() {
    local cpu_usage="$1"
    local memory_usage="$2"
    local disk_usage="$3"
    local load_avg="$4"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CPU Alert
    if (( $(echo "$cpu_usage" | cut -d'.' -f1) > CPU_ALERT_THRESHOLD )); then
        send_alert "HIGH_CPU" "CPU usage is ${cpu_usage}% (threshold: ${CPU_ALERT_THRESHOLD}%)"
    fi
    
    # Memory Alert
    if (( memory_usage > MEMORY_ALERT_THRESHOLD )); then
        send_alert "HIGH_MEMORY" "Memory usage is ${memory_usage}% (threshold: ${MEMORY_ALERT_THRESHOLD}%)"
    fi
    
    # Disk Alert
    if (( disk_usage > DISK_ALERT_THRESHOLD )); then
        send_alert "HIGH_DISK" "Disk usage is ${disk_usage}% (threshold: ${DISK_ALERT_THRESHOLD}%)"
    fi
    
    # Load Average Alert
    if (( $(echo "$load_avg" | cut -d'.' -f1) > $(echo "$LOAD_ALERT_THRESHOLD" | cut -d'.' -f1) )); then
        send_alert "HIGH_LOAD" "Load average is ${load_avg} (threshold: ${LOAD_ALERT_THRESHOLD})"
    fi
}

# Trimite alertă
send_alert() {
    local alert_type="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local alert_entry="[$timestamp] ALERT: $alert_type - $message"
    echo "$alert_entry" >> "$ALERTS_LOG"
    
    log_warning "🚨 ALERT: $alert_type - $message"
    
    # Notificare prin email (dacă este configurat)
    send_email_notification "$alert_type" "$message"
    
    # Actualizează starea
    set_state_var "LAST_ALERT" "$alert_entry" true
    set_state_var "ALERT_COUNT" "$(($(get_state_var "ALERT_COUNT" "0") + 1))" true
}

# Trimite notificare prin email
send_email_notification() {
    local alert_type="$1"
    local message="$2"
    local email_config
    
    email_config=$(get_state_var "ALERT_EMAIL" "")
    
    if [[ -n "$email_config" ]] && command -v mail >/dev/null 2>&1; then
        echo "LOMP Stack Alert: $message" | mail -s "Stack Alert: $alert_type" "$email_config"
        log_debug "Alertă trimisă prin email la: $email_config"
    fi
}

# Monitorizează serviciile Stack
monitor_stack_services() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_info "Monitorizare servicii Stack..." "cyan"
    
    # Lista serviciilor de monitorizat
    local services=("nginx" "apache2" "mysql" "mariadb" "php*-fpm" "redis-server")
    local service_status=()
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            service_status+=("$service:RUNNING")
            log_debug "Serviciu activ: $service"
        elif systemctl list-unit-files --type=service | grep -q "$service"; then
            service_status+=("$service:STOPPED")
            log_warning "Serviciu oprit: $service"
            send_alert "SERVICE_DOWN" "Service $service is not running"
        fi
    done
    
    # Log status servicii
    local services_entry="$timestamp|SERVICES:${service_status[*]}"
    echo "$services_entry" >> "$METRICS_LOG"
    
    return 0
}

# Monitorizează starea website-urilor
monitor_websites() {
    local websites_file="$MONITORING_DIR/websites.list"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ ! -f "$websites_file" ]]; then
        log_debug "Nu există listă de website-uri pentru monitorizare"
        return 0
    fi
    
    log_info "Monitorizare website-uri..." "cyan"
    
    while IFS= read -r website; do
        [[ -z "$website" || "$website" =~ ^# ]] && continue
        
        # Test conectivitate
        local response_code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$website" 2>/dev/null)
        
        if [[ "$response_code" == "200" ]]; then
            log_debug "Website OK: $website (HTTP $response_code)"
        else
            log_warning "Website probleme: $website (HTTP $response_code)"
            send_alert "WEBSITE_DOWN" "Website $website returned HTTP $response_code"
        fi
        
        # Log status website
        echo "$timestamp|WEBSITE:$website:$response_code" >> "$METRICS_LOG"
        
    done < "$websites_file"
    
    return 0
}

# Configurează monitoring pentru un website
add_website_monitoring() {
    local website="$1"
    local websites_file="$MONITORING_DIR/websites.list"
    
    if [[ -z "$website" ]]; then
        log_error "URL website necesar pentru monitoring"
        return 1
    fi
    
    # Validează URL
    if ! curl -s --head --max-time 5 "$website" >/dev/null 2>&1; then
        log_warning "Website nu răspunde: $website"
    fi
    
    # Adaugă în lista de monitoring
    echo "$website" >> "$websites_file"
    log_info "Website adăugat în monitoring: $website" "green"
    
    set_state_var "WEBSITES_MONITORED" "$(($(get_state_var "WEBSITES_MONITORED" "0") + 1))" true
    
    return 0
}

# Generează raport de monitoring
generate_monitoring_report() {
    local report_type="${1:-summary}" # summary, detailed, alerts
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_info "=== RAPORT MONITORING ($report_type) ===" "cyan"
    
    case "$report_type" in
        "summary")
            show_monitoring_summary
            ;;
        "detailed")
            show_detailed_monitoring
            ;;
        "alerts")
            show_alerts_report
            ;;
        *)
            log_warning "Tip raport necunoscut: $report_type"
            return 1
            ;;
    esac
}

# Afișează sumar monitoring
show_monitoring_summary() {
    echo "=== SUMAR MONITORING ==="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    # Ultimele metrici
    if [[ -f "$METRICS_LOG" ]]; then
        echo "Ultimele metrici sistem:"
        tail -1 "$METRICS_LOG" | sed 's/|/\n  /g'
        echo
    fi
    
    # Numărul de alerte
    local alert_count
    alert_count=$(get_state_var "ALERT_COUNT" "0")
    echo "Total alerte: $alert_count"
    
    # Ultima alertă
    local last_alert
    last_alert=$(get_state_var "LAST_ALERT" "Nu există alerte")
    echo "Ultima alertă: $last_alert"
    
    # Website-uri monitorizate
    local websites_monitored
    websites_monitored=$(get_state_var "WEBSITES_MONITORED" "0")
    echo "Website-uri monitorizate: $websites_monitored"
}

# Afișează monitoring detaliat
show_detailed_monitoring() {
    echo "=== MONITORING DETALIAT ==="
    echo
    
    # Ultimele 10 intrări din metrici
    echo "Ultimele 10 metrici sistem:"
    if [[ -f "$METRICS_LOG" ]]; then
        tail -10 "$METRICS_LOG" | while IFS='|' read -r timestamp cpu mem disk load _ _; do
            echo "  [$timestamp] CPU:$cpu MEM:$mem DISK:$disk LOAD:$load"
        done
    else
        echo "  Nu există date de monitoring"
    fi
    
    echo
    echo "Status servicii Stack:"
    monitor_stack_services >/dev/null 2>&1
    
    echo
    echo "Website-uri monitorizate:"
    if [[ -f "$MONITORING_DIR/websites.list" ]]; then
        cat "$MONITORING_DIR/websites.list" | grep -v '^#' | while read -r website; do
            [[ -n "$website" ]] && echo "  - $website"
        done
    else
        echo "  Nu sunt website-uri configurate"
    fi
}

# Afișează raport alerte
show_alerts_report() {
    echo "=== RAPORT ALERTE ==="
    echo
    
    if [[ -f "$ALERTS_LOG" ]]; then
        echo "Ultimele 10 alerte:"
        tail -10 "$ALERTS_LOG"
    else
        echo "Nu există alerte înregistrate"
    fi
}

# Setează configurarea pentru alerting
configure_alerting() {
    local email="$1"
    local enable_email="${2:-true}"
    
    log_info "Configurare alerting..." "cyan"
    
    if [[ -n "$email" && "$enable_email" == "true" ]]; then
        set_state_var "ALERT_EMAIL" "$email" true
        log_info "Email pentru alerte configurat: $email" "green"
        
        # Test email
        if command -v mail >/dev/null 2>&1; then
            echo "Test alerting configuration" | mail -s "LOMP Stack - Test Alert" "$email"
            log_info "Email de test trimis" "green"
        else
            log_warning "Comanda 'mail' nu este disponibilă pentru trimiterea alertelor"
        fi
    fi
    
    # Configurează pragurile personalizate
    echo "Configurare praguri alerting:"
    echo "CPU: $CPU_ALERT_THRESHOLD%"
    echo "Memory: $MEMORY_ALERT_THRESHOLD%"
    echo "Disk: $DISK_ALERT_THRESHOLD%"
    echo "Load: $LOAD_ALERT_THRESHOLD"
    
    set_state_var "ALERTING_CONFIGURED" "true" true
    
    return 0
}

# Pornește monitorizarea continuă
start_continuous_monitoring() {
    local interval="${1:-300}" # 5 minute default
    
    log_info "Pornesc monitorizare continuă (interval: ${interval}s)" "cyan"
    
    # Creează script pentru monitoring continuu
    local monitor_script="$MONITORING_DIR/continuous_monitor.sh"
    
    cat > "$monitor_script" << EOF
#!/bin/bash
# Continuous monitoring script
source "$SCRIPT_DIR/monitoring_manager.sh"

while true; do
    collect_system_metrics
    monitor_stack_services
    monitor_websites
    sleep $interval
done
EOF
    
    chmod +x "$monitor_script"
    
    # Pornește monitoring în background
    nohup "$monitor_script" > "$MONITORING_DIR/monitor.log" 2>&1 &
    local monitor_pid=$!
    
    echo "$monitor_pid" > "$MONITORING_DIR/monitor.pid"
    set_state_var "MONITORING_ACTIVE" "true" true
    set_state_var "MONITORING_PID" "$monitor_pid" true
    
    log_info "Monitoring continuu pornit (PID: $monitor_pid)" "green"
    
    return 0
}

# Oprește monitorizarea continuă
stop_continuous_monitoring() {
    local monitor_pid
    monitor_pid=$(get_state_var "MONITORING_PID" "")
    
    if [[ -n "$monitor_pid" ]] && kill -0 "$monitor_pid" 2>/dev/null; then
        kill "$monitor_pid"
        log_info "Monitoring continuu oprit (PID: $monitor_pid)" "yellow"
    else
        log_warning "Nu există proces de monitoring activ"
    fi
    
    set_state_var "MONITORING_ACTIVE" "false" true
    rm -f "$MONITORING_DIR/monitor.pid"
    
    return 0
}

# Inițializare automată
init_monitoring_dirs

# Export funcții pentru utilizare externă
export -f collect_system_metrics monitor_stack_services monitor_websites
export -f add_website_monitoring generate_monitoring_report configure_alerting
export -f start_continuous_monitoring stop_continuous_monitoring

log_debug "Monitoring Manager încărcat cu succes"
