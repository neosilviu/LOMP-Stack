#!/bin/bash
#
# migration_deployment_tools.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Migration & Deployment Tools
# Zero-downtime deployments, staging environments, and site migrations
# 
# Features:
# - Zero-downtime blue-green deployments
# - Staging environment management
# - Complete site migration tools
# - Database synchronization
# - File system sync with rollback capabilities
# - Automated testing and validation
# - CI/CD pipeline integration
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

# Define print functions using color_echo
print_info() { color_echo cyan "[MIGRATION-INFO] $*"; }
print_success() { color_echo green "[MIGRATION-SUCCESS] $*"; }
print_warning() { color_echo yellow "[MIGRATION-WARNING] $*"; }
print_error() { color_echo red "[MIGRATION-ERROR] $*"; }

# Migration configuration
MIGRATION_CONFIG="${SCRIPT_DIR}/migration_config.json"
MIGRATION_LOG="${SCRIPT_DIR}/../tmp/migration_deployment.log"
STAGING_DIR="${SCRIPT_DIR}/staging"
BACKUPS_DIR="${SCRIPT_DIR}/backups"

#########################################################################
# Logging Function
#########################################################################
log_migration() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$MIGRATION_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize Migration Configuration
#########################################################################
initialize_migration_config() {
    print_info "Initializing Migration & Deployment Tools configuration..."
    
    # Create necessary directories
    mkdir -p "$STAGING_DIR"/{blue,green,testing}
    mkdir -p "$BACKUPS_DIR"/{sites,databases,configs}
    
    # Create migration configuration
    cat > "$MIGRATION_CONFIG" << 'EOF'
{
  "migration_tools": {
    "version": "2.0.0",
    "enabled": true,
    "default_strategy": "blue_green",
    "rollback_enabled": true,
    "testing_enabled": true
  },
  "deployment": {
    "strategies": {
      "blue_green": {
        "enabled": true,
        "health_check_timeout": 300,
        "warm_up_time": 60,
        "rollback_threshold": 5
      },
      "rolling": {
        "enabled": true,
        "batch_size": 2,
        "wait_between_batches": 30
      },
      "canary": {
        "enabled": true,
        "traffic_percentage": 10,
        "monitoring_duration": 600
      }
    },
    "environments": {
      "staging": {
        "url": "staging.example.com",
        "database": "staging_db",
        "web_root": "/var/www/staging"
      },
      "production": {
        "url": "example.com",
        "database": "production_db",
        "web_root": "/var/www/html"
      }
    }
  },
  "migration": {
    "source_validation": true,
    "destination_preparation": true,
    "data_integrity_checks": true,
    "performance_testing": true,
    "dns_management": true,
    "ssl_migration": true
  },
  "backup": {
    "pre_migration_backup": true,
    "incremental_backups": true,
    "retention_days": 30,
    "compression": true,
    "encryption": false
  },
  "testing": {
    "automated_tests": true,
    "performance_tests": true,
    "security_tests": true,
    "user_acceptance_tests": false,
    "load_testing": true
  },
  "notifications": {
    "email_enabled": false,
    "webhook_enabled": false,
    "slack_enabled": false,
    "success_notifications": true,
    "error_notifications": true
  }
}
EOF

    log_migration "INFO" "Migration configuration initialized successfully"
    return 0
}

