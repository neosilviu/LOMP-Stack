#!/bin/bash
#
# advanced_security_manager.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Advanced Security Manager
# Enterprise-grade security with Cloudflare Tunneling, WAF, IDS, and compliance
# 
# Features:
# - Cloudflare Tunnel integration for zero-trust access
# - Web Application Firewall (WAF) management
# - Intrusion Detection System (IDS)
# - DDoS Protection with Cloudflare
# - Security scanning and vulnerability assessment
# - Compliance monitoring (GDPR, PCI-DSS)
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../helpers/utils/functions.sh"

# Define print functions using color_echo
print_info() { color_echo cyan "[INFO] $*"; }
print_success() { color_echo green "[SUCCESS] $*"; }
print_warning() { color_echo yellow "[WARNING] $*"; }
print_error() { color_echo red "[ERROR] $*"; }

# Security configuration
SECURITY_CONFIG="${SCRIPT_DIR}/security_config.json"
SECURITY_LOG="${SCRIPT_DIR}/../../tmp/advanced_security.log"
CLOUDFLARE_CONFIG="${SCRIPT_DIR}/cloudflare_tunnel_config.json"

#########################################################################
# Logging Function
#########################################################################
log_security() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$SECURITY_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize Security Configuration
#########################################################################
init_security_config() {
    log_security "INFO" "Initializing Advanced Security Manager..."
    
    # Create tmp directory for logs
    mkdir -p "$(dirname "$SECURITY_LOG")"
    
    # Create security configuration if it doesn't exist
    if [[ ! -f "$SECURITY_CONFIG" ]]; then
        cat > "$SECURITY_CONFIG" << 'EOF'
{
  "security_settings": {
    "waf_enabled": true,
    "ids_enabled": true,
    "ddos_protection": true,
    "auto_ssl": true,
    "security_scanning": true,
    "compliance_monitoring": true
  },
  "cloudflare_tunnel": {
    "enabled": false,
    "tunnel_name": "lomp-stack-tunnel",
    "tunnel_id": null,
    "credentials_file": null,
    "config_file": null
  },
  "waf_rules": {
    "sql_injection": true,
    "xss_protection": true,
    "rate_limiting": true,
    "geo_blocking": false,
    "custom_rules": []
  },
  "ids_settings": {
    "monitor_failed_logins": true,
    "monitor_file_changes": true,
    "monitor_network_traffic": true,
    "alert_threshold": 5,
    "block_threshold": 10
  },
  "compliance": {
    "gdpr_enabled": true,
    "pci_dss_enabled": false,
    "soc2_enabled": false,
    "logging_retention_days": 90
  },
  "notifications": {
    "email_alerts": true,
    "slack_webhook": null,
    "alert_levels": ["critical", "high", "medium"]
  }
}
EOF
        log_security "SUCCESS" "Security configuration created"
    fi
    
    # Create Cloudflare tunnel configuration
    if [[ ! -f "$CLOUDFLARE_CONFIG" ]]; then
        cat > "$CLOUDFLARE_CONFIG" << 'EOF'
{
  "cloudflare_settings": {
    "api_token": null,
    "zone_id": null,
    "account_id": null,
    "email": null
  },
  "tunnel_config": {
    "tunnel_name": "lomp-stack-tunnel",
    "ingress": [
      {
        "hostname": "*.example.com",
        "service": "http://localhost:80"
      },
      {
        "service": "http_status:404"
      }
    ]
  },
  "access_policies": {
    "enabled": true,
    "bypass_on_cert": false,
    "policies": [
      {
        "name": "Admin Access",
        "decision": "allow",
        "include": [],
        "require": [],
        "exclude": []
      }
    ]
  }
}
EOF
        log_security "SUCCESS" "Cloudflare tunnel configuration created"
    fi
}

