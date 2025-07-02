#!/bin/bash
#
# cloud_integration_manager.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Cloud Integration Manager
# =============================================================================
# Descriere: Manager centralizat pentru integrarea cu provideri cloud (AWS, DigitalOcean, Azure)
# Autor: LOMP Stack Development Team
# Versiune: 2.0.0 - Faza 4 (Enterprise/Cloud)
# =============================================================================

# Configurare paths și dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPERS_DIR="$(dirname "$SCRIPT_DIR")/helpers"
UTILS_DIR="$HELPERS_DIR/utils"

# Import dependencies
source "$UTILS_DIR/dependency_manager.sh" 2>/dev/null || { echo "❌ Nu găsesc dependency_manager.sh"; exit 1; }
source "$UTILS_DIR/error_handler.sh" 2>/dev/null || { echo "❌ Nu găsesc error_handler.sh"; exit 1; }
source "$UTILS_DIR/state_manager.sh" 2>/dev/null || { echo "❌ Nu găsesc state_manager.sh"; exit 1; }
source "$UTILS_DIR/ui_manager.sh" 2>/dev/null || { echo "❌ Nu găsesc ui_manager.sh"; exit 1; }

# Cloud provider configs
declare -A CLOUD_PROVIDERS=(
    ["aws"]="Amazon Web Services"
    ["digitalocean"]="DigitalOcean"
    ["azure"]="Microsoft Azure"
    ["gcp"]="Google Cloud Platform"
    ["linode"]="Linode"
)

# Global variables
CLOUD_CONFIG_DIR="$SCRIPT_DIR/configs"
CLOUD_SCRIPTS_DIR="$SCRIPT_DIR/providers"
CLOUD_TEMPLATES_DIR="$SCRIPT_DIR/templates"

# =============================================================================
# FUNCȚII UTILITARE
# =============================================================================

# Inițializează structura cloud
init_cloud_structure() {
    local action="Inițializare structură cloud"
    ui_start_action "$action"
    
    # Creează directoarele necesare
    mkdir -p "$CLOUD_CONFIG_DIR" "$CLOUD_SCRIPTS_DIR" "$CLOUD_TEMPLATES_DIR"
    mkdir -p "$CLOUD_SCRIPTS_DIR"/{aws,digitalocean,azure,gcp,linode}
    mkdir -p "$CLOUD_TEMPLATES_DIR"/{infrastructure,applications,monitoring}
    
    # Creează fișierele de configurare
    if [[ ! -f "$CLOUD_CONFIG_DIR/cloud_config.json" ]]; then
        create_default_cloud_config
    fi
    
    ui_success "$action completă"
}

# Creează configurația default pentru cloud
create_default_cloud_config() {
    cat > "$CLOUD_CONFIG_DIR/cloud_config.json" << 'EOF'
{
    "version": "2.0.0",
    "cloud_providers": {
        "aws": {
            "enabled": false,
            "region": "us-east-1",
            "credentials_file": "~/.aws/credentials",
            "services": {
                "ec2": true,
                "rds": true,
                "s3": true,
                "cloudfront": true,
                "route53": true
            }
        },
        "digitalocean": {
            "enabled": false,
            "region": "nyc3",
            "api_token_file": "~/.config/doctl/config.yaml",
            "services": {
                "droplets": true,
                "spaces": true,
                "load_balancers": true,
                "databases": true,
                "cdn": true
            }
        },
        "azure": {
            "enabled": false,
            "location": "East US",
            "subscription_id": "",
            "services": {
                "vms": true,
                "storage": true,
                "cdn": true,
                "database": true,
                "app_service": true
            }
        }
    },
    "global_settings": {
        "auto_backup": true,
        "monitoring": true,
        "ssl_enabled": true,
        "cdn_enabled": true,
        "multi_region": false
    }
}
EOF
}

# =============================================================================
# FUNCȚII CLOUD PROVIDER
# =============================================================================

# Verifică statusul provider-ilor cloud
check_cloud_providers() {
    ui_header "📡 Verificare Cloud Providers"
    
    for provider in "${!CLOUD_PROVIDERS[@]}"; do
        local status="❌ Nu este configurat"
        local cli_available="❌"
        
        case "$provider" in
            "aws")
                if command -v aws >/dev/null 2>&1; then
                    cli_available="✅"
                    if aws sts get-caller-identity >/dev/null 2>&1; then
                        status="✅ Configurat și activ"
                    else
                        status="⚠️ CLI instalat, credențiale lipsă"
                    fi
                fi
                ;;
            "digitalocean")
                if command -v doctl >/dev/null 2>&1; then
                    cli_available="✅"
                    if doctl account get >/dev/null 2>&1; then
                        status="✅ Configurat și activ"
                    else
                        status="⚠️ CLI instalat, token lipsă"
                    fi
                fi
                ;;
            "azure")
                if command -v az >/dev/null 2>&1; then
                    cli_available="✅"
                    if az account show >/dev/null 2>&1; then
                        status="✅ Configurat și activ"
                    else
                        status="⚠️ CLI instalat, autentificare lipsă"
                    fi
                fi
                ;;
        esac
        
        ui_info "$(printf "%-15s CLI: %s Status: %s" "${CLOUD_PROVIDERS[$provider]}" "$cli_available" "$status")"
    done
}