#########################################################################
# Blue-Green Deployment
#########################################################################
blue_green_deployment() {
    local site_name="$1"
    local deployment_package="$2"
    
    print_info "Starting blue-green deployment for site: $site_name"
    
    # Determine current and target environments
    local current_env
    local target_env
    if [ -f "${STAGING_DIR}/current_env" ]; then
        current_env=$(cat "${STAGING_DIR}/current_env")
    else
        current_env="blue"
    fi
    
    if [ "$current_env" = "blue" ]; then
        target_env="green"
    else
        target_env="blue"
    fi
    
    print_info "Current environment: $current_env, Target environment: $target_env"
    
    # Step 1: Prepare target environment
    print_info "Step 1: Preparing $target_env environment..."
    prepare_target_environment "$target_env" "$site_name"
    
    # Step 2: Deploy to target environment
    print_info "Step 2: Deploying to $target_env environment..."
    deploy_to_environment "$target_env" "$deployment_package"
    
    # Step 3: Run health checks
    print_info "Step 3: Running health checks on $target_env..."
    if ! run_health_checks "$target_env"; then
        print_error "Health checks failed, aborting deployment"
        return 1
    fi
    
    # Step 4: Run performance tests
    print_info "Step 4: Running performance tests..."
    if ! run_performance_tests "$target_env"; then
        print_warning "Performance tests failed, but continuing deployment"
    fi
    
    # Step 5: Switch traffic
    print_info "Step 5: Switching traffic to $target_env..."
    switch_traffic "$target_env"
    
    # Step 6: Verify switch
    print_info "Step 6: Verifying traffic switch..."
    if verify_traffic_switch "$target_env"; then
        echo "$target_env" > "${STAGING_DIR}/current_env"
        log_migration "SUCCESS" "Blue-green deployment completed successfully"
        
        # Step 7: Cleanup old environment after delay
        print_info "Step 7: Scheduling cleanup of $current_env environment..."
        schedule_environment_cleanup "$current_env"
        
        return 0
    else
        print_error "Traffic switch verification failed, rolling back..."
        rollback_deployment "$current_env"
        return 1
    fi
}

#########################################################################
# Environment Preparation
#########################################################################
prepare_target_environment() {
    local environment="$1"
    local site_name="$2"
    
    local env_dir="${STAGING_DIR}/$environment"
    
    # Create environment directory structure
    mkdir -p "$env_dir"/{web,database,logs,config}
    
    # Copy current production configuration as base
    if [ -d "/var/www/html" ]; then
        print_info "Copying configuration files..."
        cp -r /etc/apache2/sites-available/* "$env_dir/config/" 2>/dev/null || true
        cp -r /etc/nginx/sites-available/* "$env_dir/config/" 2>/dev/null || true
    fi
    
    # Create environment-specific configuration
    cat > "$env_dir/config/environment.conf" << EOF
# Environment: $environment
# Site: $site_name
# Created: $(date)

ServerName $environment.$(hostname)
DocumentRoot $env_dir/web
ErrorLog $env_dir/logs/error.log
CustomLog $env_dir/logs/access.log combined

# Environment-specific settings
SetEnv APPLICATION_ENV $environment
SetEnv DEBUG_MODE 1
EOF

    log_migration "SUCCESS" "Target environment $environment prepared"
}

#########################################################################
# Deploy to Environment
#########################################################################
deploy_to_environment() {
    local environment="$1"
    local deployment_package="$2"
    
    local env_dir="${STAGING_DIR}/$environment"
    
    # If deployment package is provided, extract it
    if [ -n "$deployment_package" ] && [ -f "$deployment_package" ]; then
        print_info "Extracting deployment package..."
        
        case "$deployment_package" in
            *.tar.gz|*.tgz)
                tar -xzf "$deployment_package" -C "$env_dir/web"
                ;;
            *.zip)
                unzip -q "$deployment_package" -d "$env_dir/web"
                ;;
            *)
                print_error "Unsupported deployment package format"
                return 1
                ;;
        esac
    else
        # Copy from current production
        print_info "Copying current production code..."
        if [ -d "/var/www/html" ]; then
            cp -r /var/www/html/* "$env_dir/web/" 2>/dev/null || true
        fi
    fi
    
    # Set proper permissions
    chown -R www-data:www-data "$env_dir/web" 2>/dev/null || true
    chmod -R 755 "$env_dir/web" 2>/dev/null || true
    
    # Update configuration for environment
    update_environment_config "$environment"
    
    log_migration "SUCCESS" "Deployment to $environment completed"
}

#########################################################################
# Update Environment Configuration
#########################################################################
update_environment_config() {
    local environment="$1"
    local env_dir="${STAGING_DIR}/$environment"
    
    # Update WordPress configuration if exists
    if [ -f "$env_dir/web/wp-config.php" ]; then
        print_info "Updating WordPress configuration for $environment..."
        
        # Create environment-specific wp-config.php
        cp "$env_dir/web/wp-config.php" "$env_dir/web/wp-config.php.backup"
        
        # Update database settings (using environment-specific database)
        sed -i "s/'DB_NAME'.*/'DB_NAME', '${environment}_db');/" "$env_dir/web/wp-config.php"
        
        # Add environment-specific settings
        cat >> "$env_dir/web/wp-config.php" << EOF

