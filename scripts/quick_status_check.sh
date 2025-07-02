#!/bin/bash
#
# quick_status_check.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Quick Status Check for Phase 4 Modules
#########################################################################

echo "🚀 LOMP Stack v2.0 - Phase 4 Status Check"
echo "=========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check modules
modules=(
    "Enterprise Monitoring Suite:monitoring/enterprise/enterprise_monitoring_suite.sh"
    "WordPress Advanced Manager:wordpress/wp_advanced_manager.sh"
    "Advanced Analytics Engine:analytics/advanced_analytics_engine.sh"
    "CDN Integration Manager:cdn/cdn_integration_manager.sh"
    "Migration & Deployment Tools:migration/migration_deployment_tools.sh"
    "Multi-Site Manager:multisite/multisite_manager.sh"
    "API Management System:api/api_management_system.sh"
    "Auto-Scaling Manager:scaling/auto_scaling_manager.sh"
    "Advanced Security Manager:security/advanced/advanced_security_manager.sh"
    "Multi-Cloud Orchestrator:cloud/multi_cloud_orchestrator.sh"
    "Main Enterprise Dashboard:main_enterprise_dashboard.sh"
)

echo "📊 MODULE STATUS CHECK:"
echo "─────────────────────────────────────────────────────────────────"

total_modules=${#modules[@]}
working_modules=0

for module_info in "${modules[@]}"; do
    module_name="${module_info%%:*}"
    module_path="${module_info##*:}"
    full_path="${SCRIPT_DIR}/${module_path}"
    
    printf "%-35s " "$module_name:"
    
    if [ -f "$full_path" ]; then
        # Check if file is executable and has basic structure
        if grep -q "#!/bin/bash" "$full_path" && grep -q "main\|menu" "$full_path"; then
            echo "✅ IMPLEMENTED"
            ((working_modules++))
        else
            echo "⚠️  PARTIAL"
        fi
    else
        echo "❌ MISSING"
    fi
done

echo "─────────────────────────────────────────────────────────────────"
echo "📈 SUMMARY:"
echo "   Total Modules: $total_modules"
echo "   Implemented: $working_modules"
echo "   Progress: $(echo "scale=1; $working_modules * 100 / $total_modules" | bc -l 2>/dev/null || echo "N/A")%"
echo

# Check configuration files
echo "📁 CONFIGURATION FILES:"
echo "─────────────────────────────────────────────────────────────────"

config_files=(
    "Analytics Config:analytics/analytics_config.json"
    "CDN Config:cdn/cdn_config.json"
    "Migration Config:migration/migration_config.json"
    "WordPress Config:wordpress/wp_advanced_config.json"
    "Monitoring Config:monitoring/enterprise/monitoring_config.json"
    "Multisite Config:multisite/multisite_config.json"
)

for config_info in "${config_files[@]}"; do
    config_name="${config_info%%:*}"
    config_path="${config_info##*:}"
    full_path="${SCRIPT_DIR}/${config_path}"
    
    printf "%-25s " "$config_name:"
    
    if [ -f "$full_path" ]; then
        if jq empty "$full_path" 2>/dev/null; then
            echo "✅ VALID JSON"
        else
            echo "⚠️  INVALID JSON"
        fi
    else
        echo "❌ MISSING"
    fi
done

echo "─────────────────────────────────────────────────────────────────"
echo

# Check directory structure
echo "📂 DIRECTORY STRUCTURE:"
echo "─────────────────────────────────────────────────────────────────"

directories=(
    "analytics"
    "cdn"
    "migration"
    "monitoring/enterprise"
    "multisite"
    "wordpress"
    "scaling"
    "security/advanced"
    "api"
    "cloud"
)

for dir in "${directories[@]}"; do
    full_path="${SCRIPT_DIR}/${dir}"
    printf "%-25s " "$dir:"
    
    if [ -d "$full_path" ]; then
        file_count=$(find "$full_path" -type f | wc -l)
        echo "✅ EXISTS ($file_count files)"
    else
        echo "❌ MISSING"
    fi
done

echo "─────────────────────────────────────────────────────────────────"
echo "✨ Phase 4 Status Check Complete!"
echo