# Configurează un cloud provider
configure_cloud_provider() {
    local provider="$1"
    
    if [[ -z "$provider" ]] || [[ ! "${CLOUD_PROVIDERS[$provider]}" ]]; then
        ui_error "Provider invalid: $provider"
        return 1
    fi
    
    ui_header "🔧 Configurare ${CLOUD_PROVIDERS[$provider]}"
    
    case "$provider" in
        "aws")
            configure_aws_provider
            ;;
        "digitalocean")
            configure_digitalocean_provider
            ;;
        "azure")
            configure_azure_provider
            ;;
        *)
            ui_warning "Configurarea pentru $provider nu este încă implementată"
            ;;
    esac
}

# Configurează AWS
configure_aws_provider() {
    ui_info "Configurare AWS CLI și credențiale..."
    
    # Verifică dacă AWS CLI este instalat
    if ! command -v aws >/dev/null 2>&1; then
        ui_info "Instalare AWS CLI..."
        if command -v snap >/dev/null 2>&1; then
            snap install aws-cli --classic
        elif command -v apt >/dev/null 2>&1; then
            apt update && apt install -y awscli
        else
            ui_error "Nu pot instala AWS CLI automat. Instalează manual."
            return 1
        fi
    fi
    
    # Configurare interactivă
    ui_info "Te rog să introduci credențialele AWS:"
    aws configure
    
    # Test conexiune
    if aws sts get-caller-identity >/dev/null 2>&1; then
        ui_success "AWS configurat cu succes!"
        update_cloud_config "aws" "enabled" "true"
    else
        ui_error "Configurarea AWS a eșuat"
        return 1
    fi
}

# Configurează DigitalOcean
configure_digitalocean_provider() {
    ui_info "Configurare DigitalOcean CLI..."
    
    # Verifică dacă doctl este instalat
    if ! command -v doctl >/dev/null 2>&1; then
        ui_info "Instalare doctl..."
        local doctl_version="1.98.1"
        local doctl_url="https://github.com/digitalocean/doctl/releases/download/v${doctl_version}/doctl-${doctl_version}-linux-amd64.tar.gz"
        
        wget -O - "$doctl_url" | tar -xzC /usr/local/bin/
        chmod +x /usr/local/bin/doctl
    fi
    
    # Configurare token
    ui_info "Te rog să introduci API token-ul DigitalOcean:"
    read -rsp "API Token: " do_token
    echo
    
    doctl auth init --access-token "$do_token"
    
    # Test conexiune
    if doctl account get >/dev/null 2>&1; then
        ui_success "DigitalOcean configurat cu succes!"
        update_cloud_config "digitalocean" "enabled" "true"
    else
        ui_error "Configurarea DigitalOcean a eșuat"
        return 1
    fi
}

# Configurează Azure
configure_azure_provider() {
    ui_info "Configurare Azure CLI..."
    
    # Verifică dacă Azure CLI este instalat
    if ! command -v az >/dev/null 2>&1; then
        ui_info "Instalare Azure CLI..."
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    fi
    
    # Login interactiv
    ui_info "Login în Azure (se va deschide browser-ul):"
    az login
    
    # Test conexiune
    if az account show >/dev/null 2>&1; then
        ui_success "Azure configurat cu succes!"
        update_cloud_config "azure" "enabled" "true"
    else
        ui_error "Configurarea Azure a eșuat"
        return 1
    fi
}

# =============================================================================
# FUNCȚII DE DEPLOYMENT
# =============================================================================

# Deploy aplicație în cloud
deploy_to_cloud() {
    local provider="$1"
    local app_type="$2"
    local environment="$3"
    
    [[ -z "$provider" ]] && { ui_error "Provider lipsă"; return 1; }
    [[ -z "$app_type" ]] && app_type="wordpress"
    [[ -z "$environment" ]] && environment="production"
    
    ui_header "🚀 Deploy $app_type în ${CLOUD_PROVIDERS[$provider]} ($environment)"
    
    case "$provider" in
        "aws")
            deploy_to_aws "$app_type" "$environment"
            ;;
        "digitalocean")
            deploy_to_digitalocean "$app_type" "$environment"
            ;;
        "azure")
            deploy_to_azure "$app_type" "$environment"
            ;;
        *)
            ui_error "Deploy pentru $provider nu este implementat"
            return 1
            ;;
    esac
}

# Deploy pe AWS
deploy_to_aws() {
    local app_type="$1"
    local environment="$2"
    
    ui_info "Inițiere deployment AWS pentru $app_type..."
    
    # Verifică configurarea
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        ui_error "AWS nu este configurat corect"
        return 1
    fi
    
    # Rulează scriptul specific AWS
    local aws_script="$CLOUD_SCRIPTS_DIR/aws/deploy_${app_type}.sh"
    if [[ -f "$aws_script" ]]; then
        bash "$aws_script" "$environment"
    else
        ui_warning "Script de deployment AWS pentru $app_type nu există"
        create_aws_deployment_script "$app_type"
        ui_info "Script creat. Rulează din nou pentru deployment."
    fi
}