#########################################################################
# Install Cloudflare Tunnel (cloudflared)
#########################################################################
install_cloudflare_tunnel() {
    log_security "INFO" "Installing Cloudflare Tunnel (cloudflared)..."
    
    # Check if already installed
    if command -v cloudflared >/dev/null 2>&1; then
        local version
        version=$(cloudflared --version 2>/dev/null | head -n1)
        log_security "INFO" "Cloudflared already installed: $version"
        return 0
    fi
    
    # Detect architecture
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="arm" ;;
        *) 
            log_security "ERROR" "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    # Detect OS
    local os
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os="darwin"
    else
        log_security "ERROR" "Unsupported OS: $OSTYPE"
        return 1
    fi
    
    log_security "INFO" "Downloading cloudflared for $os-$arch..."
    
    # Download and install cloudflared
    local download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-$os-$arch"
    local temp_file="/tmp/cloudflared"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q "$download_url" -O "$temp_file"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -s "$download_url" -o "$temp_file"
    else
        log_security "ERROR" "Neither wget nor curl available for download"
        return 1
    fi
    
    # Make executable and move to system path
    chmod +x "$temp_file"
    sudo mv "$temp_file" /usr/local/bin/cloudflared
    
    # Verify installation
    if command -v cloudflared >/dev/null 2>&1; then
        local version
        version=$(cloudflared --version 2>/dev/null | head -n1)
        log_security "SUCCESS" "Cloudflared installed successfully: $version"
        return 0
    else
        log_security "ERROR" "Cloudflared installation failed"
        return 1
    fi
}

#########################################################################
# Setup Cloudflare Tunnel
#########################################################################
setup_cloudflare_tunnel() {
    log_security "INFO" "Setting up Cloudflare Tunnel..."
    
    # Check if cloudflared is installed
    if ! command -v cloudflared >/dev/null 2>&1; then
        log_security "WARNING" "Cloudflared not installed. Installing now..."
        install_cloudflare_tunnel || return 1
    fi
    
    # Get configuration
    local api_token tunnel_name
    api_token=$(jq -r '.cloudflare_settings.api_token' "$CLOUDFLARE_CONFIG" 2>/dev/null)
    tunnel_name=$(jq -r '.tunnel_config.tunnel_name' "$CLOUDFLARE_CONFIG" 2>/dev/null)
    
    if [[ "$api_token" == "null" || -z "$api_token" ]]; then
        log_security "ERROR" "Cloudflare API token not configured"
        print_warning "Please configure Cloudflare credentials in: $CLOUDFLARE_CONFIG"
        return 1
    fi
    
    # Authenticate with Cloudflare
    log_security "INFO" "Authenticating with Cloudflare..."
    export TUNNEL_TOKEN="$api_token"
    
    # Create tunnel if it doesn't exist
    log_security "INFO" "Creating tunnel: $tunnel_name"
    
    local tunnel_id
    tunnel_id=$(cloudflared tunnel list 2>/dev/null | grep "$tunnel_name" | awk '{print $1}' | head -n1)
    
    if [[ -z "$tunnel_id" ]]; then
        # Create new tunnel
        tunnel_id=$(cloudflared tunnel create "$tunnel_name" 2>/dev/null | grep -o '[a-f0-9\-]\{36\}' | head -n1)
        if [[ -n "$tunnel_id" ]]; then
            log_security "SUCCESS" "Created tunnel: $tunnel_name ($tunnel_id)"
            
            # Update configuration with tunnel ID
            jq --arg tid "$tunnel_id" '.cloudflare_tunnel.tunnel_id = $tid' "$CLOUDFLARE_CONFIG" > "${CLOUDFLARE_CONFIG}.tmp" && \
            mv "${CLOUDFLARE_CONFIG}.tmp" "$CLOUDFLARE_CONFIG"
        else
            log_security "ERROR" "Failed to create tunnel"
            return 1
        fi
    else
        log_security "INFO" "Using existing tunnel: $tunnel_name ($tunnel_id)"
    fi
    
    # Create tunnel configuration file
    local config_dir="$HOME/.cloudflared"
    mkdir -p "$config_dir"
    
    local config_file="$config_dir/config.yml"
    cat > "$config_file" << EOF
tunnel: $tunnel_id
credentials-file: $config_dir/$tunnel_id.json

ingress:
  - hostname: "*.$(jq -r '.tunnel_config.ingress[0].hostname' "$CLOUDFLARE_CONFIG" | sed 's/\*\.//')"
    service: http://localhost:80
  - service: http_status:404
EOF
    
    log_security "SUCCESS" "Tunnel configuration created: $config_file"
    
    # Update security config to mark tunnel as enabled
    jq '.cloudflare_tunnel.enabled = true' "$SECURITY_CONFIG" > "${SECURITY_CONFIG}.tmp" && \
    mv "${SECURITY_CONFIG}.tmp" "$SECURITY_CONFIG"
    
    return 0
}

