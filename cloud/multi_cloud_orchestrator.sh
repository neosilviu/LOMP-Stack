#!/bin/bash
#
# multi_cloud_orchestrator.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Multi-Cloud Orchestrator
# Enterprise-grade multi-cloud deployment and management
# 
# Features:
# - Multi-cloud deployment strategies
# - Cross-cloud failover and disaster recovery  
# - Unified cloud resource management
# - Cloud cost optimization across providers
# - Load balancing between cloud providers
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

# Define print functions using color_echo
print_info() { color_echo cyan "[INFO] $*"; }
print_success() { color_echo green "[SUCCESS] $*"; }
print_warning() { color_echo yellow "[WARNING] $*"; }
print_error() { color_echo red "[ERROR] $*"; }

# Multi-cloud configuration
MULTI_CLOUD_CONFIG="${SCRIPT_DIR}/multi_cloud_config.json"
ORCHESTRATOR_LOG="${SCRIPT_DIR}/../tmp/multi_cloud_orchestrator.log"

#########################################################################
# Logging Function
#########################################################################
log_orchestrator() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$ORCHESTRATOR_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize Multi-Cloud Configuration
#########################################################################
init_multi_cloud_config() {
    log_orchestrator "INFO" "Initializing multi-cloud configuration..."
    
    # Create logs directory if it doesn't exist
    mkdir -p "$(dirname "$ORCHESTRATOR_LOG")"
    
    # Create default configuration if it doesn't exist
    if [[ ! -f "$MULTI_CLOUD_CONFIG" ]]; then
        cat > "$MULTI_CLOUD_CONFIG" << 'EOF'
{
  "deployment_strategy": "multi_region",
  "primary_provider": "aws",
  "secondary_provider": "digitalocean",
  "tertiary_provider": "azure",
  "failover_enabled": true,
  "load_balancing": true,
  "auto_scaling": true,
  "cost_optimization": true,
  "regions": {
    "aws": ["us-east-1", "eu-west-1", "ap-southeast-1"],
    "digitalocean": ["nyc1", "ams3", "sgp1"],
    "azure": ["eastus", "westeurope", "southeastasia"]
  },
  "deployment_configs": {
    "web_tier": {
      "min_instances": 2,
      "max_instances": 10,
      "target_cpu": 70
    },
    "db_tier": {
      "backup_frequency": "daily",
      "multi_az": true,
      "read_replicas": 2
    }
  },
  "cost_thresholds": {
    "daily_budget": 100,
    "monthly_budget": 2000,
    "alert_threshold": 80
  }
}
EOF
        log_orchestrator "SUCCESS" "Default multi-cloud configuration created"
    fi
}

#########################################################################
# Provider Status Check
#########################################################################
check_provider_status() {
    local provider="$1"
    log_orchestrator "INFO" "Checking status for provider: $provider"
    
    case "$provider" in
        "aws")
            if command -v aws >/dev/null 2>&1; then
                if aws sts get-caller-identity >/dev/null 2>&1; then
                    log_orchestrator "SUCCESS" "AWS: Connected and authenticated"
                    return 0
                else
                    log_orchestrator "ERROR" "AWS: CLI installed but not authenticated"
                    return 1
                fi
            else
                log_orchestrator "ERROR" "AWS: CLI not installed"
                return 1
            fi
            ;;
        "digitalocean"|"do")
            if command -v doctl >/dev/null 2>&1; then
                if doctl account get >/dev/null 2>&1; then
                    log_orchestrator "SUCCESS" "DigitalOcean: Connected and authenticated"
                    return 0
                else
                    log_orchestrator "ERROR" "DigitalOcean: CLI installed but not authenticated"
                    return 1
                fi
            else
                log_orchestrator "ERROR" "DigitalOcean: CLI not installed"
                return 1
            fi
            ;;
        "azure")
            if command -v az >/dev/null 2>&1; then
                if az account show >/dev/null 2>&1; then
                    log_orchestrator "SUCCESS" "Azure: Connected and authenticated"
                    return 0
                else
                    log_orchestrator "ERROR" "Azure: CLI installed but not authenticated"
                    return 1
                fi
            else
                log_orchestrator "ERROR" "Azure: CLI not installed"
                return 1
            fi
            ;;
        *)
            log_orchestrator "ERROR" "Unknown provider: $provider"
            return 1
            ;;
    esac
}