# =============================================================================
# FUNCȚII DE MANAGEMENT
# =============================================================================

# Monitorizare resurse cloud
monitor_cloud_resources() {
    ui_header "📊 Monitorizare Resurse Cloud"
    
    for provider in "${!CLOUD_PROVIDERS[@]}"; do
        if is_provider_enabled "$provider"; then
            ui_info "📡 Verificare resurse ${CLOUD_PROVIDERS[$provider]}..."
            
            case "$provider" in
                "aws")
                    monitor_aws_resources
                    ;;
                "digitalocean")
                    monitor_digitalocean_resources
                    ;;
                "azure")
                    monitor_azure_resources
                    ;;
            esac
            echo
        fi
    done
}

# Monitorizare AWS
monitor_aws_resources() {
    echo "EC2 Instances:"
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress]' --output table 2>/dev/null || echo "  ❌ Nu pot accesa EC2"
    
    echo "RDS Instances:"
    aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,DBInstanceClass]' --output table 2>/dev/null || echo "  ❌ Nu pot accesa RDS"
    
    echo "S3 Buckets:"
    aws s3 ls 2>/dev/null || echo "  ❌ Nu pot accesa S3"
}

# Monitorizare DigitalOcean
monitor_digitalocean_resources() {
    echo "Droplets:"
    doctl compute droplet list --format "ID,Name,Status,PublicIPv4,Memory,Disk" 2>/dev/null || echo "  ❌ Nu pot accesa Droplets"
    
    echo "Load Balancers:"
    doctl compute load-balancer list --format "ID,Name,Status,IP" 2>/dev/null || echo "  ❌ Nu pot accesa Load Balancers"
    
    echo "Databases:"
    doctl databases list --format "ID,Name,Status,Engine,Size" 2>/dev/null || echo "  ❌ Nu pot accesa Databases"
}

# =============================================================================
# FUNCȚII HELPER
# =============================================================================

# Verifică dacă un provider este activat
is_provider_enabled() {
    local provider="$1"
    local config_file="$CLOUD_CONFIG_DIR/cloud_config.json"
    
    if [[ -f "$config_file" ]]; then
        local enabled
        enabled=$(jq -r ".cloud_providers.${provider}.enabled" "$config_file" 2>/dev/null)
        [[ "$enabled" == "true" ]]
    else
        return 1
    fi
}

# Actualizează configurația cloud
update_cloud_config() {
    local provider="$1"
    local key="$2"
    local value="$3"
    local config_file="$CLOUD_CONFIG_DIR/cloud_config.json"
    
    if [[ -f "$config_file" ]]; then
        jq ".cloud_providers.${provider}.${key} = ${value}" "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    fi
}

# Afișează meniul principal
show_cloud_menu() {
    ui_header "☁️ LOMP Stack v2.0 - Cloud Integration Manager"
    
    echo "1. 📡 Verifică status cloud providers"
    echo "2. 🔧 Configurează cloud provider"
    echo "3. 🚀 Deploy aplicație în cloud"
    echo "4. 📊 Monitorizare resurse cloud"
    echo "5. 🌐 Gestionare multi-cloud"
    echo "6. ⚙️ Configurări avansate"
    echo "7. 📚 Documentație și exemple"
    echo "8. 🗄️ Rclone Management"
    echo "0. ↩️ Ieșire"
    echo
}

# Meniul de configurare provider
show_provider_config_menu() {
    ui_header "🔧 Configurare Cloud Provider"
    
    local i=1
    for provider in "${!CLOUD_PROVIDERS[@]}"; do
        local status="❌"
        if is_provider_enabled "$provider"; then
            status="✅"
        fi
        echo "$i. $status ${CLOUD_PROVIDERS[$provider]}"
        ((i++))
    done
    echo "0. ↩️ Înapoi"
    echo
}

# =============================================================================
# FUNCȚIE PRINCIPALĂ
# =============================================================================