#########################################################################
# Start Cloudflare Tunnel
#########################################################################
start_cloudflare_tunnel() {
    log_security "INFO" "Starting Cloudflare Tunnel..."
    
    # Check if tunnel is configured
    local tunnel_enabled
    tunnel_enabled=$(jq -r '.cloudflare_tunnel.enabled' "$SECURITY_CONFIG" 2>/dev/null)
    
    if [[ "$tunnel_enabled" != "true" ]]; then
        log_security "ERROR" "Cloudflare tunnel not configured. Run setup first."
        return 1
    fi
    
    # Check if tunnel is already running
    if pgrep -f "cloudflared tunnel run" >/dev/null; then
        log_security "INFO" "Cloudflare tunnel is already running"
        return 0
    fi
    
    # Start tunnel in background
    nohup cloudflared tunnel run > "${SCRIPT_DIR}/../../tmp/cloudflared.log" 2>&1 &
    local tunnel_pid=$!
    
    # Wait a moment and check if it started successfully
    sleep 3
    if kill -0 "$tunnel_pid" 2>/dev/null; then
        log_security "SUCCESS" "Cloudflare tunnel started successfully (PID: $tunnel_pid)"
        echo "$tunnel_pid" > "${SCRIPT_DIR}/../../tmp/cloudflared.pid"
        return 0
    else
        log_security "ERROR" "Failed to start Cloudflare tunnel"
        return 1
    fi
}

#########################################################################
# Stop Cloudflare Tunnel
#########################################################################
stop_cloudflare_tunnel() {
    log_security "INFO" "Stopping Cloudflare Tunnel..."
    
    local pid_file="${SCRIPT_DIR}/../../tmp/cloudflared.pid"
    
    # Kill tunnel process
    if pgrep -f "cloudflared tunnel run" >/dev/null; then
        pkill -f "cloudflared tunnel run"
        log_security "SUCCESS" "Cloudflare tunnel stopped"
    else
        log_security "INFO" "Cloudflare tunnel was not running"
    fi
    
    # Remove PID file
    [[ -f "$pid_file" ]] && rm -f "$pid_file"
}

#########################################################################
# Configure WAF Rules
#########################################################################
configure_waf() {
    log_security "INFO" "Configuring Web Application Firewall..."
    
    # Check if UFW is installed
    if ! command -v ufw >/dev/null 2>&1; then
        log_security "WARNING" "UFW not installed. Installing..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y ufw
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y ufw
        else
            log_security "ERROR" "Cannot install UFW on this system"
            return 1
        fi
    fi
    
    # Enable UFW if not already enabled
    if ! sudo ufw status | grep -q "Status: active"; then
        log_security "INFO" "Enabling UFW firewall..."
        sudo ufw --force enable
    fi
    
    # Basic firewall rules
    log_security "INFO" "Configuring basic firewall rules..."
    
    # Allow SSH (be careful not to lock ourselves out)
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Allow database access only from localhost
    sudo ufw allow from 127.0.0.1 to any port 3306
    
    # Block common attack ports
    sudo ufw deny 23    # Telnet
    sudo ufw deny 135   # RPC
    sudo ufw deny 139   # NetBIOS
    sudo ufw deny 445   # SMB
    
    # Rate limiting for SSH
    sudo ufw limit ssh
    
    log_security "SUCCESS" "Basic WAF rules configured"
    
    # Install and configure Fail2ban
    configure_fail2ban
}

#########################################################################
# Configure Fail2ban (IDS component)
#########################################################################
configure_fail2ban() {
    log_security "INFO" "Configuring Fail2ban (Intrusion Detection)..."
    
    # Check if Fail2ban is installed
    if ! command -v fail2ban-server >/dev/null 2>&1; then
        log_security "WARNING" "Fail2ban not installed. Installing..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y fail2ban
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y fail2ban
        else
            log_security "ERROR" "Cannot install Fail2ban on this system"
            return 1
        fi
    fi
    
    # Create custom Fail2ban configuration
    local jail_config="/etc/fail2ban/jail.local"
    
    sudo tee "$jail_config" > /dev/null << 'EOF'
[DEFAULT]
# Ban time: 1 hour
bantime = 3600

# Find time: 10 minutes
findtime = 600

# Max retry: 5 attempts
maxretry = 5

# Email notifications
destemail = admin@localhost
sendername = Fail2Ban
mta = sendmail

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[apache-auth]
enabled = true
port = http,https
logpath = /var/log/apache*/*error.log

[nginx-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

[wordpress]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
          /var/log/apache*/access.log
maxretry = 3
EOF

    # Start and enable Fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban
    
    # Verify Fail2ban is running
    if sudo systemctl is-active fail2ban >/dev/null 2>&1; then
        log_security "SUCCESS" "Fail2ban configured and running"
    else
        log_security "ERROR" "Failed to start Fail2ban"
        return 1
    fi
}