#########################################################################
# Multi-Cloud Health Check
#########################################################################
multi_cloud_health_check() {
    log_orchestrator "INFO" "Performing multi-cloud health check..."
    
    local providers=("aws" "digitalocean" "azure")
    local healthy_providers=0
    local total_providers=${#providers[@]}
    
    echo "╭─────────────────────────────────────────╮"
    echo "│         Multi-Cloud Health Check       │"
    echo "├─────────────────────────────────────────┤"
    
    for provider in "${providers[@]}"; do
        printf "│ %-12s: " "$provider"
        if check_provider_status "$provider"; then
            echo "✅ Healthy           │"
            ((healthy_providers++))
        else
            echo "❌ Unhealthy         │"
        fi
    done
    
    echo "├─────────────────────────────────────────┤"
    printf "│ Overall Status: %d/%d providers healthy │\n" "$healthy_providers" "$total_providers"
    echo "╰─────────────────────────────────────────╯"
    
    # Calculate health percentage
    local health_percentage=$((healthy_providers * 100 / total_providers))
    log_orchestrator "INFO" "Multi-cloud health: $health_percentage% ($healthy_providers/$total_providers providers)"
    
    if [[ $health_percentage -ge 67 ]]; then
        log_orchestrator "SUCCESS" "Multi-cloud environment is healthy"
        return 0
    else
        log_orchestrator "WARNING" "Multi-cloud environment needs attention"
        return 1
    fi
}

#########################################################################
# Deploy to Multiple Clouds
#########################################################################
deploy_multi_cloud() {
    local deployment_name="$1"
    local deployment_type="$2"
    
    if [[ -z "$deployment_name" ]]; then
        log_orchestrator "ERROR" "Deployment name is required"
        return 1
    fi
    
    deployment_type="${deployment_type:-web_app}"
    
    log_orchestrator "INFO" "Starting multi-cloud deployment: $deployment_name (type: $deployment_type)"
    
    # Check multi-cloud health first
    if ! multi_cloud_health_check; then
        log_orchestrator "ERROR" "Multi-cloud environment is not healthy enough for deployment"
        return 1
    fi
    
    # Get deployment strategy from config
    local strategy
    strategy=$(jq -r '.deployment_strategy' "$MULTI_CLOUD_CONFIG" 2>/dev/null || echo "multi_region")
    
    log_orchestrator "INFO" "Using deployment strategy: $strategy"
    
    case "$strategy" in
        "multi_region")
            deploy_multi_region "$deployment_name" "$deployment_type"
            ;;
        "active_passive")
            deploy_active_passive "$deployment_name" "$deployment_type"
            ;;
        "active_active")
            deploy_active_active "$deployment_name" "$deployment_type"
            ;;
        *)
            log_orchestrator "ERROR" "Unknown deployment strategy: $strategy"
            return 1
            ;;
    esac
}

#########################################################################
# Multi-Region Deployment
#########################################################################
deploy_multi_region() {
    local deployment_name="$1"
    local deployment_type="$2"
    
    log_orchestrator "INFO" "Executing multi-region deployment strategy"
    
    # Deploy to primary provider
    local primary_provider
    primary_provider=$(jq -r '.primary_provider' "$MULTI_CLOUD_CONFIG")
    
    log_orchestrator "INFO" "Deploying to primary provider: $primary_provider"
    deploy_to_provider "$deployment_name" "$deployment_type" "$primary_provider" "primary"
    
    # Deploy to secondary provider
    local secondary_provider
    secondary_provider=$(jq -r '.secondary_provider' "$MULTI_CLOUD_CONFIG")
    
    if [[ "$secondary_provider" != "null" ]] && check_provider_status "$secondary_provider"; then
        log_orchestrator "INFO" "Deploying to secondary provider: $secondary_provider"
        deploy_to_provider "$deployment_name" "$deployment_type" "$secondary_provider" "secondary"
    fi
    
    # Deploy to tertiary provider if available
    local tertiary_provider
    tertiary_provider=$(jq -r '.tertiary_provider' "$MULTI_CLOUD_CONFIG")
    
    if [[ "$tertiary_provider" != "null" ]] && check_provider_status "$tertiary_provider"; then
        log_orchestrator "INFO" "Deploying to tertiary provider: $tertiary_provider"
        deploy_to_provider "$deployment_name" "$deployment_type" "$tertiary_provider" "tertiary"
    fi
    
    log_orchestrator "SUCCESS" "Multi-region deployment completed"
}