main() {
    # Verifică dependencies
    check_dependencies "jq,curl,wget"
    
    # Inițializează structura
    init_cloud_structure
    
    # Meniu principal
    while true; do
        show_cloud_menu
        read -rp "Selectează opțiunea: " choice
        
        case "$choice" in
            1)
                check_cloud_providers
                read -rp "Apasă Enter pentru a continua..."
                ;;
            2)
                show_provider_config_menu
                read -rp "Selectează provider (1-${#CLOUD_PROVIDERS[@]}): " provider_choice
                
                local providers_array
                mapfile -t providers_array < <(printf '%s\n' "${!CLOUD_PROVIDERS[@]}" | sort)
                local selected_provider="${providers_array[$((provider_choice-1))]}"
                
                if [[ -n "$selected_provider" ]]; then
                    configure_cloud_provider "$selected_provider"
                fi
                ;;
            3)
                echo "Providers disponibili:"
                local i=1
                for provider in "${!CLOUD_PROVIDERS[@]}"; do
                    if is_provider_enabled "$provider"; then
                        echo "$i. ${CLOUD_PROVIDERS[$provider]} ✅"
                        ((i++))
                    fi
                done
                
                read -rp "Selectează provider pentru deployment: " deploy_choice
                read -rp "Tip aplicație (wordpress/lamp/custom): " app_type
                read -rp "Environment (production/staging/development): " environment
                
                # Procesează selecția deployment-ului
                if [[ "$deploy_choice" =~ ^[0-9]+$ ]] && (( deploy_choice > 0 )); then
                    ui_info "🚀 Inițiere deployment cu provider $deploy_choice pentru $app_type în $environment"
                    # Logic pentru deployment va fi implementată
                else
                    ui_error "Selecție invalidă pentru deployment"
                fi
                ;;
            4)
                monitor_cloud_resources
                read -rp "Apasă Enter pentru a continua..."
                ;;
            5)
                ui_info "🌐 Funcționalitatea multi-cloud va fi implementată în versiunile următoare"
                ;;
            6)
                ui_info "⚙️ Configurări avansate vor fi implementate în versiunile următoare"
                ;;
            7)
                ui_info "📚 Documentația va fi disponibilă în versiunile următoare"
                ;;
            8)
                show_rclone_menu
                ;;
            0)
                ui_success "Ieșire din Cloud Integration Manager"
                break
                ;;
            *)
                ui_error "Opțiune invalidă"
                ;;
        esac
        echo
    done
}

# Install și configurare rclone
install_rclone() {
    log_info "Instalare rclone..." "cyan"
    
    if command -v rclone >/dev/null 2>&1; then
        log_info "Rclone este deja instalat" "green"
        return 0
    fi
    
    # Detectează arhitectura
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l) arch="arm" ;;
        *) arch="amd64" ;;
    esac
    
    # Download și instalare rclone
    log_info "Download rclone pentru arhitectura: $arch" "blue"
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if curl -o "$temp_dir/rclone.zip" "https://downloads.rclone.org/rclone-current-linux-${arch}.zip"; then
        log_debug "Rclone descărcat cu succes"
    else
        log_error "Eroare la descărcarea rclone"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extragere și instalare
    if command -v unzip >/dev/null 2>&1; then
        cd "$temp_dir" || return 1
        unzip -q rclone.zip
        
        local rclone_dir
        rclone_dir=$(find . -name "rclone-*" -type d | head -1)
        
        if [[ -n "$rclone_dir" && -f "$rclone_dir/rclone" ]]; then
            sudo cp "$rclone_dir/rclone" /usr/local/bin/
            sudo chmod +x /usr/local/bin/rclone
            log_info "Rclone instalat cu succes în /usr/local/bin/" "green"
        else
            log_error "Fișierul rclone nu a fost găsit în arhivă"
            return 1
        fi
    else
        log_error "Unzip nu este disponibil pentru extragerea rclone"
        return 1
    fi
    
    # Curățare
    rm -rf "$temp_dir"
    
    # Verificare instalare
    if command -v rclone >/dev/null 2>&1; then
        local version
        version=$(rclone version | head -1)
        log_info "Rclone instalat: $version" "green"
        return 0
    else
        log_error "Instalarea rclone a eșuat"
        return 1
    fi
}

# Configurare remote rclone
configure_rclone_remote() {
    local remote_name="$1"
    local provider="$2"
    local config_params="$3"
    
    if [[ -z "$remote_name" || -z "$provider" ]]; then
        log_error "Nume remote și provider sunt necesare pentru configurarea rclone"
        return 1
    fi
    
    log_info "Configurare rclone remote: $remote_name ($provider)" "cyan"
    
    # Verifică dacă remote-ul există deja
    if rclone listremotes | grep -q "^${remote_name}:$"; then
        log_warning "Remote-ul $remote_name există deja"
        read -p "Doriți să îl suprascrieți? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    case "$provider" in
        "s3"|"aws")
            configure_rclone_s3 "$remote_name" "$config_params"
            ;;
        "dropbox")
            configure_rclone_dropbox "$remote_name"
            ;;
        "gdrive"|"google")
            configure_rclone_gdrive "$remote_name"
            ;;
        "onedrive"|"microsoft")
            configure_rclone_onedrive "$remote_name"
            ;;
        "ftp")
            configure_rclone_ftp "$remote_name" "$config_params"
            ;;
        "sftp")
            configure_rclone_sftp "$remote_name" "$config_params"
            ;;
        *)
            log_error "Provider rclone necunoscut: $provider"
            return 1
            ;;
    esac
}

# Configurare rclone pentru Amazon S3
configure_rclone_s3() {
    local remote_name="$1"
    local config_params="$2"
    
    log_info "Configurare rclone pentru Amazon S3..." "blue"
    
    # Parametri necesari pentru S3
    echo "Pentru configurarea S3, veți avea nevoie de:"
    echo "- Access Key ID"
    echo "- Secret Access Key"  
    echo "- Region (opțional)"
    echo
    
    read -p "Access Key ID: " -r access_key
    read -s -p "Secret Access Key: " secret_key
    echo
    read -p "Region (default: us-east-1): " -r region
    region=${region:-us-east-1}
    
    # Creează configurația rclone
    rclone config create "$remote_name" s3 \
        provider AWS \
        access_key_id "$access_key" \
        secret_access_key "$secret_key" \
        region "$region"
    
    if [[ $? -eq 0 ]]; then
        log_info "Remote S3 '$remote_name' configurat cu succes" "green"
        save_cloud_config "rclone" "$remote_name" "s3" "configured"
    else
        log_error "Eroare la configurarea remote-ului S3"
        return 1
    fi
}