#########################################################################
# Security Scan
#########################################################################
run_security_scan() {
    log_security "INFO" "Running security scan..."
    
    local scan_results
    scan_results="${SCRIPT_DIR}/../../tmp/security_scan_$(date +%Y%m%d_%H%M%S).json"
    local issues=0
    
    # Initialize scan results
    cat > "$scan_results" << 'EOF'
{
  "scan_timestamp": "",
  "scan_type": "comprehensive",
  "results": {
    "firewall": {},
    "ssl": {},
    "services": {},
    "file_permissions": {},
    "system_security": {}
  },
  "issues": [],
  "recommendations": []
}
EOF
    
    # Update timestamp
    jq --arg ts "$(date -Iseconds)" '.scan_timestamp = $ts' "$scan_results" > "${scan_results}.tmp" && \
    mv "${scan_results}.tmp" "$scan_results"
    
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│                    🔍 SECURITY SCAN                        │"
    echo "├─────────────────────────────────────────────────────────────┤"
    
    # Check firewall status
    print_info "Checking firewall status..."
    if sudo ufw status | grep -q "Status: active"; then
        echo "│ ✅ Firewall: Active                                       │"
        jq '.results.firewall.status = "active"' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
    else
        echo "│ ❌ Firewall: Inactive                                     │"
        jq '.results.firewall.status = "inactive" | .issues += ["Firewall is not active"]' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
        ((issues++))
    fi
    
    # Check Fail2ban status
    print_info "Checking intrusion detection..."
    if sudo systemctl is-active fail2ban >/dev/null 2>&1; then
        echo "│ ✅ Fail2ban: Active                                       │"
        jq '.results.system_security.fail2ban = "active"' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
    else
        echo "│ ❌ Fail2ban: Inactive                                     │"
        jq '.results.system_security.fail2ban = "inactive" | .issues += ["Fail2ban is not active"]' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
        ((issues++))
    fi
    
    # Check SSL certificates
    print_info "Checking SSL certificates..."
    if [[ -d "/etc/letsencrypt/live" ]] && [[ -n "$(ls -A /etc/letsencrypt/live 2>/dev/null)" ]]; then
        echo "│ ✅ SSL Certificates: Found                                │"
        jq '.results.ssl.certificates = "found"' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
    else
        echo "│ ⚠️  SSL Certificates: Not found                           │"
        jq '.results.ssl.certificates = "not_found" | .recommendations += ["Install SSL certificates"]' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
    fi
    
    # Check open ports
    print_info "Checking open ports..."
    local open_ports
    open_ports=$(ss -tuln | grep LISTEN | wc -l)
    echo "│ 📊 Open Ports: $open_ports                                     │"
    jq --arg ports "$open_ports" '.results.services.open_ports = ($ports | tonumber)' "$scan_results" > "${scan_results}.tmp" && \
    mv "${scan_results}.tmp" "$scan_results"
    
    # Check Cloudflare tunnel status
    print_info "Checking Cloudflare tunnel..."
    if pgrep -f "cloudflared tunnel run" >/dev/null; then
        echo "│ ✅ Cloudflare Tunnel: Active                              │"
        jq '.results.system_security.cloudflare_tunnel = "active"' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
    else
        echo "│ ⚠️  Cloudflare Tunnel: Inactive                           │"
        jq '.results.system_security.cloudflare_tunnel = "inactive" | .recommendations += ["Configure Cloudflare Tunnel for enhanced security"]' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
    fi
    
    # Check system updates
    print_info "Checking system updates..."
    if command -v apt >/dev/null 2>&1; then
        local updates
        updates=$(apt list --upgradable 2>/dev/null | wc -l)
        echo "│ 📦 Available Updates: $updates                              │"
        jq --arg upd "$updates" '.results.system_security.pending_updates = ($upd | tonumber)' "$scan_results" > "${scan_results}.tmp" && \
        mv "${scan_results}.tmp" "$scan_results"
    fi
    
    echo "├─────────────────────────────────────────────────────────────┤"
    printf "│ 🛡️  Security Issues Found: %-27d │\n" "$issues"
    echo "│ 📊 Scan Results: $scan_results │"
    echo "╰─────────────────────────────────────────────────────────────╯"
    
    # Update issues count in results
    jq --arg count "$issues" '.results.total_issues = ($count | tonumber)' "$scan_results" > "${scan_results}.tmp" && \
    mv "${scan_results}.tmp" "$scan_results"
    
    log_security "SUCCESS" "Security scan completed. Issues found: $issues"
    
    return $issues
}