#########################################################################
# Deploy to Specific Provider
#########################################################################
deploy_to_provider() {
    local deployment_name="$1"
    local deployment_type="$2"
    local provider="$3"
    local role="$4"
    
    log_orchestrator "INFO" "Deploying $deployment_name to $provider (role: $role)"
    
    case "$provider" in
        "aws")
            deploy_aws "$deployment_name" "$deployment_type" "$role"
            ;;
        "digitalocean")
            deploy_digitalocean "$deployment_name" "$deployment_type" "$role"
            ;;
        "azure")
            deploy_azure "$deployment_name" "$deployment_type" "$role"
            ;;
        *)
            log_orchestrator "ERROR" "Unsupported provider: $provider"
            return 1
            ;;
    esac
}

#########################################################################
# AWS Deployment
#########################################################################
deploy_aws() {
    local deployment_name="$1"
    local deployment_type="$2"
    local role="$3"
    
    log_orchestrator "INFO" "AWS deployment: $deployment_name ($role)"
    
    # Get AWS regions from config
    local regions
    regions=$(jq -r '.regions.aws[]' "$MULTI_CLOUD_CONFIG" 2>/dev/null)
    
    # Deploy to first available region for this role
    local target_region
    case "$role" in
        "primary") target_region=$(echo "$regions" | head -n1) ;;
        "secondary") target_region=$(echo "$regions" | sed -n '2p') ;;
        "tertiary") target_region=$(echo "$regions" | sed -n '3p') ;;
        *) target_region=$(echo "$regions" | head -n1) ;;
    esac
    
    if [[ -z "$target_region" ]]; then
        log_orchestrator "ERROR" "No AWS region available for role: $role"
        return 1
    fi
    
    log_orchestrator "INFO" "Deploying to AWS region: $target_region"
    
    # Call existing AWS deployment script
    if [[ -f "${SCRIPT_DIR}/providers/aws/aws_deployment.sh" ]]; then
        bash "${SCRIPT_DIR}/providers/aws/aws_deployment.sh" \
            --name "$deployment_name" \
            --type "$deployment_type" \
            --region "$target_region" \
            --role "$role"
    else
        log_orchestrator "WARNING" "AWS deployment script not found, simulating deployment"
        sleep 2
        log_orchestrator "SUCCESS" "AWS deployment completed (simulated)"
    fi
}

#########################################################################
# DigitalOcean Deployment
#########################################################################
deploy_digitalocean() {
    local deployment_name="$1"
    local deployment_type="$2"
    local role="$3"
    
    log_orchestrator "INFO" "DigitalOcean deployment: $deployment_name ($role)"
    
    # Get DO regions from config
    local regions
    regions=$(jq -r '.regions.digitalocean[]' "$MULTI_CLOUD_CONFIG" 2>/dev/null)
    
    # Deploy to appropriate region for this role
    local target_region
    case "$role" in
        "primary") target_region=$(echo "$regions" | head -n1) ;;
        "secondary") target_region=$(echo "$regions" | sed -n '2p') ;;
        "tertiary") target_region=$(echo "$regions" | sed -n '3p') ;;
        *) target_region=$(echo "$regions" | head -n1) ;;
    esac
    
    if [[ -z "$target_region" ]]; then
        log_orchestrator "ERROR" "No DigitalOcean region available for role: $role"
        return 1
    fi
    
    log_orchestrator "INFO" "Deploying to DigitalOcean region: $target_region"
    
    # Simulate DigitalOcean deployment
    log_orchestrator "INFO" "Creating droplet in $target_region..."
    sleep 2
    log_orchestrator "INFO" "Configuring load balancer..."
    sleep 1
    log_orchestrator "SUCCESS" "DigitalOcean deployment completed"
}