# Configurare rclone pentru Google Drive
configure_rclone_gdrive() {
    local remote_name="$1"
    
    log_info "Configurare rclone pentru Google Drive..." "blue"
    echo "ATENȚIE: Configurarea Google Drive necesită browser pentru autentificare."
    echo "Asigurați-vă că aveți acces la un browser web."
    
    read -p "Continuați? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    # Configurare interactivă pentru Google Drive
    rclone config create "$remote_name" drive
    
    if [[ $? -eq 0 ]]; then
        log_info "Remote Google Drive '$remote_name' configurat cu succes" "green"
        save_cloud_config "rclone" "$remote_name" "gdrive" "configured"
    else
        log_error "Eroare la configurarea remote-ului Google Drive"
        return 1
    fi
}

# Configurare rclone pentru Dropbox
configure_rclone_dropbox() {
    local remote_name="$1"
    
    log_info "Configurare rclone pentru Dropbox..." "blue"
    echo "ATENȚIE: Configurarea Dropbox necesită browser pentru autentificare."
    
    read -p "Continuați? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    rclone config create "$remote_name" dropbox
    
    if [[ $? -eq 0 ]]; then
        log_info "Remote Dropbox '$remote_name' configurat cu succes" "green"
        save_cloud_config "rclone" "$remote_name" "dropbox" "configured"
    else
        log_error "Eroare la configurarea remote-ului Dropbox"
        return 1
    fi
}

# Configurare rclone pentru OneDrive
configure_rclone_onedrive() {
    local remote_name="$1"
    
    log_info "Configurare rclone pentru OneDrive..." "blue"
    echo "ATENȚIE: Configurarea OneDrive necesită browser pentru autentificare."
    
    read -p "Continuați? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    rclone config create "$remote_name" onedrive
    
    if [[ $? -eq 0 ]]; then
        log_info "Remote OneDrive '$remote_name' configurat cu succes" "green"
        save_cloud_config "rclone" "$remote_name" "onedrive" "configured"
    else
        log_error "Eroare la configurarea remote-ului OneDrive"
        return 1
    fi
}

# Configurare rclone pentru FTP
configure_rclone_ftp() {
    local remote_name="$1"
    local config_params="$2"
    
    log_info "Configurare rclone pentru FTP..." "blue"
    
    read -p "Host FTP: " -r ftp_host
    read -p "User FTP: " -r ftp_user
    read -p "Port FTP (default: 21): " -r ftp_port
    ftp_port=${ftp_port:-21}
    read -s -p "Password FTP: " ftp_pass
    echo
    
    rclone config create "$remote_name" ftp \
        host "$ftp_host" \
        user "$ftp_user" \
        port "$ftp_port" \
        pass "$(rclone obscure "$ftp_pass")"
    
    if [[ $? -eq 0 ]]; then
        log_info "Remote FTP '$remote_name' configurat cu succes" "green"
        save_cloud_config "rclone" "$remote_name" "ftp" "configured"
    else
        log_error "Eroare la configurarea remote-ului FTP"
        return 1
    fi
}

# Configurare rclone pentru SFTP
configure_rclone_sftp() {
    local remote_name="$1"
    local config_params="$2"
    
    log_info "Configurare rclone pentru SFTP..." "blue"
    
    read -p "Host SFTP: " -r sftp_host
    read -p "User SFTP: " -r sftp_user
    read -p "Port SFTP (default: 22): " -r sftp_port
    sftp_port=${sftp_port:-22}
    read -s -p "Password SFTP: " sftp_pass
    echo
    
    rclone config create "$remote_name" sftp \
        host "$sftp_host" \
        user "$sftp_user" \
        port "$sftp_port" \
        pass "$(rclone obscure "$sftp_pass")"
    
    if [[ $? -eq 0 ]]; then
        log_info "Remote SFTP '$remote_name' configurat cu succes" "green"
        save_cloud_config "rclone" "$remote_name" "sftp" "configured"
    else
        log_error "Eroare la configurarea remote-ului SFTP"
        return 1
    fi
}