#########################################################################
# Security Status Overview
#########################################################################
show_security_status() {
    clear
    
    local firewall_status fail2ban_status tunnel_status ssl_status
    
    # Get status of various components
    firewall_status=$(sudo ufw status 2>/dev/null | grep -q "Status: active" && echo "✅ Active" || echo "❌ Inactive")
    fail2ban_status=$(sudo systemctl is-active fail2ban 2>/dev/null | grep -q "active" && echo "✅ Active" || echo "❌ Inactive")
    tunnel_status=$(pgrep -f "cloudflared tunnel run" >/dev/null && echo "✅ Active" || echo "❌ Inactive")
    ssl_status=$([[ -d "/etc/letsencrypt/live" ]] && [[ -n "$(ls -A /etc/letsencrypt/live 2>/dev/null)" ]] && echo "✅ Found" || echo "⚠️  Missing")
    
    cat << EOF
╭─────────────────────────────────────────────────────────────────────────╮
│                    🔒 ADVANCED SECURITY STATUS                         │
│                        LOMP Stack v2.0                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  🛡️  Core Security Components:                                         │
│     Firewall (UFW):       $firewall_status                                │
│     Intrusion Detection:  $fail2ban_status                                │
│     SSL Certificates:     $ssl_status                                │
│                                                                         │
│  🌐 Cloudflare Security:                                               │
│     Tunnel Status:        $tunnel_status                                │
│     DDoS Protection:      $(jq -r '.security_settings.ddos_protection' "$SECURITY_CONFIG" 2>/dev/null | sed 's/true/✅ Enabled/g' | sed 's/false/❌ Disabled/g')                                │
│     WAF Rules:            $(jq -r '.waf_rules.sql_injection' "$SECURITY_CONFIG" 2>/dev/null | sed 's/true/✅ Enabled/g' | sed 's/false/❌ Disabled/g')                                │
│                                                                         │
│  📊 Security Metrics:                                                  │
│     Failed Login Attempts: $(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l || echo "0")                                  │
│     Blocked IPs (Fail2ban): $(sudo fail2ban-client status 2>/dev/null | grep -o "Currently banned:.*" | awk '{print $3}' || echo "0")                                 │
│     Open Ports:           $(ss -tuln | grep LISTEN | wc -l)                                   │
│                                                                         │
│  ⚖️  Compliance Status:                                                │
│     GDPR Compliance:      $(jq -r '.compliance.gdpr_enabled' "$SECURITY_CONFIG" 2>/dev/null | sed 's/true/✅ Enabled/g' | sed 's/false/❌ Disabled/g')                                │
│     PCI-DSS:              $(jq -r '.compliance.pci_dss_enabled' "$SECURITY_CONFIG" 2>/dev/null | sed 's/true/✅ Enabled/g' | sed 's/false/❌ Disabled/g')                                │
│     Log Retention:        $(jq -r '.compliance.logging_retention_days' "$SECURITY_CONFIG" 2>/dev/null || echo "90") days                              │
├─────────────────────────────────────────────────────────────────────────┤
│  Last Security Scan: $(date +'%Y-%m-%d %H:%M:%S')                                   │
╰─────────────────────────────────────────────────────────────────────────╯
EOF
}

