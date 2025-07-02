#!/bin/bash
#
# aws_deployment.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - AWS Integration Scripts
# =============================================================================
# Descriere: Scripturi pentru deployment și management AWS
# =============================================================================

# Configurare paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUD_DIR="$(dirname "$SCRIPT_DIR")"
HELPERS_DIR="$(dirname "$(dirname "$CLOUD_DIR")")/helpers"
UTILS_DIR="$HELPERS_DIR/utils"

# Import dependencies
source "$UTILS_DIR/ui_manager.sh" 2>/dev/null || { echo "❌ Nu găsesc ui_manager.sh"; exit 1; }

# =============================================================================
# AWS DEPLOYMENT FUNCTIONS
# =============================================================================

# Deploy WordPress pe AWS
deploy_wordpress_aws() {
    local environment="$1"
    [[ -z "$environment" ]] && environment="production"
    
    ui_header "🚀 AWS WordPress Deployment - $environment"
    
    # Configurări pentru environment
    case "$environment" in
        "production")
            local instance_type="t3.medium"
            local db_instance_class="db.t3.micro"
            local multi_az="true"
            ;;
        "staging")
            local instance_type="t3.small"
            local db_instance_class="db.t3.micro"
            local multi_az="false"
            ;;
        "development")
            local instance_type="t3.micro"
            local db_instance_class="db.t3.micro"
            local multi_az="false"
            ;;
    esac
    
    ui_info "📋 Configurare deployment:"
    echo "  Environment: $environment"
    echo "  Instance Type: $instance_type"
    echo "  DB Instance: $db_instance_class"
    echo "  Multi-AZ: $multi_az"
    echo
    
    # Creare VPC și subnets
    create_aws_vpc "$environment"
    
    # Creare Security Groups
    create_aws_security_groups "$environment"
    
    # Creare RDS Database
    create_aws_rds_instance "$environment" "$db_instance_class" "$multi_az"
    
    # Creare EC2 Instance
    create_aws_ec2_instance "$environment" "$instance_type"
    
    # Configurare Load Balancer (pentru production)
    if [[ "$environment" == "production" ]]; then
        create_aws_load_balancer "$environment"
    fi
    
    # Setup CloudFront CDN
    create_aws_cloudfront_distribution "$environment"
    
    ui_success "✅ Deployment AWS WordPress completat pentru $environment"
}

# Creare VPC
create_aws_vpc() {
    local environment="$1"
    local vpc_name="lomp-vpc-$environment"
    
    ui_info "🌐 Creare VPC: $vpc_name"
    
    # Creare VPC
    local vpc_id
    vpc_id=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/16 \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$vpc_name},{Key=Environment,Value=$environment}]" \
        --query 'Vpc.VpcId' \
        --output text)
    
    if [[ -n "$vpc_id" ]]; then
        ui_success "VPC creat: $vpc_id"
        
        # Enable DNS hostname
        aws ec2 modify-vpc-attribute --vpc-id "$vpc_id" --enable-dns-hostnames
        
        # Creare Internet Gateway
        local igw_id
        igw_id=$(aws ec2 create-internet-gateway \
            --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$vpc_name-igw}]" \
            --query 'InternetGateway.InternetGatewayId' \
            --output text)
        
        # Attach Internet Gateway
        aws ec2 attach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id"
        
        # Creare subnets publice și private
        create_aws_subnets "$vpc_id" "$environment"
        
        # Salvare VPC ID pentru folosire ulterioară
        echo "$vpc_id" > "/tmp/lomp-vpc-$environment.id"
    else
        ui_error "Eroare la crearea VPC"
        return 1
    fi
}

# Creare subnets
create_aws_subnets() {
    local vpc_id="$1"
    local environment="$2"
    
    ui_info "🏗️ Creare subnets pentru VPC $vpc_id"
    
    # Subnet public
    local public_subnet_id
    public_subnet_id=$(aws ec2 create-subnet \
        --vpc-id "$vpc_id" \
        --cidr-block 10.0.1.0/24 \
        --availability-zone "$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=lomp-public-$environment},{Key=Type,Value=Public}]" \
        --query 'Subnet.SubnetId' \
        --output text)
    
    # Subnet privat
    local private_subnet_id
    private_subnet_id=$(aws ec2 create-subnet \
        --vpc-id "$vpc_id" \
        --cidr-block 10.0.2.0/24 \
        --availability-zone "$(aws ec2 describe-availability-zones --query 'AvailabilityZones[1].ZoneName' --output text)" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=lomp-private-$environment},{Key=Type,Value=Private}]" \
        --query 'Subnet.SubnetId' \
        --output text)
    
    # Enable auto-assign public IP pentru subnet public
    aws ec2 modify-subnet-attribute --subnet-id "$public_subnet_id" --map-public-ip-on-launch
    
    # Salvare subnet IDs
    echo "$public_subnet_id" > "/tmp/lomp-public-subnet-$environment.id"
    echo "$private_subnet_id" > "/tmp/lomp-private-subnet-$environment.id"
    
    ui_success "Subnets create: Public($public_subnet_id), Private($private_subnet_id)"
}