# Sincronizare cu rclone
sync_with_rclone() {
    local local_path="$1"
    local remote_name="$2"
    local remote_path="$3"
    local sync_type="${4:-sync}" # sync, copy, move
    
    if [[ -z "$local_path" || -z "$remote_name" || -z "$remote_path" ]]; then
        log_error "Parametri necesari: local_path, remote_name, remote_path"
        return 1
    fi
    
    # Verifică dacă remote-ul există
    if ! rclone listremotes | grep -q "^${remote_name}:$"; then
        log_error "Remote-ul '$remote_name' nu este configurat"
        return 1
    fi
    
    log_info "Sincronizare $sync_type: $local_path -> $remote_name:$remote_path" "cyan"
    
    # Configurări pentru sincronizare
    local rclone_flags=(
        "--progress"
        "--stats=1s"
        "--transfers=4"
        "--checkers=8"
        "--retries=3"
    )
    
    # Opțiuni pentru sincronizare sigură
    if [[ "$sync_type" == "sync" ]]; then
        rclone_flags+=(
            "--backup-dir=${remote_name}:/.trash/$(date +%Y%m%d_%H%M%S)"
            "--suffix=.backup"
        )
    fi
    
    case "$sync_type" in
        "sync")
            rclone sync "$local_path" "$remote_name:$remote_path" "${rclone_flags[@]}"
            ;;
        "copy")
            rclone copy "$local_path" "$remote_name:$remote_path" "${rclone_flags[@]}"
            ;;
        "move")
            rclone move "$local_path" "$remote_name:$remote_path" "${rclone_flags[@]}"
            ;;
        *)
            log_error "Tip sincronizare necunoscut: $sync_type"
            return 1
            ;;
    esac
    
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        log_info "Sincronizare completă cu succes" "green"
        
        # Log sincronizare
        echo "$(date '+%Y-%m-%d %H:%M:%S'): $sync_type $local_path -> $remote_name:$remote_path SUCCESS" >> "$CLOUD_LOG"
    else
        log_error "Eroare la sincronizare (cod: $result)"
        echo "$(date '+%Y-%m-%d %H:%M:%S'): $sync_type $local_path -> $remote_name:$remote_path FAILED" >> "$CLOUD_LOG"
    fi
    
    return $result
}

# Backup cu rclone
backup_with_rclone() {
    local backup_source="$1"
    local remote_name="$2"
    local backup_path="${3:-backups/$(hostname)/$(date +%Y%m%d_%H%M%S)}"
    
    log_info "Backup cu rclone: $backup_source -> $remote_name:$backup_path" "cyan"
    
    if [[ ! -e "$backup_source" ]]; then
        log_error "Sursa de backup nu există: $backup_source"
        return 1
    fi
    
    # Creează arhiva dacă este director
    local temp_archive=""
    if [[ -d "$backup_source" ]]; then
        temp_archive="/tmp/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        log_info "Creez arhiva: $temp_archive" "blue"
        
        tar -czf "$temp_archive" -C "$(dirname "$backup_source")" "$(basename "$backup_source")"
        backup_source="$temp_archive"
    fi
    
    # Upload cu rclone
    if rclone copy "$backup_source" "$remote_name:$backup_path" --progress; then
        log_info "Backup uplodat cu succes" "green"
        
        # Curățare arhivă temporară
        [[ -n "$temp_archive" && -f "$temp_archive" ]] && rm -f "$temp_archive"
        
        # Salvează informații backup
        save_cloud_config "rclone_backup" "$remote_name" "$backup_path" "$(date)"
        
        return 0
    else
        log_error "Eroare la upload backup"
        [[ -n "$temp_archive" && -f "$temp_archive" ]] && rm -f "$temp_archive"
        return 1
    fi
}

# Listează remote-uri rclone
list_rclone_remotes() {
    log_info "Remote-uri rclone configurate:" "cyan"
    
    if ! command -v rclone >/dev/null 2>&1; then
        log_warning "Rclone nu este instalat"
        return 1
    fi
    
    local remotes
    remotes=$(rclone listremotes)
    
    if [[ -z "$remotes" ]]; then
        log_info "Nu sunt remote-uri configurate" "yellow"
        return 0
    fi
    
    echo
    echo "Remote-uri disponibile:"
    while IFS= read -r remote; do
        if [[ -n "$remote" ]]; then
            remote_name=${remote%:}
            echo "  • $remote_name"
            
            # Încearcă să obțină informații despre remote
            local info
            info=$(rclone config show "$remote_name" 2>/dev/null | grep "type" | cut -d'=' -f2 | tr -d ' ')
            [[ -n "$info" ]] && echo "    Tip: $info"
        fi
    done <<< "$remotes"
    echo
}

# Test conectivitate rclone
test_rclone_remote() {
    local remote_name="$1"
    
    if [[ -z "$remote_name" ]]; then
        log_error "Nume remote necesar"
        return 1
    fi
    
    log_info "Test conectivitate pentru remote: $remote_name" "cyan"
    
    # Test simplu de listare
    if rclone lsd "$remote_name:" --max-depth 1 >/dev/null 2>&1; then
        log_info "Conectivitate OK pentru $remote_name" "green"
        return 0
    else
        log_error "Eroare de conectivitate pentru $remote_name"
        return 1
    fi
}

# =============================================================================
# INTEGRARE CU MENIUL PRINCIPAL
# =============================================================================

# Adaugă rclone în meniul principal cloud
integrate_rclone_menu() {
    log_info "Integrare rclone în meniul principal..." "cyan"
    
    # Adaugă rclone ca opțiune în meniul cloud principal
    # Această funcție va fi apelată din main()
    echo "8. 🗄️ Rclone Management" # Va fi adăugat în show_cloud_menu()
}

