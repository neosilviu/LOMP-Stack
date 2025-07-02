#!/bin/bash
#
# multisite_manager.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Multi-Site Manager
# Centralized management for multiple WordPress sites
# 
# Features:
# - Centralized site creation, management, and monitoring
# - Bulk operations across multiple sites
# - Site templates and cloning
# - Resource allocation and optimization
# - Cross-site backup and synchronization
# - Performance analytics across all sites
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

# Define print functions using color_echo
print_info() { color_echo cyan "[MULTISITE-INFO] $*"; }
print_success() { color_echo green "[MULTISITE-SUCCESS] $*"; }
print_warning() { color_echo yellow "[MULTISITE-WARNING] $*"; }
print_error() { color_echo red "[MULTISITE-ERROR] $*"; }

# Multi-site configuration
MULTISITE_CONFIG="${SCRIPT_DIR}/multisite_config.json"
MULTISITE_LOG="${SCRIPT_DIR}/../tmp/multisite_manager.log"
SITES_DATABASE="${SCRIPT_DIR}/sites_database.json"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

#########################################################################
# Logging Function
#########################################################################
log_multisite() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$MULTISITE_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize Multi-Site Configuration
#########################################################################
init_multisite_config() {
    log_multisite "INFO" "Initializing Multi-Site Manager configuration..."
    
    # Create main configuration
    cat > "$MULTISITE_CONFIG" << 'EOF'
{
    "multisite": {
        "version": "1.0.0",
        "max_sites": 100,
        "default_php_version": "8.2",
        "default_resources": {
            "cpu_limit": "1",
            "memory_limit": "512M",
            "disk_quota": "5G"
        },
        "backup_settings": {
            "auto_backup": true,
            "backup_frequency": "daily",
            "retention_days": 30,
            "cross_site_sync": false
        },
        "monitoring": {
            "health_check_interval": 300,
            "performance_tracking": true,
            "uptime_monitoring": true,
            "ssl_monitoring": true
        }
    },
    "templates": {
        "wordpress_basic": {
            "name": "WordPress Basic",
            "description": "Standard WordPress installation",
            "plugins": ["akismet", "jetpack"],
            "theme": "twentytwentyfour",
            "settings": {
                "admin_email": "admin@example.com",
                "timezone": "UTC",
                "date_format": "Y-m-d"
            }
        },
        "wordpress_ecommerce": {
            "name": "WordPress E-commerce",
            "description": "WordPress with WooCommerce",
            "plugins": ["woocommerce", "woocommerce-payments", "jetpack"],
            "theme": "storefront",
            "settings": {
                "admin_email": "admin@example.com",
                "timezone": "UTC",
                "currency": "USD"
            }
        },
        "wordpress_blog": {
            "name": "WordPress Blog",
            "description": "Optimized for blogging",
            "plugins": ["yoast-seo", "wp-super-cache", "jetpack"],
            "theme": "twentytwentyfour",
            "settings": {
                "admin_email": "admin@example.com",
                "timezone": "UTC",
                "posts_per_page": 10
            }
        }
    },
    "resource_limits": {
        "small": {
            "cpu": "0.5",
            "memory": "256M",
            "disk": "2G",
            "bandwidth": "10G"
        },
        "medium": {
            "cpu": "1",
            "memory": "512M",
            "disk": "5G",
            "bandwidth": "50G"
        },
        "large": {
            "cpu": "2",
            "memory": "1G",
            "disk": "10G",
            "bandwidth": "100G"
        },
        "enterprise": {
            "cpu": "4",
            "memory": "2G",
            "disk": "20G",
            "bandwidth": "unlimited"
        }
    }
}
EOF
    
    log_multisite "SUCCESS" "Multi-Site configuration initialized"
}

#########################################################################
# Initialize Sites Database
#########################################################################
init_sites_database() {
    log_multisite "INFO" "Initializing sites database..."
    
    cat > "$SITES_DATABASE" << 'EOF'
{
    "sites": [],
    "total_sites": 0,
    "active_sites": 0,
    "last_updated": "2025-07-01T00:00:00Z"
}
EOF
    
    log_multisite "SUCCESS" "Sites database initialized"
}