# Creare Security Groups
create_aws_security_groups() {
    local environment="$1"
    local vpc_id
    vpc_id=$(cat "/tmp/lomp-vpc-$environment.id")
    
    ui_info "🔒 Creare Security Groups"
    
    # Web Security Group
    local web_sg_id
    web_sg_id=$(aws ec2 create-security-group \
        --group-name "lomp-web-$environment" \
        --description "LOMP Web Server Security Group - $environment" \
        --vpc-id "$vpc_id" \
        --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=lomp-web-$environment}]" \
        --query 'GroupId' \
        --output text)
    
    # Database Security Group
    local db_sg_id
    db_sg_id=$(aws ec2 create-security-group \
        --group-name "lomp-db-$environment" \
        --description "LOMP Database Security Group - $environment" \
        --vpc-id "$vpc_id" \
        --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=lomp-db-$environment}]" \
        --query 'GroupId' \
        --output text)
    
    # Reguli pentru Web SG
    aws ec2 authorize-security-group-ingress --group-id "$web_sg_id" --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id "$web_sg_id" --protocol tcp --port 443 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id "$web_sg_id" --protocol tcp --port 22 --cidr 0.0.0.0/0
    
    # Reguli pentru DB SG (acces doar din Web SG)
    aws ec2 authorize-security-group-ingress --group-id "$db_sg_id" --protocol tcp --port 3306 --source-group "$web_sg_id"
    
    # Salvare Security Group IDs
    echo "$web_sg_id" > "/tmp/lomp-web-sg-$environment.id"
    echo "$db_sg_id" > "/tmp/lomp-db-sg-$environment.id"
    
    ui_success "Security Groups create: Web($web_sg_id), DB($db_sg_id)"
}

# Creare RDS Instance
create_aws_rds_instance() {
    local environment="$1"
    local db_instance_class="$2"
    local multi_az="$3"
    
    ui_info "🗄️ Creare RDS Database Instance"
    
    local db_sg_id
    db_sg_id=$(cat "/tmp/lomp-db-sg-$environment.id")
    
    local private_subnet_id
    private_subnet_id=$(cat "/tmp/lomp-private-subnet-$environment.id")
    
    # Creare DB Subnet Group
    local vpc_id
    vpc_id=$(cat "/tmp/lomp-vpc-$environment.id")
    
    # Obține toate subnet-urile private din VPC (necesare pentru subnet group)
    local all_subnets
    all_subnets=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Type,Values=Private" \
        --query 'Subnets[].SubnetId' \
        --output text)
    
    if [[ -z "$all_subnets" ]]; then
        all_subnets="$private_subnet_id"
    fi
    
    aws rds create-db-subnet-group \
        --db-subnet-group-name "lomp-db-subnet-group-$environment" \
        --db-subnet-group-description "LOMP DB Subnet Group - $environment" \
        --subnet-ids $all_subnets \
        --tags Key=Name,Value="lomp-db-subnet-group-$environment" Key=Environment,Value="$environment"
    
    # Creare RDS Instance
    local db_identifier="lomp-db-$environment"
    aws rds create-db-instance \
        --db-instance-identifier "$db_identifier" \
        --db-instance-class "$db_instance_class" \
        --engine mysql \
        --engine-version "8.0" \
        --master-username admin \
        --master-user-password "LompStack2024!" \
        --allocated-storage 20 \
        --vpc-security-group-ids "$db_sg_id" \
        --db-subnet-group-name "lomp-db-subnet-group-$environment" \
        --multi-az "$multi_az" \
        --storage-encrypted \
        --backup-retention-period 7 \
        --tags Key=Name,Value="$db_identifier" Key=Environment,Value="$environment"
    
    ui_success "RDS Instance creat: $db_identifier"
    echo "$db_identifier" > "/tmp/lomp-db-$environment.id"
}