# =============================================================================
# FUNCȚII DE EXPORT PENTRU TESTE
# =============================================================================

# Export funcții pentru testing
export_rclone_functions() {
    echo "install_rclone"
    echo "configure_rclone_remote"
    echo "sync_with_rclone"
    echo "backup_with_rclone"
    echo "list_rclone_remotes"
    echo "test_rclone_remote"
    echo "validate_rclone_configs"
    echo "create_rclone_backup_job"
    echo "monitor_cloud_storage"
    echo "cleanup_old_backups"
    echo "show_rclone_menu"
}

# =============================================================================
# SELF-TEST PENTRU RCLONE
# =============================================================================

# Test rapid rclone
test_rclone_functionality() {
    log_info "Test funcționalitate rclone..." "cyan"
    
    # Test 1: Verifică instalarea
    if command -v rclone >/dev/null 2>&1; then
        log_info "✅ Rclone este instalat" "green"
        local version
        version=$(rclone version | head -1)
        log_info "Versiune: $version" "blue"
    else
        log_warning "⚠️ Rclone nu este instalat" "yellow"
        return 1
    fi
    
    # Test 2: Verifică configurațiile
    local remotes
    remotes=$(rclone listremotes 2>/dev/null)
    
    if [[ -n "$remotes" ]]; then
        log_info "✅ Remote-uri configurate:" "green"
        echo "$remotes" | while read -r remote; do
            [[ -n "$remote" ]] && echo "  • ${remote%:}"
        done
    else
        log_info "ℹ️ Nu sunt remote-uri configurate" "blue"
    fi
    
    # Test 3: Verifică structura de directoare
    if [[ -d "$CLOUD_CONFIG_DIR" ]]; then
        log_info "✅ Directoare cloud configurate" "green"
    else
        log_warning "⚠️ Directoare cloud nu sunt configurate" "yellow"
    fi
    
    return 0
}

# Auto-run test dacă scriptul este executat direct
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "🧪 Test automat rclone functionality..."
    test_rclone_functionality
fi