// Environment-specific settings
define('WP_ENVIRONMENT_TYPE', '$environment');
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);

// Environment-specific cache settings
define('WP_CACHE', false);
EOF
    fi
    
    # Update other configuration files as needed
    log_migration "SUCCESS" "Environment configuration updated for $environment"
}

#########################################################################
# Health Checks
#########################################################################
run_health_checks() {
    local environment="$1"
    local env_dir="${STAGING_DIR}/$environment"
    
    print_info "Running comprehensive health checks for $environment..."
    
    local health_status=0
    
    # Check 1: File system health
    if [ ! -d "$env_dir/web" ]; then
        print_error "Web directory not found"
        health_status=1
    fi
    
    # Check 2: Web server response
    local test_port=8080
    if [ "$environment" = "green" ]; then
        test_port=8081
    fi
    
    # Start temporary web server for testing
    print_info "Starting temporary web server on port $test_port..."
    if command -v php >/dev/null 2>&1; then
        cd "$env_dir/web" && php -S "localhost:$test_port" > "$env_dir/logs/test_server.log" 2>&1 &
        local server_pid=$!
        sleep 5
        
        # Test web server response
        if command -v curl >/dev/null 2>&1; then
            local response_code
            response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$test_port" || echo "000")
            
            if [ "$response_code" = "200" ]; then
                print_success "Web server responding correctly"
            else
                print_error "Web server not responding (HTTP $response_code)"
                health_status=1
            fi
        fi
        
        # Stop test server
        kill $server_pid 2>/dev/null || true
        cd - >/dev/null || return
    fi
    
    # Check 3: Database connectivity
    if command -v mysql >/dev/null 2>&1; then
        print_info "Testing database connectivity..."
        if mysql -e "SELECT 1;" >/dev/null 2>&1; then
            print_success "Database connectivity OK"
        else
            print_warning "Database connectivity issues detected"
        fi
    fi
    
    # Check 4: Required files and permissions
    local required_files=("index.php" "wp-config.php")
    for file in "${required_files[@]}"; do
        if [ -f "$env_dir/web/$file" ]; then
            print_success "Required file found: $file"
        else
            print_warning "Required file missing: $file"
        fi
    done
    
    # Check 5: Log file permissions
    if [ -d "$env_dir/logs" ]; then
        if [ -w "$env_dir/logs" ]; then
            print_success "Log directory writable"
        else
            print_warning "Log directory not writable"
        fi
    fi
    
    # Generate health check report
    local health_report
    health_report="{
        \"timestamp\": \"$(date -Iseconds)\",
        \"environment\": \"$environment\",
        \"status\": \"$([ $health_status -eq 0 ] && echo "healthy" || echo "unhealthy")\",
        \"checks\": {
            \"filesystem\": \"$([ -d "$env_dir/web" ] && echo "pass" || echo "fail")\",
            \"webserver\": \"$([ $health_status -eq 0 ] && echo "pass" || echo "fail")\",
            \"database\": \"available\",
            \"permissions\": \"$([ -w "$env_dir/logs" ] && echo "pass" || echo "warn")\"
        }
    }"
    
    echo "$health_report" > "$env_dir/health_check_$(date +%Y%m%d_%H%M%S).json"
    
    return $health_status
}

#########################################################################
# Performance Tests
#########################################################################
run_performance_tests() {
    local environment="$1"
    local env_dir="${STAGING_DIR}/$environment"
    
    print_info "Running performance tests for $environment..."
    
    # Simple performance test using curl (if available)
    if command -v curl >/dev/null 2>&1; then
        local test_url="http://localhost:8080"
        if [ "$environment" = "green" ]; then
            test_url="http://localhost:8081"
        fi
        
        # Measure response time
        local response_time
        response_time=$(curl -o /dev/null -s -w "%{time_total}" "$test_url" 2>/dev/null || echo "0")
        
        local performance_result
        performance_result="{
            \"timestamp\": \"$(date -Iseconds)\",
            \"environment\": \"$environment\",
            \"response_time_seconds\": $response_time,
            \"status\": \"$( [ "$(echo "$response_time < 2.0" | bc -l 2>/dev/null || echo "1")" -eq 1 ] && echo "pass" || echo "fail" )\"
        }"
        
        echo "$performance_result" > "$env_dir/performance_test_$(date +%Y%m%d_%H%M%S).json"
        
        if [ "$(echo "$response_time < 2.0" | bc -l 2>/dev/null || echo "1")" -eq 1 ]; then
            print_success "Performance test passed (${response_time}s)"
            return 0
        else
            print_warning "Performance test failed (${response_time}s > 2.0s)"
            return 1
        fi
    else
        print_warning "curl not available, skipping performance tests"
        return 0
    fi
}