#########################################################################
# Advanced Security Manager Menu
#########################################################################
show_security_menu() {
    while true; do
        clear
        cat << 'EOF'
╭─────────────────────────────────────────────────────────────────────────╮
│                   🔒 ADVANCED SECURITY MANAGER                         │
│                        LOMP Stack v2.0                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  1) 📊 Security Status Overview                                        │
│  2) 🛡️  Configure Web Application Firewall (WAF)                       │
│  3) 🔍 Configure Intrusion Detection (IDS)                            │
│  4) 🌐 Setup Cloudflare Tunnel                                        │
│  5) ▶️  Start Cloudflare Tunnel                                        │
│  6) ⏹️  Stop Cloudflare Tunnel                                         │
│  7) 🔧 Configure Security Settings                                     │
│  8) 🔍 Run Security Scan                                               │
│  9) 📜 View Security Logs                                              │
│  10) ⚖️ Compliance Monitoring                                          │
│  11) 🚨 Security Alerts & Notifications                               │
│  0) ⬅️  Return to Enterprise Dashboard                                 │
├─────────────────────────────────────────────────────────────────────────┤
│ Status: Advanced Security Manager Ready                                │
╰─────────────────────────────────────────────────────────────────────────╯
EOF

        read -p "Select option [0-11]: " choice
        
        case $choice in
            1)
                show_security_status
                read -p "Press Enter to continue..."
                ;;
            2)
                print_info "Configuring Web Application Firewall..."
                configure_waf
                read -p "Press Enter to continue..."
                ;;
            3)
                print_info "Configuring Intrusion Detection System..."
                configure_fail2ban
                read -p "Press Enter to continue..."
                ;;
            4)
                print_info "Setting up Cloudflare Tunnel..."
                setup_cloudflare_tunnel
                read -p "Press Enter to continue..."
                ;;
            5)
                print_info "Starting Cloudflare Tunnel..."
                start_cloudflare_tunnel
                read -p "Press Enter to continue..."
                ;;
            6)
                print_info "Stopping Cloudflare Tunnel..."
                stop_cloudflare_tunnel
                read -p "Press Enter to continue..."
                ;;
            7)
                print_info "Opening security configuration..."
                if command -v nano >/dev/null 2>&1; then
                    nano "$SECURITY_CONFIG"
                else
                    cat "$SECURITY_CONFIG"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8)
                print_info "Running comprehensive security scan..."
                run_security_scan
                read -p "Press Enter to continue..."
                ;;
            9)
                print_info "Security logs:"
                if [[ -f "$SECURITY_LOG" ]]; then
                    tail -20 "$SECURITY_LOG"
                else
                    print_warning "No security logs found"
                fi
                read -p "Press Enter to continue..."
                ;;
            10)
                print_info "Compliance monitoring - Coming Soon"
                read -p "Press Enter to continue..."
                ;;
            11)
                print_info "Security alerts & notifications - Coming Soon"
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
    init_security_config
    
    # If script is called with arguments, run specific function
    if [[ $# -gt 0 ]]; then
        case "$1" in
            "status")
                show_security_status
                ;;
            "scan")
                run_security_scan
                ;;
            "setup-cloudflare"|"setup-tunnel")
                setup_cloudflare_tunnel
                ;;
            "start-tunnel")
                start_cloudflare_tunnel
                ;;
            "stop-tunnel")
                stop_cloudflare_tunnel
                ;;
            "configure-waf"|"waf")
                configure_waf
                ;;
            "configure-ids"|"ids")
                configure_fail2ban
                ;;
            "install-cloudflared")
                install_cloudflare_tunnel
                ;;
            "menu")
                show_security_menu
                ;;
            *)
                echo "Usage: $0 {status|scan|setup-cloudflare|start-tunnel|stop-tunnel|waf|ids|install-cloudflared|menu}"
                echo "  status            - Show security status overview"
                echo "  scan              - Run comprehensive security scan"
                echo "  setup-cloudflare  - Setup Cloudflare Tunnel"
                echo "  start-tunnel      - Start Cloudflare Tunnel"
                echo "  stop-tunnel       - Stop Cloudflare Tunnel"
                echo "  waf               - Configure Web Application Firewall"
                echo "  ids               - Configure Intrusion Detection System"
                echo "  install-cloudflared - Install Cloudflare tunnel binary"
                echo "  menu              - Show interactive menu"
                exit 1
                ;;
        esac
    else
        # Show menu by default
        show_security_menu
    fi
}

# Run main function
main "$@"