#########################################################################
# Create Site Templates Directory
#########################################################################
create_templates_dir() {
    log_multisite "INFO" "Creating templates directory..."
    
    mkdir -p "$TEMPLATES_DIR"
    
    # Create basic template structure
    mkdir -p "$TEMPLATES_DIR/wordpress_basic"
    mkdir -p "$TEMPLATES_DIR/wordpress_ecommerce" 
    mkdir -p "$TEMPLATES_DIR/wordpress_blog"
    
    # Create template configuration files
    cat > "$TEMPLATES_DIR/wordpress_basic/template.json" << 'EOF'
{
    "name": "WordPress Basic",
    "version": "1.0.0",
    "description": "Standard WordPress installation with essential plugins",
    "wordpress_version": "latest",
    "php_version": "8.2",
    "plugins": [
        {
            "name": "akismet",
            "version": "latest",
            "required": true
        },
        {
            "name": "jetpack",
            "version": "latest",
            "required": false
        }
    ],
    "theme": {
        "name": "twentytwentyfour",
        "version": "latest"
    },
    "settings": {
        "admin_email": "admin@example.com",
        "site_title": "My WordPress Site",
        "tagline": "Just another WordPress site",
        "timezone": "UTC",
        "date_format": "Y-m-d",
        "time_format": "H:i"
    },
    "resources": {
        "plan": "medium",
        "ssl": true,
        "cdn": false
    }
}
EOF
    
    log_multisite "SUCCESS" "Templates directory created"
}

#########################################################################
# List All Sites
#########################################################################
list_all_sites() {
    log_multisite "INFO" "Listing all managed sites..."
    
    if [ ! -f "$SITES_DATABASE" ]; then
        print_warning "Sites database not found. Initializing..."
        init_sites_database
    fi
    
    local total_sites
    total_sites=$(jq '.total_sites' "$SITES_DATABASE" 2>/dev/null || echo "0")
    
    print_info "=== Multi-Site Manager - Sites Overview ==="
    print_info "Total Managed Sites: $total_sites"
    echo ""
    
    if [ "$total_sites" -gt 0 ]; then
        print_info "Site Details:"
        echo "┌─────────────────────────────────────────────────────────────────────────┐"
        echo "│ Domain                    │ Status    │ Template      │ Resources     │"
        echo "├─────────────────────────────────────────────────────────────────────────┤"
        
        jq -r '.sites[] | "\(.domain) │ \(.status) │ \(.template) │ \(.resource_plan)"' "$SITES_DATABASE" 2>/dev/null | \
        while IFS= read -r line; do
            echo "│ $line │"
        done
        
        echo "└─────────────────────────────────────────────────────────────────────────┘"
    else
        print_info "No sites currently managed."
        print_info "Use 'Create New Site' to add your first site."
    fi
    
    echo ""
    print_info "Quick Actions:"
    print_info "- Total disk usage: $(du -sh /var/www 2>/dev/null | cut -f1 || echo "N/A")"
    print_info "- Active domains: $(find /var/www -maxdepth 1 -type d -name "*.com" -o -name "*.org" -o -name "*.net" 2>/dev/null | wc -l)"
    print_info "- SSL certificates: $(find /etc/letsencrypt/live -maxdepth 1 -type d 2>/dev/null | wc -l)"
}