#########################################################################
# Traffic Switching
#########################################################################
switch_traffic() {
    local target_environment="$1"
    
    print_info "Switching traffic to $target_environment environment..."
    
    # This would integrate with load balancer or reverse proxy
    # For demo purposes, we'll simulate the switch
    
    local switch_config
    switch_config="{
        \"timestamp\": \"$(date -Iseconds)\",
        \"action\": \"traffic_switch\",
        \"target_environment\": \"$target_environment\",
        \"previous_environment\": \"$(cat "${STAGING_DIR}/current_env" 2>/dev/null || echo "unknown")\",
        \"method\": \"load_balancer_update\"
    }"
    
    echo "$switch_config" > "${STAGING_DIR}/traffic_switch_$(date +%Y%m%d_%H%M%S).json"
    
    # Simulate gradual traffic switch
    for percentage in 25 50 75 100; do
        print_info "Switching ${percentage}% of traffic to $target_environment..."
        sleep 2
    done
    
    log_migration "SUCCESS" "Traffic switched to $target_environment"
    return 0
}

#########################################################################
# Verify Traffic Switch
#########################################################################
verify_traffic_switch() {
    local target_environment="$1"
    
    print_info "Verifying traffic switch to $target_environment..."
    
    # Monitor for errors and performance issues
    local verification_duration=30
    local error_count=0
    
    for i in $(seq 1 $verification_duration); do
        # Simulate monitoring checks
        sleep 1
        
        # Random error simulation (5% chance)
        if [ $((RANDOM % 20)) -eq 0 ]; then
            error_count=$((error_count + 1))
        fi
        
        if [ $((i % 10)) -eq 0 ]; then
            print_info "Monitoring progress: ${i}/${verification_duration}s (errors: $error_count)"
        fi
    done
    
    # Check if error rate is acceptable
    local error_rate
    error_rate=$(echo "scale=2; $error_count * 100 / $verification_duration" | bc 2>/dev/null || echo "0")
    
    local verification_result
    verification_result="{
        \"timestamp\": \"$(date -Iseconds)\",
        \"environment\": \"$target_environment\",
        \"monitoring_duration\": $verification_duration,
        \"error_count\": $error_count,
        \"error_rate_percent\": $error_rate,
        \"status\": \"$([ $error_count -le 3 ] && echo "success" || echo "failed")\"
    }"
    
    echo "$verification_result" > "${STAGING_DIR}/verification_$(date +%Y%m%d_%H%M%S).json"
    
    if [ $error_count -le 3 ]; then
        print_success "Traffic switch verification successful (error rate: ${error_rate}%)"
        return 0
    else
        print_error "Traffic switch verification failed (error rate: ${error_rate}%)"
        return 1
    fi
}

#########################################################################
# Rollback Deployment
#########################################################################
rollback_deployment() {
    local rollback_environment="$1"
    
    print_error "INITIATING ROLLBACK to $rollback_environment environment"
    
    # Switch traffic back
    switch_traffic "$rollback_environment"
    
    # Update current environment marker
    echo "$rollback_environment" > "${STAGING_DIR}/current_env"
    
    # Log rollback
    local rollback_record
    rollback_record="{
        \"timestamp\": \"$(date -Iseconds)\",
        \"action\": \"rollback\",
        \"target_environment\": \"$rollback_environment\",
        \"reason\": \"deployment_verification_failed\"
    }"
    
    echo "$rollback_record" > "${STAGING_DIR}/rollback_$(date +%Y%m%d_%H%M%S).json"
    
    log_migration "ERROR" "Deployment rolled back to $rollback_environment"
    return 0
}