# Creare EC2 Instance
create_aws_ec2_instance() {
    local environment="$1"
    local instance_type="$2"
    
    ui_info "💻 Creare EC2 Instance"
    
    local public_subnet_id
    public_subnet_id=$(cat "/tmp/lomp-public-subnet-$environment.id")
    
    local web_sg_id
    web_sg_id=$(cat "/tmp/lomp-web-sg-$environment.id")
    
    # Obține cel mai recent AMI Ubuntu
    local ami_id
    ami_id=$(aws ec2 describe-images \
        --owners 099720109477 \
        --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \
        --query 'Images|sort_by(@, &CreationDate)[-1].ImageId' \
        --output text)
    
    # Creare User Data script pentru configurarea automată
    create_user_data_script "$environment" > "/tmp/user-data-$environment.sh"
    
    # Launch EC2 Instance
    local instance_id
    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --count 1 \
        --instance-type "$instance_type" \
        --subnet-id "$public_subnet_id" \
        --security-group-ids "$web_sg_id" \
        --user-data "file:///tmp/user-data-$environment.sh" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=lomp-web-$environment},{Key=Environment,Value=$environment}]" \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    if [[ -n "$instance_id" ]]; then
        ui_success "EC2 Instance creat: $instance_id"
        echo "$instance_id" > "/tmp/lomp-ec2-$environment.id"
        
        # Așteaptă ca instanța să fie running
        ui_info "⏳ Aștept ca instanța să fie disponibilă..."
        aws ec2 wait instance-running --instance-ids "$instance_id"
        
        # Obține IP-ul public
        local public_ip
        public_ip=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        
        ui_success "✅ Instanța este disponibilă la IP: $public_ip"
        echo "$public_ip" > "/tmp/lomp-ip-$environment.txt"
    else
        ui_error "Eroare la crearea instanței EC2"
        return 1
    fi
}

# Creare User Data Script
create_user_data_script() {
    local environment="$1"
    
    cat << 'EOF'
#!/bin/bash
# LOMP Stack Auto-Installation Script
export DEBIAN_FRONTEND=noninteractive

# Update system
apt-get update -y
apt-get upgrade -y

# Install basic packages
apt-get install -y wget curl git unzip

# Download and install LOMP Stack
cd /opt
git clone https://github.com/your-repo/lomp-stack.git || echo "Using local LOMP installation"

# Install LOMP Stack dependencies
if [[ -f "/opt/lomp-stack/install.sh" ]]; then
    chmod +x /opt/lomp-stack/install.sh
    bash /opt/lomp-stack/install.sh --auto --cloud-mode
fi

# Configure automatic updates
cat > /etc/cron.daily/lomp-update << 'EOCRON'
#!/bin/bash
cd /opt/lomp-stack
git pull origin main
chmod +x install.sh
bash install.sh --update --quiet
EOCRON
chmod +x /etc/cron.daily/lomp-update

# Setup CloudWatch agent (optional)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

echo "LOMP Stack installation completed" > /var/log/lomp-install.log
EOF
}

# =============================================================================
# AWS MONITORING FUNCTIONS
# =============================================================================

# Monitorizare resurse AWS
monitor_aws_resources() {
    ui_header "📊 AWS Resources Monitoring"
    
    echo "🖥️ EC2 Instances:"
    aws ec2 describe-instances \
        --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
        --output table
    
    echo
    echo "🗄️ RDS Instances:"
    aws rds describe-db-instances \
        --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,DBInstanceClass,Endpoint.Address]' \
        --output table
    
    echo
    echo "📦 S3 Buckets:"
    aws s3 ls
    
    echo
    echo "🌐 CloudFront Distributions:"
    aws cloudfront list-distributions \
        --query 'DistributionList.Items[*].[Id,Status,DomainName,Comment]' \
        --output table 2>/dev/null || echo "No CloudFront distributions found"
}

# =============================================================================
# AWS CLEANUP FUNCTIONS
# =============================================================================

# Cleanup resurse AWS pentru un environment
cleanup_aws_environment() {
    local environment="$1"
    
    ui_header "🧹 Cleanup AWS Resources - $environment"
    ui_warning "⚠️ Această operație va șterge TOATE resursele pentru environment-ul $environment"
    
    read -rp "Ești sigur că vrei să continui? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        ui_info "Operație anulată"
        return 0
    fi
    
    # Terminare EC2 instances
    if [[ -f "/tmp/lomp-ec2-$environment.id" ]]; then
        local instance_id
        instance_id=$(cat "/tmp/lomp-ec2-$environment.id")
        ui_info "🗑️ Terminare EC2 instance: $instance_id"
        aws ec2 terminate-instances --instance-ids "$instance_id"
        aws ec2 wait instance-terminated --instance-ids "$instance_id"
    fi
    
    # Ștergere RDS instance
    if [[ -f "/tmp/lomp-db-$environment.id" ]]; then
        local db_identifier
        db_identifier=$(cat "/tmp/lomp-db-$environment.id")
        ui_info "🗑️ Ștergere RDS instance: $db_identifier"
        aws rds delete-db-instance \
            --db-instance-identifier "$db_identifier" \
            --skip-final-snapshot \
            --delete-automated-backups
    fi
    
    # Cleanup files
    rm -f "/tmp/lomp-"*"-$environment."*
    
    ui_success "✅ Cleanup completat pentru environment $environment"
}

# Rulează funcția dacă scriptul este apelat direct
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "deploy-wordpress")
            deploy_wordpress_aws "${2:-production}"
            ;;
        "monitor")
            monitor_aws_resources
            ;;
        "cleanup")
            cleanup_aws_environment "${2:-development}"
            ;;
        *)
            echo "Usage: $0 {deploy-wordpress|monitor|cleanup} [environment]"
            exit 1
            ;;
    esac
fi