#########################################################################
# Create New Site from Template
#########################################################################
create_site_from_template() {
    local domain="$1"
    local template="$2"
    local admin_email="$3"
    local resource_plan="${4:-medium}"
    
    if [ -z "$domain" ] || [ -z "$template" ] || [ -z "$admin_email" ]; then
        print_error "Domain, template, and admin email are required"
        return 1
    fi
    
    log_multisite "INFO" "Creating site $domain from template $template..."
    
    # Check if template exists
    if [ ! -f "$TEMPLATES_DIR/$template/template.json" ]; then
        print_error "Template '$template' not found"
        return 1
    fi
    
    # Check if domain already exists
    if [ -d "/var/www/$domain" ]; then
        print_error "Site $domain already exists"
        return 1
    fi
    
    print_info "Creating site: $domain"
    print_info "Template: $template"
    print_info "Admin email: $admin_email"
    print_info "Resource plan: $resource_plan"
    
    # Create site directory
    sudo mkdir -p "/var/www/$domain"
    sudo chown -R www-data:www-data "/var/www/$domain"
    
    # Download and install WordPress
    cd "/var/www/$domain" || return 1
    sudo -u www-data wp core download --allow-root 2>/dev/null || {
        print_info "Installing WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/gh-pages/wp-cli.phar
        chmod +x wp-cli.phar
        sudo mv wp-cli.phar /usr/local/bin/wp
        sudo -u www-data wp core download --allow-root
    }
    
    # Create WordPress configuration
    local db_name
    db_name="wp_$(echo "$domain" | tr '.-' '_')"
    local db_user="$db_name"
    local db_pass
    db_pass=$(openssl rand -base64 16)
    
    # Create database and user
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\`;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Configure WordPress
    sudo -u www-data wp config create \
        --dbname="$db_name" \
        --dbuser="$db_user" \
        --dbpass="$db_pass" \
        --dbhost="localhost" \
        --allow-root
    
    # Install WordPress
    local site_title
    site_title=$(jq -r '.settings.site_title' "$TEMPLATES_DIR/$template/template.json")
    
    sudo -u www-data wp core install \
        --url="https://$domain" \
        --title="$site_title" \
        --admin_user="admin" \
        --admin_password="$(openssl rand -base64 12)" \
        --admin_email="$admin_email" \
        --allow-root
    
    # Install plugins from template
    local plugins
    plugins=$(jq -r '.plugins[].name' "$TEMPLATES_DIR/$template/template.json")
    for plugin in $plugins; do
        if [ "$plugin" != "null" ]; then
            sudo -u www-data wp plugin install "$plugin" --activate --allow-root
        fi
    done
    
    # Install theme from template
    local theme
    theme=$(jq -r '.theme.name' "$TEMPLATES_DIR/$template/template.json")
    if [ "$theme" != "null" ]; then
        sudo -u www-data wp theme install "$theme" --activate --allow-root
    fi
    
    # Add site to database
    add_site_to_database "$domain" "$template" "$admin_email" "$resource_plan"
    
    # Create virtual host
    create_virtual_host "$domain"
    
    # Request SSL certificate
    request_ssl_certificate "$domain"
    
    log_multisite "SUCCESS" "Site $domain created successfully"
    print_success "Site $domain created successfully!"
    print_info "Access your site at: https://$domain"
    print_info "Admin panel: https://$domain/wp-admin"
}

#########################################################################
# Add Site to Database
#########################################################################
add_site_to_database() {
    local domain="$1"
    local template="$2"
    local admin_email="$3"
    local resource_plan="$4"
    
    local site_data
    site_data=$(cat <<EOF
{
    "domain": "$domain",
    "template": "$template",
    "admin_email": "$admin_email",
    "resource_plan": "$resource_plan",
    "status": "active",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "last_backup": null,
    "ssl_status": "pending",
    "php_version": "8.2",
    "wordpress_version": "latest",
    "disk_usage": "0",
    "monthly_visitors": 0,
    "uptime": "100%"
}
EOF
    )
    
    # Add site to sites array and update totals
    jq --argjson site "$site_data" '
        .sites += [$site] |
        .total_sites = (.sites | length) |
        .active_sites = (.sites | map(select(.status == "active")) | length) |
        .last_updated = now | todate
    ' "$SITES_DATABASE" > "$SITES_DATABASE.tmp" && mv "$SITES_DATABASE.tmp" "$SITES_DATABASE"
}

#########################################################################
# Create Virtual Host
#########################################################################
create_virtual_host() {
    local domain="$1"
    
    # Detect web server
    if command -v nginx &> /dev/null; then
        create_nginx_vhost "$domain"
    elif command -v apache2 &> /dev/null; then
        create_apache_vhost "$domain"
    else
        print_warning "No supported web server found"
        return 1
    fi
}

#########################################################################
# Create Nginx Virtual Host
#########################################################################
create_nginx_vhost() {
    local domain="$1"
    
    cat > "/etc/nginx/sites-available/$domain" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root /var/www/$domain;
    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF
    
    # Enable site
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
    nginx -t && systemctl reload nginx
}

#########################################################################
# Request SSL Certificate
#########################################################################
request_ssl_certificate() {
    local domain="$1"
    
    print_info "Requesting SSL certificate for $domain..."
    
    if command -v certbot &> /dev/null; then
        certbot --nginx -d "$domain" -d "www.$domain" --non-interactive --agree-tos --email "admin@$domain"
        
        if [ $? -eq 0 ]; then
            # Update SSL status in database
            jq --arg domain "$domain" '
                .sites = (.sites | map(
                    if .domain == $domain then
                        .ssl_status = "active"
                    else
                        .
                    end
                ))
            ' "$SITES_DATABASE" > "$SITES_DATABASE.tmp" && mv "$SITES_DATABASE.tmp" "$SITES_DATABASE"
            
            print_success "SSL certificate installed for $domain"
        else
            print_warning "SSL certificate installation failed for $domain"
        fi
    else
        print_warning "Certbot not installed. SSL certificate not requested."
    fi
}

#########################################################################
# Bulk Operations
#########################################################################
bulk_operations() {
    local operation="$1"
    local target="${2:-all}"
    
    print_info "=== Bulk Operations ===" 
    print_info "Operation: $operation"
    print_info "Target: $target"
    
    case "$operation" in
        "backup")
            bulk_backup "$target"
            ;;
        "update")
            bulk_update "$target"
            ;;
        "plugin-install")
            local plugin="$3"
            bulk_plugin_install "$target" "$plugin"
            ;;
        "ssl-renew")
            bulk_ssl_renew "$target"
            ;;
        "health-check")
            bulk_health_check "$target"
            ;;
        *)
            print_error "Unknown operation: $operation"
            print_info "Available operations: backup, update, plugin-install, ssl-renew, health-check"
            ;;
    esac
}

#########################################################################
# Bulk Backup
#########################################################################
bulk_backup() {
    local target="$1"
    
    print_info "Starting bulk backup operation..."
    
    local sites
    if [ "$target" = "all" ]; then
        sites=$(jq -r '.sites[].domain' "$SITES_DATABASE")
    else
        sites="$target"
    fi
    
    local backup_count=0
    local success_count=0
    
    for domain in $sites; do
        if [ -d "/var/www/$domain" ]; then
            print_info "Backing up $domain..."
            ((backup_count++))
            
            # Create backup directory
            local backup_dir
            backup_dir="/var/backups/multisite/$(date +%Y%m%d)"
            mkdir -p "$backup_dir"
            
            # Backup files
            tar -czf "$backup_dir/${domain}_files_$(date +%Y%m%d_%H%M%S).tar.gz" -C "/var/www" "$domain"
            
            # Backup database
            local db_name
            db_name="wp_$(echo "$domain" | tr '.-' '_')"
            mysqldump "$db_name" > "$backup_dir/${domain}_db_$(date +%Y%m%d_%H%M%S).sql"
            
            if [ $? -eq 0 ]; then
                ((success_count++))
                print_success "Backup completed for $domain"
                
                # Update last backup time in database
                jq --arg domain "$domain" --arg backup_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
                    .sites = (.sites | map(
                        if .domain == $domain then
                            .last_backup = $backup_time
                        else
                            .
                        end
                    ))
                ' "$SITES_DATABASE" > "$SITES_DATABASE.tmp" && mv "$SITES_DATABASE.tmp" "$SITES_DATABASE"
            else
                print_error "Backup failed for $domain"
            fi
        fi
    done
    
    print_success "Bulk backup completed: $success_count/$backup_count sites backed up successfully"
}

#########################################################################
# Bulk WordPress Update
#########################################################################
bulk_update() {
    local target="$1"
    
    print_info "Starting bulk WordPress update..."
    
    local sites
    if [ "$target" = "all" ]; then
        sites=$(jq -r '.sites[].domain' "$SITES_DATABASE")
    else
        sites="$target"
    fi
    
    local update_count=0
    local success_count=0
    
    for domain in $sites; do
        if [ -d "/var/www/$domain" ]; then
            print_info "Updating WordPress for $domain..."
            ((update_count++))
            
            cd "/var/www/$domain" || continue
            
            # Update WordPress core
            sudo -u www-data wp core update --allow-root
            
            # Update plugins
            sudo -u www-data wp plugin update --all --allow-root
            
            # Update themes
            sudo -u www-data wp theme update --all --allow-root
            
            if [ $? -eq 0 ]; then
                ((success_count++))
                print_success "Update completed for $domain"
            else
                print_error "Update failed for $domain"
            fi
        fi
    done
    
    print_success "Bulk update completed: $success_count/$update_count sites updated successfully"
}

#########################################################################
# Site Performance Analytics
#########################################################################
show_site_analytics() {
    print_info "=== Multi-Site Performance Analytics ==="
    
    local total_sites
    local active_sites
    local total_disk_usage
    
    total_sites=$(jq '.total_sites' "$SITES_DATABASE")
    active_sites=$(jq '.active_sites' "$SITES_DATABASE")
    total_disk_usage=$(du -sh /var/www 2>/dev/null | cut -f1 || echo "N/A")
    
    echo ""
    print_info "📊 Global Statistics:"
    echo "  Total Sites: $total_sites"
    echo "  Active Sites: $active_sites"
    echo "  Total Disk Usage: $total_disk_usage"
    echo "  Average Site Size: $(( $(du -s /var/www 2>/dev/null | cut -f1 || echo "0") / (total_sites > 0 ? total_sites : 1) ))KB"
    
    echo ""
    print_info "🚀 Performance Metrics:"
    
    # Top 5 sites by disk usage
    print_info "Top 5 Sites by Disk Usage:"
    find /var/www -maxdepth 1 -type d -name "*.*" -exec du -sh {} \; 2>/dev/null | \
    sort -hr | head -5 | while read -r size path; do
        local domain
        domain=$(basename "$path")
        echo "  $domain: $size"
    done
    
    echo ""
    print_info "🔒 Security Status:"
    local ssl_count
    ssl_count=$(jq '.sites | map(select(.ssl_status == "active")) | length' "$SITES_DATABASE")
    echo "  Sites with SSL: $ssl_count/$total_sites"
    
    jq -r '.sites[].domain' "$SITES_DATABASE" | while read -r domain; do
        if [ -d "/var/www/$domain" ]; then
            cd "/var/www/$domain" || continue
            local wp_version
            wp_version=$(sudo -u www-data wp core version --allow-root 2>/dev/null)
            if [ -n "$wp_version" ]; then
                echo "  $domain: WordPress $wp_version"
            fi
        fi
    done | head -5
    
    echo ""
    print_info "📈 Resource Distribution:"
    jq -r '.sites | group_by(.resource_plan) | .[] | "\(.[0].resource_plan): \(length) sites"' "$SITES_DATABASE" 2>/dev/null
}

#########################################################################
# Delete Site
#########################################################################
delete_site() {
    local domain="$1"
    local confirm="$2"
    
    if [ -z "$domain" ]; then
        print_error "Domain is required"
        return 1
    fi
    
    if [ "$confirm" != "yes" ]; then
        print_warning "This will permanently delete $domain and all its data!"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" != "yes" ]; then
            print_info "Site deletion cancelled"
            return 0
        fi
    fi
    
    print_info "Deleting site: $domain"
    
    # Remove from sites database
    jq --arg domain "$domain" '
        .sites = (.sites | map(select(.domain != $domain))) |
        .total_sites = (.sites | length) |
        .active_sites = (.sites | map(select(.status == "active")) | length)
    ' "$SITES_DATABASE" > "$SITES_DATABASE.tmp" && mv "$SITES_DATABASE.tmp" "$SITES_DATABASE"
    
    # Remove site files
    if [ -d "/var/www/$domain" ]; then
        sudo rm -rf "/var/www/$domain"
        print_success "Site files removed"
    fi
    
    # Remove database
    local db_name
    db_name="wp_$(echo "$domain" | tr '.-' '_')"
    mysql -u root <<EOF
DROP DATABASE IF EXISTS \`$db_name\`;
DROP USER IF EXISTS '$db_name'@'localhost';
EOF
    print_success "Database removed"
    
    # Remove virtual host
    if [ -f "/etc/nginx/sites-enabled/$domain" ]; then
        sudo rm -f "/etc/nginx/sites-enabled/$domain"
        sudo rm -f "/etc/nginx/sites-available/$domain"
        sudo nginx -t && sudo systemctl reload nginx
        print_success "Virtual host removed"
    fi
    
    # Remove SSL certificate
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        sudo certbot delete --cert-name "$domain" --non-interactive
        print_success "SSL certificate removed"
    fi
    
    log_multisite "SUCCESS" "Site $domain deleted successfully"
    print_success "Site $domain deleted successfully!"
}

#########################################################################
# Clone Site
#########################################################################
clone_site() {
    local source_domain="$1"
    local target_domain="$2"
    local admin_email="$3"
    
    if [ -z "$source_domain" ] || [ -z "$target_domain" ] || [ -z "$admin_email" ]; then
        print_error "Source domain, target domain, and admin email are required"
        return 1
    fi
    
    if [ ! -d "/var/www/$source_domain" ]; then
        print_error "Source site $source_domain does not exist"
        return 1
    fi
    
    if [ -d "/var/www/$target_domain" ]; then
        print_error "Target site $target_domain already exists"
        return 1
    fi
    
    print_info "Cloning site from $source_domain to $target_domain..."
    
    # Clone files
    sudo cp -r "/var/www/$source_domain" "/var/www/$target_domain"
    sudo chown -R www-data:www-data "/var/www/$target_domain"
    
    # Clone database
    local source_db
    source_db="wp_$(echo "$source_domain" | tr '.-' '_')"
    local target_db
    target_db="wp_$(echo "$target_domain" | tr '.-' '_')"
    local db_pass
    db_pass=$(openssl rand -base64 16)
    
    # Create new database
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`$target_db\`;
CREATE USER IF NOT EXISTS '$target_db'@'localhost' IDENTIFIED BY '$db_pass';
GRANT ALL PRIVILEGES ON \`$target_db\`.* TO '$target_db'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Copy database content
    mysqldump "$source_db" | mysql "$target_db"
    
    # Update WordPress configuration
    cd "/var/www/$target_domain" || return 1
    
    # Update wp-config.php
    sudo -u www-data wp config set DB_NAME "$target_db" --allow-root
    sudo -u www-data wp config set DB_USER "$target_db" --allow-root
    sudo -u www-data wp config set DB_PASSWORD "$db_pass" --allow-root
    
    # Update site URLs
    sudo -u www-data wp search-replace "https://$source_domain" "https://$target_domain" --allow-root
    sudo -u www-data wp search-replace "http://$source_domain" "https://$target_domain" --allow-root
    
    # Update admin email
    sudo -u www-data wp option update admin_email "$admin_email" --allow-root
    
    # Get template and resource plan from source site
    local template
    local resource_plan
    template=$(jq -r --arg domain "$source_domain" '.sites[] | select(.domain == $domain) | .template' "$SITES_DATABASE")
    resource_plan=$(jq -r --arg domain "$source_domain" '.sites[] | select(.domain == $domain) | .resource_plan' "$SITES_DATABASE")
    
    # Add cloned site to database
    add_site_to_database "$target_domain" "${template:-wordpress_basic}" "$admin_email" "${resource_plan:-medium}"
    
    # Create virtual host
    create_virtual_host "$target_domain"
    
    # Request SSL certificate
    request_ssl_certificate "$target_domain"
    
    log_multisite "SUCCESS" "Site cloned from $source_domain to $target_domain"
    print_success "Site cloned successfully!"
    print_info "Access cloned site at: https://$target_domain"
}

#########################################################################
# Interactive Menu
#########################################################################
show_multisite_menu() {
    while true; do
        clear
        color_echo cyan "🌍 LOMP Stack v2.0 - Multi-Site Manager"
        echo "=============================================="
        color_echo yellow "1.  📋 List All Sites"
        color_echo yellow "2.  ➕ Create New Site from Template"
        color_echo yellow "3.  👥 Bulk Operations"
        color_echo yellow "4.  📊 Site Analytics & Performance"
        color_echo yellow "5.  🗂️  Manage Templates"
        color_echo yellow "6.  📂 Clone Existing Site"
        color_echo yellow "7.  🗑️  Delete Site"
        color_echo yellow "8.  🔧 Configure Multi-Site Settings"
        color_echo yellow "9.  💾 Backup All Sites"
        color_echo yellow "10. 🔄 Update All Sites"
        color_echo yellow "11. 🔍 Health Check All Sites"
        color_echo yellow "12. 📈 Resource Usage Report"
        color_echo red "0.  ↩️  Return to Enterprise Dashboard"
        echo "=============================================="
        
        read -p "Select an option (0-12): " choice
        
        case $choice in
            1)
                list_all_sites
                press_enter
                ;;
            2)
                echo ""
                print_info "Available templates:"
                print_info "1. wordpress_basic - Standard WordPress"
                print_info "2. wordpress_ecommerce - WordPress with WooCommerce"
                print_info "3. wordpress_blog - Optimized for blogging"
                echo ""
                read -p "Enter domain: " domain
                read -p "Select template (1-3): " template_choice
                read -p "Enter admin email: " admin_email
                read -p "Resource plan (small/medium/large/enterprise): " resource_plan
                
                case $template_choice in
                    1) template="wordpress_basic" ;;
                    2) template="wordpress_ecommerce" ;;
                    3) template="wordpress_blog" ;;
                    *) template="wordpress_basic" ;;
                esac
                
                create_site_from_template "$domain" "$template" "$admin_email" "${resource_plan:-medium}"
                press_enter
                ;;
            3)
                echo ""
                print_info "Bulk Operations:"
                print_info "1. Backup all sites"
                print_info "2. Update all sites"
                print_info "3. Install plugin on all sites"
                print_info "4. Renew SSL certificates"
                print_info "5. Health check all sites"
                echo ""
                read -p "Select operation (1-5): " bulk_op
                read -p "Target (domain or 'all'): " target
                
                case $bulk_op in
                    1) bulk_operations "backup" "$target" ;;
                    2) bulk_operations "update" "$target" ;;
                    3) 
                        read -p "Plugin name: " plugin
                        bulk_operations "plugin-install" "$target" "$plugin"
                        ;;
                    4) bulk_operations "ssl-renew" "$target" ;;
                    5) bulk_operations "health-check" "$target" ;;
                esac
                press_enter
                ;;
            4)
                show_site_analytics
                press_enter
                ;;
            5)
                print_info "Template management - Coming Soon"
                press_enter
                ;;
            6)
                echo ""
                read -p "Source domain: " source_domain
                read -p "Target domain: " target_domain
                read -p "Admin email for new site: " admin_email
                clone_site "$source_domain" "$target_domain" "$admin_email"
                press_enter
                ;;
            7)
                echo ""
                read -p "Domain to delete: " domain
                delete_site "$domain"
                press_enter
                ;;
            8)
                print_info "Opening multi-site configuration..."
                if command -v nano &> /dev/null; then
                    nano "$MULTISITE_CONFIG"
                else
                    cat "$MULTISITE_CONFIG"
                fi
                press_enter
                ;;
            9)
                bulk_operations "backup" "all"
                press_enter
                ;;
            10)
                bulk_operations "update" "all" 
                press_enter
                ;;
            11)
                bulk_operations "health-check" "all"
                press_enter
                ;;
            12)
                show_site_analytics
                press_enter
                ;;
            0)
                break
                ;;
            *)
                color_echo red "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

#########################################################################
# Main Function
#########################################################################
main() {
    log_multisite "INFO" "Starting Multi-Site Manager..."
    
    # Create required directories
    mkdir -p "$(dirname "$MULTISITE_LOG")"
    
    # Initialize if needed
    if [ ! -f "$MULTISITE_CONFIG" ]; then
        init_multisite_config
    fi
    
    if [ ! -f "$SITES_DATABASE" ]; then
        init_sites_database
    fi
    
    if [ ! -d "$TEMPLATES_DIR" ]; then
        create_templates_dir
    fi
    
    case "${1:-menu}" in
        "init")
            init_multisite_config
            init_sites_database
            create_templates_dir
            ;;
        "list")
            list_all_sites
            ;;
        "create")
            create_site_from_template "$2" "$3" "$4" "$5"
            ;;
        "delete")
            delete_site "$2" "$3"
            ;;
        "clone")
            clone_site "$2" "$3" "$4"
            ;;
        "bulk")
            bulk_operations "$2" "$3" "$4"
            ;;
        "analytics")
            show_site_analytics
            ;;
        "menu"|*)
            show_multisite_menu
            ;;
    esac
}

# Helper function for "Press Enter to continue"
press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