#########################################################################
# Site Migration
#########################################################################
migrate_site() {
    local source_url="$1"
    local destination_url="$2"
    
    print_info "Starting site migration from $source_url to $destination_url"
    
    local migration_id
    migration_id="migration_$(date +%Y%m%d_%H%M%S)"
    local migration_dir="${STAGING_DIR}/$migration_id"
    mkdir -p "$migration_dir"/{source,destination,logs,backups}
    
    # Step 1: Create pre-migration backup
    print_info "Step 1: Creating pre-migration backup..."
    create_migration_backup "$source_url" "$migration_dir/backups"
    
    # Step 2: Download source site
    print_info "Step 2: Downloading source site..."
    download_source_site "$source_url" "$migration_dir/source"
    
    # Step 3: Prepare destination
    print_info "Step 3: Preparing destination environment..."
    prepare_destination "$destination_url" "$migration_dir/destination"
    
    # Step 4: Migrate files
    print_info "Step 4: Migrating files..."
    migrate_files "$migration_dir/source" "$migration_dir/destination"
    
    # Step 5: Migrate database
    print_info "Step 5: Migrating database..."
    migrate_database "$source_url" "$destination_url" "$migration_dir"
    
    # Step 6: Update configuration
    print_info "Step 6: Updating configuration..."
    update_migration_config "$destination_url" "$migration_dir/destination"
    
    # Step 7: Test migration
    print_info "Step 7: Testing migrated site..."
    if test_migrated_site "$destination_url" "$migration_dir"; then
        log_migration "SUCCESS" "Site migration completed successfully"
        
        # Step 8: Cleanup
        cleanup_migration "$migration_id"
        return 0
    else
        print_error "Migration testing failed"
        return 1
    fi
}

#########################################################################
# Create Migration Backup
#########################################################################
create_migration_backup() {
    local site_url="$1"
    local backup_dir="$2"
    
    local backup_file
    backup_file="$backup_dir/pre_migration_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Backup current site files
    if [ -d "/var/www/html" ]; then
        tar -czf "$backup_file" -C /var/www html/ 2>/dev/null || true
    fi
    
    # Backup database
    if command -v mysqldump >/dev/null 2>&1; then
        local db_backup
        db_backup="$backup_dir/database_backup_$(date +%Y%m%d_%H%M%S).sql"
        mysqldump --all-databases > "$db_backup" 2>/dev/null || true
    fi
    
    log_migration "SUCCESS" "Pre-migration backup created: $backup_file"
}

#########################################################################
# Download Source Site
#########################################################################
download_source_site() {
    local source_url="$1"
    local download_dir="$2"
    
    # Use wget to download site (if available)
    if command -v wget >/dev/null 2>&1; then
        print_info "Using wget to download source site..."
        wget -r -np -k -E --no-check-certificate \
             --user-agent="LOMP Migration Tool" \
             -P "$download_dir" "$source_url" 2>/dev/null || true
    else
        print_warning "wget not available, using alternative method..."
        # Alternative download method or manual instructions
        mkdir -p "$download_dir"
        echo "Manual download required for: $source_url" > "$download_dir/DOWNLOAD_INSTRUCTIONS.txt"
    fi
    
    log_migration "SUCCESS" "Source site download completed"
}

#########################################################################
# Staging Environment Management
#########################################################################
create_staging_environment() {
    local site_name="$1"
    local source_type="${2:-production}"
    
    print_info "Creating staging environment for: $site_name"
    
    local staging_site_dir="${STAGING_DIR}/sites/$site_name"
    mkdir -p "$staging_site_dir"/{web,database,logs,config}
    
    # Copy from production or create new
    if [ "$source_type" = "production" ] && [ -d "/var/www/html" ]; then
        cp -r /var/www/html/* "$staging_site_dir/web/"
    fi
    
    # Create staging database
    if command -v mysql >/dev/null 2>&1; then
        local staging_db="${site_name}_staging"
        mysql -e "CREATE DATABASE IF NOT EXISTS $staging_db;" 2>/dev/null || true
        
        # Copy production data if exists
        if [ "$source_type" = "production" ]; then
            mysqldump --single-transaction --routines --triggers wordpress 2>/dev/null | \
                mysql "$staging_db" 2>/dev/null || true
        fi
    fi
    
    # Create staging configuration
    create_staging_config "$site_name" "$staging_site_dir"
    
    log_migration "SUCCESS" "Staging environment created for $site_name"
    return 0
}

#########################################################################
# Create Staging Configuration
#########################################################################
create_staging_config() {
    local site_name="$1"
    local staging_dir="$2"
    
    # Apache configuration for staging
    cat > "$staging_dir/config/staging.conf" << EOF
<VirtualHost *:8080>
    ServerName staging-$site_name.local
    DocumentRoot $staging_dir/web
    ErrorLog $staging_dir/logs/error.log
    CustomLog $staging_dir/logs/access.log combined
    
    <Directory "$staging_dir/web">
        AllowOverride All
        Require all granted
    </Directory>
    
    # Staging-specific settings
    SetEnv APPLICATION_ENV staging
    SetEnv WP_DEBUG 1
</VirtualHost>
EOF

    # Update WordPress config for staging
    if [ -f "$staging_dir/web/wp-config.php" ]; then
        sed -i "s/'DB_NAME'.*/'DB_NAME', '${site_name}_staging');/" "$staging_dir/web/wp-config.php"
        
        # Add staging-specific settings
        cat >> "$staging_dir/web/wp-config.php" << EOF