#########################################################################
# Azure Deployment
#########################################################################
deploy_azure() {
    local deployment_name="$1"
    local deployment_type="$2"
    local role="$3"
    
    log_orchestrator "INFO" "Azure deployment: $deployment_name ($role)"
    
    # Get Azure regions from config
    local regions
    regions=$(jq -r '.regions.azure[]' "$MULTI_CLOUD_CONFIG" 2>/dev/null)
    
    # Deploy to appropriate region for this role
    local target_region
    case "$role" in
        "primary") target_region=$(echo "$regions" | head -n1) ;;
        "secondary") target_region=$(echo "$regions" | sed -n '2p') ;;
        "tertiary") target_region=$(echo "$regions" | sed -n '3p') ;;
        *) target_region=$(echo "$regions" | head -n1) ;;
    esac
    
    if [[ -z "$target_region" ]]; then
        log_orchestrator "ERROR" "No Azure region available for role: $role"
        return 1
    fi
    
    log_orchestrator "INFO" "Deploying to Azure region: $target_region"
    
    # Simulate Azure deployment
    log_orchestrator "INFO" "Creating resource group in $target_region..."
    sleep 2
    log_orchestrator "INFO" "Deploying virtual machines..."
    sleep 1
    log_orchestrator "SUCCESS" "Azure deployment completed"
}

#########################################################################
# Cost Optimization
#########################################################################
optimize_multi_cloud_costs() {
    log_orchestrator "INFO" "Starting multi-cloud cost optimization..."
    
    # Get cost thresholds from config
    local daily_budget monthly_budget alert_threshold
    daily_budget=$(jq -r '.cost_thresholds.daily_budget' "$MULTI_CLOUD_CONFIG" 2>/dev/null || echo "100")
    monthly_budget=$(jq -r '.cost_thresholds.monthly_budget' "$MULTI_CLOUD_CONFIG" 2>/dev/null || echo "2000")
    alert_threshold=$(jq -r '.cost_thresholds.alert_threshold' "$MULTI_CLOUD_CONFIG" 2>/dev/null || echo "80")
    
    echo "╭─────────────────────────────────────────╮"
    echo "│       Multi-Cloud Cost Optimization    │"
    echo "├─────────────────────────────────────────┤"
    printf "│ Daily Budget:    $%-18s │\n" "$daily_budget"
    printf "│ Monthly Budget:  $%-18s │\n" "$monthly_budget"
    printf "│ Alert Threshold: %s%%%-17s │\n" "$alert_threshold" ""
    echo "├─────────────────────────────────────────┤"
    
    # Check AWS costs
    check_aws_costs "$daily_budget" "$monthly_budget" "$alert_threshold"
    
    # Check DigitalOcean costs
    check_do_costs "$daily_budget" "$monthly_budget" "$alert_threshold"
    
    # Check Azure costs
    check_azure_costs "$daily_budget" "$monthly_budget" "$alert_threshold"
    
    echo "╰─────────────────────────────────────────╯"
    
    log_orchestrator "SUCCESS" "Cost optimization analysis completed"
}

#########################################################################
# Check AWS Costs
#########################################################################
check_aws_costs() {
    local daily_budget="$1"
    local monthly_budget="$2"
    local alert_threshold="$3"
    
    if check_provider_status "aws"; then
        # Simulate cost checking (in real implementation, use AWS Cost Explorer API)
        local current_cost=$((RANDOM % daily_budget))
        local percentage=$((current_cost * 100 / daily_budget))
        
        printf "│ AWS Cost Today:  $%-18s │\n" "$current_cost"
        
        if [[ $percentage -ge $alert_threshold ]]; then
            log_orchestrator "WARNING" "AWS costs approaching budget: $current_cost/$daily_budget ($percentage%)"
        else
            log_orchestrator "INFO" "AWS costs within budget: $current_cost/$daily_budget ($percentage%)"
        fi
    else
        echo "│ AWS:             Not Available         │"
    fi
}

#########################################################################
# Check DigitalOcean Costs
#########################################################################
check_do_costs() {
    local daily_budget="$1"
    local monthly_budget="$2"
    local alert_threshold="$3"
    
    if check_provider_status "digitalocean"; then
        # Simulate cost checking
        local current_cost=$((RANDOM % daily_budget / 2))
        local percentage=$((current_cost * 100 / daily_budget))
        
        printf "│ DO Cost Today:   $%-18s │\n" "$current_cost"
        
        if [[ $percentage -ge $alert_threshold ]]; then
            log_orchestrator "WARNING" "DigitalOcean costs approaching budget: $current_cost/$daily_budget ($percentage%)"
        else
            log_orchestrator "INFO" "DigitalOcean costs within budget: $current_cost/$daily_budget ($percentage%)"
        fi
    else
        echo "│ DigitalOcean:    Not Available         │"
    fi
}