# Validează configurațiile rclone
validate_rclone_configs() {
    log_info "Validare configurații rclone..." "cyan"
    
    if ! command -v rclone >/dev/null 2>&1; then
        log_error "Rclone nu este instalat"
        return 1
    fi
    
    local remotes
    remotes=$(rclone listremotes)
    
    if [[ -z "$remotes" ]]; then
        log_warning "Nu sunt remote-uri configurate"
        return 0
    fi
    
    local failed_remotes=()
    local successful_remotes=()
    
    echo
    log_info "Testing remote configurations..." "blue"
    
    while IFS= read -r remote; do
        if [[ -n "$remote" ]]; then
            remote_name=${remote%:}
            echo -n "  Testing $remote_name: "
            
            if timeout 30 rclone lsd "$remote:" --max-depth 1 >/dev/null 2>&1; then
                echo "✅ OK"
                successful_remotes+=("$remote_name")
            else
                echo "❌ FAILED"
                failed_remotes+=("$remote_name")
            fi
        fi
    done <<< "$remotes"
    
    echo
    if [[ ${#successful_remotes[@]} -gt 0 ]]; then
        log_info "Remote-uri funcționale: ${successful_remotes[*]}" "green"
    fi
    
    if [[ ${#failed_remotes[@]} -gt 0 ]]; then
        log_warning "Remote-uri cu probleme: ${failed_remotes[*]}" "yellow"
        return 1
    fi
    
    log_info "Toate remote-urile sunt funcționale" "green"
    return 0
}

# Creează job de backup automat
create_rclone_backup_job() {
    local job_name="$1"
    local source_path="$2"
    local remote_name="$3"
    local remote_path="$4"
    local schedule="$5"  # daily, weekly, monthly
    
    if [[ -z "$job_name" || -z "$source_path" || -z "$remote_name" || -z "$remote_path" ]]; then
        log_error "Parametri necesari: job_name, source_path, remote_name, remote_path"
        return 1
    fi
    
    log_info "Creare job backup automat: $job_name" "cyan"
    
    # Creează directorul pentru job-uri
    local jobs_dir="$CLOUD_CONFIG_DIR/backup_jobs"
    mkdir -p "$jobs_dir"
    
    # Creează script pentru job
    local job_script="$jobs_dir/${job_name}.sh"
    
    cat > "$job_script" << EOF
#!/bin/bash
# Backup job auto-generat: $job_name
# Creat: $(date)

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
CLOUD_DIR="\$(dirname "\$(dirname "\$SCRIPT_DIR")")"

# Import dependencies
source "\$CLOUD_DIR/cloud_integration_manager.sh"

# Configurare logging
LOG_FILE="\$CLOUD_DIR/logs/backup_\${job_name}_\$(date +%Y%m%d).log"
mkdir -p "\$(dirname "\$LOG_FILE")"

# Funcție de logging pentru job
job_log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') [\$1] \$2" | tee -a "\$LOG_FILE"
}

# Execută backup
job_log "INFO" "Începe backup job: $job_name"

if backup_with_rclone "$source_path" "$remote_name" "$remote_path"; then
    job_log "SUCCESS" "Backup complet cu succes"
    exit 0
else
    job_log "ERROR" "Backup eșuat"
    exit 1
fi
EOF
    
    chmod +x "$job_script"
    
    # Salvează configurația job-ului
    local job_config="$jobs_dir/${job_name}.conf"
    cat > "$job_config" << EOF
JOB_NAME="$job_name"
SOURCE_PATH="$source_path"
REMOTE_NAME="$remote_name"
REMOTE_PATH="$remote_path"
SCHEDULE="$schedule"
CREATED="$(date)"
SCRIPT_PATH="$job_script"
EOF
    
    log_info "Job de backup '$job_name' creat cu succes" "green"
    return 0
}

# Monitorizare spațiu cloud storage
monitor_cloud_storage() {
    local remote_name="$1"
    
    if [[ -z "$remote_name" ]]; then
        log_error "Nume remote necesar"
        return 1
    fi
    
    log_info "Monitorizare spațiu storage pentru: $remote_name" "cyan"
    
    # Verifică dacă remote-ul suportă informații despre spațiu
    if rclone about "$remote_name:" >/dev/null 2>&1; then
        echo
        echo "=== INFORMAȚII STORAGE ==="
        rclone about "$remote_name:" | while read -r line; do
            echo "  $line"
        done
        echo
    else
        log_warning "Remote-ul $remote_name nu suportă informații despre spațiu"
    fi
    
    # Statistici generale
    echo "=== STATISTICI FIȘIERE ==="
    echo -n "  Calculez statistici... "
    
    local temp_file
    temp_file=$(mktemp)
    
    if timeout 60 rclone size "$remote_name:" > "$temp_file" 2>/dev/null; then
        echo "✅"
        cat "$temp_file" | while read -r line; do
            echo "  $line"
        done
    else
        echo "❌ (timeout sau eroare)"
    fi
    
    rm -f "$temp_file"
    echo
}

# Meniu interactiv rclone
show_rclone_menu() {
    while true; do
        clear
        echo "=== RCLONE MANAGEMENT ==="
        echo "1.  📦 Instalare rclone"
        echo "2.  🔧 Configurare remote nou"
        echo "3.  📋 Listare remote-uri"
        echo "4.  🔍 Test conectivitate"
        echo "5.  ✅ Validare configurații"
        echo "6.  🔄 Sincronizare fișiere"
        echo "7.  💾 Backup cu rclone"
        echo "8.  ⏰ Configurare backup automat"
        echo "9.  📈 Monitorizare storage"
        echo "10. ↩️  Înapoi"
        echo
        
        read -p "Selectați opțiunea (1-10): " choice
        
        case "$choice" in
            1)
                install_rclone
                read -p "Apăsați Enter pentru a continua..."
                ;;
            2)
                echo
                read -p "Nume remote: " remote_name
                echo "Provideri disponibili: s3, dropbox, gdrive, onedrive, ftp, sftp"
                read -p "Provider: " provider
                configure_rclone_remote "$remote_name" "$provider"
                read -p "Apăsați Enter pentru a continua..."
                ;;
            3)
                list_rclone_remotes
                read -p "Apăsați Enter pentru a continua..."
                ;;
            4)
                echo
                read -p "Nume remote pentru test: " remote_name
                test_rclone_remote "$remote_name"
                read -p "Apăsați Enter pentru a continua..."
                ;;
            5)
                validate_rclone_configs
                read -p "Apăsați Enter pentru a continua..."
                ;;
            6)
                echo
                read -p "Cale locală: " local_path
                read -p "Nume remote: " remote_name  
                read -p "Cale remote: " remote_path
                echo "Tipuri: sync, copy, move"
                read -p "Tip sincronizare (default: sync): " sync_type
                sync_type=${sync_type:-sync}
                sync_with_rclone "$local_path" "$remote_name" "$remote_path" "$sync_type"
                read -p "Apăsați Enter pentru a continua..."
                ;;
            7)
                echo
                read -p "Sursa de backup: " backup_source
                read -p "Remote pentru backup: " remote_name
                read -p "Cale backup (opțional): " backup_path
                backup_with_rclone "$backup_source" "$remote_name" "$backup_path"
                read -p "Apăsați Enter pentru a continua..."
                ;;
            8)
                echo
                read -p "Nume job: " job_name
                read -p "Cale sursă: " source_path
                read -p "Remote name: " remote_name
                read -p "Remote path: " remote_path
                echo "Schedule: daily, weekly, monthly"
                read -p "Schedule (opțional): " schedule
                create_rclone_backup_job "$job_name" "$source_path" "$remote_name" "$remote_path" "$schedule"
                read -p "Apăsați Enter pentru a continua..."
                ;;
            9)
                echo
                read -p "Remote pentru monitorizare: " remote_name
                monitor_cloud_storage "$remote_name"
                read -p "Apăsați Enter pentru a continua..."
                ;;
            10)
                break
                ;;
            *)
                echo "Opțiune invalidă!"
                sleep 1
                ;;
        esac
    done
}

# =============================================================================
# SFÂRȘIT RCLONE MANAGER
# =============================================================================