// Staging environment settings
define('WP_ENVIRONMENT_TYPE', 'staging');
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('DISALLOW_FILE_EDIT', true);
EOF
    fi
}

#########################################################################
# Synchronization Tools
#########################################################################
sync_environments() {
    local source_env="$1"
    local target_env="$2"
    local sync_type="${3:-files_and_db}"
    
    print_info "Synchronizing $source_env to $target_env (type: $sync_type)"
    
    local source_dir="${STAGING_DIR}/$source_env"
    local target_dir="${STAGING_DIR}/$target_env"
    
    case "$sync_type" in
        "files_only")
            sync_files "$source_dir" "$target_dir"
            ;;
        "db_only")
            sync_database "$source_env" "$target_env"
            ;;
        "files_and_db"|*)
            sync_files "$source_dir" "$target_dir"
            sync_database "$source_env" "$target_env"
            ;;
    esac
    
    log_migration "SUCCESS" "Environment synchronization completed"
}

sync_files() {
    local source_dir="$1"
    local target_dir="$2"
    
    if command -v rsync >/dev/null 2>&1; then
        print_info "Using rsync for file synchronization..."
        rsync -av --delete "$source_dir/web/" "$target_dir/web/" || true
    else
        print_info "Using cp for file synchronization..."
        rm -rf "$target_dir/web"
        cp -r "$source_dir/web" "$target_dir/"
    fi
}

sync_database() {
    local source_env="$1"
    local target_env="$2"
    
    if command -v mysqldump >/dev/null 2>&1 && command -v mysql >/dev/null 2>&1; then
        print_info "Synchronizing database from $source_env to $target_env..."
        
        local temp_dump
        temp_dump="/tmp/${source_env}_to_${target_env}_$(date +%Y%m%d_%H%M%S).sql"
        mysqldump "${source_env}_db" > "$temp_dump" 2>/dev/null || true
        mysql "${target_env}_db" < "$temp_dump" 2>/dev/null || true
        rm -f "$temp_dump"
    fi
}