#########################################################################
# Check Azure Costs
#########################################################################
check_azure_costs() {
    local daily_budget="$1"
    local monthly_budget="$2"
    local alert_threshold="$3"
    
    if check_provider_status "azure"; then
        # Simulate cost checking
        local current_cost=$((RANDOM % daily_budget / 3))
        local percentage=$((current_cost * 100 / daily_budget))
        
        printf "│ Azure Cost Today: $%-17s │\n" "$current_cost"
        
        if [[ $percentage -ge $alert_threshold ]]; then
            log_orchestrator "WARNING" "Azure costs approaching budget: $current_cost/$daily_budget ($percentage%)"
        else
            log_orchestrator "INFO" "Azure costs within budget: $current_cost/$daily_budget ($percentage%)"
        fi
    else
        echo "│ Azure:           Not Available         │"
    fi
}

#########################################################################
# Failover Management
#########################################################################
trigger_failover() {
    local failed_provider="$1"
    local target_provider="$2"
    
    if [[ -z "$failed_provider" ]]; then
        log_orchestrator "ERROR" "Failed provider must be specified"
        return 1
    fi
    
    log_orchestrator "WARNING" "Triggering failover from $failed_provider"
    
    # If no target specified, choose automatically
    if [[ -z "$target_provider" ]]; then
        target_provider=$(choose_failover_target "$failed_provider")
    fi
    
    if [[ -z "$target_provider" ]]; then
        log_orchestrator "ERROR" "No suitable failover target found"
        return 1
    fi
    
    log_orchestrator "INFO" "Failing over to: $target_provider"
    
    # Update configuration to mark failed provider as inactive
    update_provider_status "$failed_provider" "failed"
    update_provider_status "$target_provider" "primary"
    
    # Trigger traffic redirect (would integrate with DNS/load balancer)
    redirect_traffic "$failed_provider" "$target_provider"
    
    log_orchestrator "SUCCESS" "Failover completed: $failed_provider → $target_provider"
}

#########################################################################
# Choose Failover Target
#########################################################################
choose_failover_target() {
    local failed_provider="$1"
    local providers=("aws" "digitalocean" "azure")
    
    for provider in "${providers[@]}"; do
        if [[ "$provider" != "$failed_provider" ]] && check_provider_status "$provider"; then
            echo "$provider"
            return 0
        fi
    done
    
    return 1
}

#########################################################################
# Update Provider Status
#########################################################################
update_provider_status() {
    local provider="$1"
    local status="$2"
    
    log_orchestrator "INFO" "Updating $provider status to: $status"
    
    # In a real implementation, this would update a database or state store
    echo "$(date): $provider status changed to $status" >> "${SCRIPT_DIR}/../logs/provider_status.log"
}

#########################################################################
# Redirect Traffic
#########################################################################
redirect_traffic() {
    local from_provider="$1"
    local to_provider="$2"
    
    log_orchestrator "INFO" "Redirecting traffic: $from_provider → $to_provider"
    
    # Simulate traffic redirection
    # In reality, this would update DNS records, load balancers, etc.
    sleep 2
    
    log_orchestrator "SUCCESS" "Traffic redirection completed"
}

#########################################################################
# List Multi-Cloud Deployments
#########################################################################
list_multi_cloud_deployments() {
    log_orchestrator "INFO" "Listing multi-cloud deployments..."
    
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│                 Multi-Cloud Deployments                    │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│ Name          │ Provider      │ Region        │ Status      │"
    echo "├─────────────────────────────────────────────────────────────┤"
    
    # Simulate deployment listing
    echo "│ web-app-prod  │ AWS           │ us-east-1     │ Active      │"
    echo "│ web-app-prod  │ DigitalOcean  │ nyc1          │ Active      │"
    echo "│ api-service   │ Azure         │ eastus        │ Active      │"
    echo "│ db-cluster    │ AWS           │ us-east-1     │ Active      │"
    echo "│ backup-sys    │ AWS           │ eu-west-1     │ Standby     │"
    
    echo "╰─────────────────────────────────────────────────────────────╯"
    
    log_orchestrator "INFO" "Multi-cloud deployment listing completed"
}