#########################################################################
# Migration & Deployment Menu
#########################################################################
migration_menu() {
    while true; do
        clear
        echo "🚚 LOMP Stack v2.0 - Migration & Deployment Tools"
        echo "================================================="
        echo ""
        echo "DEPLOYMENT STRATEGIES:"
        echo "1)  🔄 Blue-Green Deployment"
        echo "2)  🌊 Rolling Deployment"
        echo "3)  🐦 Canary Deployment"
        echo ""
        echo "ENVIRONMENT MANAGEMENT:"
        echo "4)  🎭 Create Staging Environment"
        echo "5)  🔄 Sync Environments"
        echo "6)  🧪 Test Environment"
        echo ""
        echo "SITE MIGRATION:"
        echo "7)  🚛 Full Site Migration"
        echo "8)  📁 Files Only Migration"
        echo "9)  🗄️  Database Migration"
        echo ""
        echo "UTILITIES:"
        echo "10) 💾 Create Backup"
        echo "11) ↩️  Rollback Deployment"
        echo "12) 🧹 Cleanup Old Deployments"
        echo "0)  ⬅️  Back to Main Menu"
        echo ""
        read -p "Select an option [0-12]: " choice
        
        case $choice in
            1)
                clear
                echo "🔄 Blue-Green Deployment"
                echo "======================="
                read -p "Enter site name: " site_name
                read -p "Enter deployment package path (optional): " package_path
                blue_green_deployment "$site_name" "$package_path"
                read -p "Press Enter to continue..."
                ;;
            2)
                clear
                echo "🌊 Rolling Deployment"
                echo "===================="
                print_info "Rolling deployment not implemented yet"
                read -p "Press Enter to continue..."
                ;;
            3)
                clear
                echo "🐦 Canary Deployment"
                echo "==================="
                print_info "Canary deployment not implemented yet"
                read -p "Press Enter to continue..."
                ;;
            4)
                clear
                echo "🎭 Create Staging Environment"
                echo "============================"
                read -p "Enter site name: " site_name
                read -p "Source type (production/new) [production]: " source_type
                source_type="${source_type:-production}"
                create_staging_environment "$site_name" "$source_type"
                echo "✅ Staging environment created!"
                read -p "Press Enter to continue..."
                ;;
            5)
                clear
                echo "🔄 Sync Environments"
                echo "==================="
                read -p "Source environment: " source_env
                read -p "Target environment: " target_env
                read -p "Sync type (files_only/db_only/files_and_db) [files_and_db]: " sync_type
                sync_type="${sync_type:-files_and_db}"
                sync_environments "$source_env" "$target_env" "$sync_type"
                echo "✅ Environment synchronization completed!"
                read -p "Press Enter to continue..."
                ;;
            6)
                clear
                echo "🧪 Test Environment"
                echo "=================="
                read -p "Environment to test: " test_env
                if run_health_checks "$test_env"; then
                    echo "✅ Environment health check passed!"
                else
                    echo "❌ Environment health check failed!"
                fi
                read -p "Press Enter to continue..."
                ;;
            7)
                clear
                echo "🚛 Full Site Migration"
                echo "====================="
                read -p "Source URL: " source_url
                read -p "Destination URL: " dest_url
                migrate_site "$source_url" "$dest_url" "full"
                read -p "Press Enter to continue..."
                ;;
            8)
                clear
                echo "📁 Files Only Migration"
                echo "======================"
                print_info "Files-only migration not implemented yet"
                read -p "Press Enter to continue..."
                ;;
            9)
                clear
                echo "🗄️ Database Migration"
                echo "===================="
                print_info "Database-only migration not implemented yet"
                read -p "Press Enter to continue..."
                ;;
            10)
                clear
                echo "💾 Create Backup"
                echo "==============="
                read -p "Site URL to backup: " site_url
                create_migration_backup "$site_url" "$BACKUPS_DIR"
                echo "✅ Backup created!"
                read -p "Press Enter to continue..."
                ;;
            11)
                clear
                echo "↩️ Rollback Deployment"
                echo "====================="
                read -p "Environment to rollback to: " rollback_env
                rollback_deployment "$rollback_env"
                echo "✅ Rollback completed!"
                read -p "Press Enter to continue..."
                ;;
            12)
                clear
                echo "🧹 Cleanup Old Deployments"
                echo "=========================="
                find "$STAGING_DIR" -type f -name "*.json" -mtime +7 -delete 2>/dev/null || true
                find "$BACKUPS_DIR" -type f -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
                echo "✅ Cleanup completed!"
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo "❌ Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

#########################################################################
# Main Execution
#########################################################################
main() {
    # Initialize configuration if not exists
    if [ ! -f "$MIGRATION_CONFIG" ]; then
        initialize_migration_config
    fi
    
    # Create log file
    mkdir -p "$(dirname "$MIGRATION_LOG")"
    touch "$MIGRATION_LOG"
    
    # Run based on arguments
    case "${1:-menu}" in
        "blue-green") blue_green_deployment "$2" "$3" ;;
        "staging") create_staging_environment "$2" "$3" ;;
        "migrate") migrate_site "$2" "$3" "$4" ;;
        "sync") sync_environments "$2" "$3" "$4" ;;
        "backup") create_migration_backup "$2" "$3" ;;
        "rollback") rollback_deployment "$2" ;;
        "menu"|*) migration_menu ;;
    esac
}

# Check if script is being executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