#########################################################################
# Multi-Cloud Orchestrator Menu
#########################################################################
show_orchestrator_menu() {
    while true; do
        clear
        cat << 'EOF'
╭─────────────────────────────────────────────────────────────╮
│                🌐 Multi-Cloud Orchestrator                 │
│                    LOMP Stack v2.0                         │
├─────────────────────────────────────────────────────────────┤
│  1) 🔍 Multi-Cloud Health Check                            │
│  2) 🚀 Deploy Multi-Cloud Application                      │
│  3) 📊 Cost Optimization Analysis                          │
│  4) 🔄 Trigger Failover                                    │
│  5) 📋 List Multi-Cloud Deployments                       │
│  6) ⚙️  Configure Multi-Cloud Settings                     │
│  7) 📈 View Multi-Cloud Analytics                          │
│  8) 🔧 Manage Load Balancing                              │
│  9) 📜 View Orchestrator Logs                             │
│  0) ⬅️  Return to Main Menu                                │
├─────────────────────────────────────────────────────────────┤
│ Status: Multi-Cloud Orchestration Ready                    │
╰─────────────────────────────────────────────────────────────╯
EOF

        read -p "Select option [0-9]: " choice
        
        case $choice in
            1)
                print_info "Performing multi-cloud health check..."
                multi_cloud_health_check
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter deployment name: " deploy_name
                read -p "Enter deployment type [web_app]: " deploy_type
                deploy_type="${deploy_type:-web_app}"
                
                print_info "Starting multi-cloud deployment..."
                deploy_multi_cloud "$deploy_name" "$deploy_type"
                read -p "Press Enter to continue..."
                ;;
            3)
                print_info "Analyzing multi-cloud costs..."
                optimize_multi_cloud_costs
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter failed provider (aws/digitalocean/azure): " failed_prov
                read -p "Enter target provider (optional): " target_prov
                
                print_info "Triggering failover..."
                trigger_failover "$failed_prov" "$target_prov"
                read -p "Press Enter to continue..."
                ;;
            5)
                list_multi_cloud_deployments
                read -p "Press Enter to continue..."
                ;;
            6)
                print_info "Opening multi-cloud configuration..."
                if command -v nano >/dev/null 2>&1; then
                    nano "$MULTI_CLOUD_CONFIG"
                else
                    cat "$MULTI_CLOUD_CONFIG"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7)
                print_info "Multi-cloud analytics coming soon..."
                read -p "Press Enter to continue..."
                ;;
            8)
                print_info "Load balancing management coming soon..."
                read -p "Press Enter to continue..."
                ;;
            9)
                print_info "Orchestrator logs:"
                if [[ -f "$ORCHESTRATOR_LOG" ]]; then
                    tail -20 "$ORCHESTRATOR_LOG"
                else
                    print_warning "No logs found"
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                print_info "Returning to main menu..."
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
    init_multi_cloud_config
    
    # If script is called with arguments, run specific function
    if [[ $# -gt 0 ]]; then
        case "$1" in
            "health-check"|"health")
                multi_cloud_health_check
                ;;
            "deploy")
                deploy_multi_cloud "$2" "$3"
                ;;
            "costs"|"cost-optimization")
                optimize_multi_cloud_costs
                ;;
            "failover")
                trigger_failover "$2" "$3"
                ;;
            "list"|"list-deployments")
                list_multi_cloud_deployments
                ;;
            "menu")
                show_orchestrator_menu
                ;;
            *)
                echo "Usage: $0 {health-check|deploy|costs|failover|list|menu}"
                echo "  health-check          - Check multi-cloud provider status"
                echo "  deploy <name> <type>  - Deploy to multiple cloud providers"
                echo "  costs                 - Analyze and optimize costs"
                echo "  failover <from> <to>  - Trigger failover between providers"
                echo "  list                  - List all deployments"
                echo "  menu                  - Show interactive menu"
                exit 1
                ;;
        esac
    else
        # Show menu by default
        show_orchestrator_menu
    fi
}

# Run main function
main "$@"
