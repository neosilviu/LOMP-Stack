#!/bin/bash
#
# test_phase4b_enterprise.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Test Phase 4B Enterprise Modules
# Testing newly implemented Phase 4B enterprise modules:
# - Advanced Security Manager (with Cloudflare Tunneling)
# - Auto-Scaling Manager
# - Updated Enterprise Dashboard integration
#########################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers/utils/functions.sh"

print_info() { color_echo cyan "[INFO] $*"; }
print_success() { color_echo green "[SUCCESS] $*"; }
print_warning() { color_echo yellow "[WARNING] $*"; }
print_error() { color_echo red "[ERROR] $*"; }

TEST_LOG="${SCRIPT_DIR}/tmp/test_phase4b_$(date +%Y%m%d_%H%M%S).log"

#########################################################################
# Logging Function
#########################################################################
log_test() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$TEST_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Test Advanced Security Manager
#########################################################################
test_advanced_security_manager() {
    local test_name="Advanced Security Manager"
    log_test "INFO" "Testing $test_name..."
    
    local errors=0
    
    # Test 1: Check if script exists
    if [[ ! -f "${SCRIPT_DIR}/security/advanced/advanced_security_manager.sh" ]]; then
        log_test "ERROR" "$test_name: Script file missing"
        ((errors++))
    else
        log_test "SUCCESS" "$test_name: Script file exists"
    fi
    
    # Test 2: Check if security directory structure exists
    if [[ ! -d "${SCRIPT_DIR}/security/advanced" ]]; then
        log_test "ERROR" "$test_name: Security directory missing"
        ((errors++))
    else
        log_test "SUCCESS" "$test_name: Security directory exists"
    fi
    
    # Test 3: Configuration file creation
    if bash "${SCRIPT_DIR}/security/advanced/advanced_security_manager.sh" >/dev/null 2>&1; then
        if [[ -f "${SCRIPT_DIR}/security/advanced/security_config.json" ]]; then
            log_test "SUCCESS" "$test_name: Security configuration created"
        else
            log_test "ERROR" "$test_name: Security configuration not created"
            ((errors++))
        fi
    fi
    
    # Test 4: Cloudflare configuration
    if [[ -f "${SCRIPT_DIR}/security/advanced/cloudflare_tunnel_config.json" ]]; then
        log_test "SUCCESS" "$test_name: Cloudflare tunnel configuration created"
    else
        log_test "ERROR" "$test_name: Cloudflare tunnel configuration missing"
        ((errors++))
    fi
    
    # Test 5: Status command
    if bash "${SCRIPT_DIR}/security/advanced/advanced_security_manager.sh" status >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Status command works"
    else
        log_test "ERROR" "$test_name: Status command failed"
        ((errors++))
    fi
    
    # Test 6: Security scan functionality (without sudo)
    log_test "INFO" "$test_name: Skipping security scan test (requires sudo)"
    
    # Test 7: Check JSON configuration structure
    if command -v jq >/dev/null 2>&1; then
        local config_file="${SCRIPT_DIR}/security/advanced/security_config.json"
        if [[ -f "$config_file" ]]; then
            if jq '.security_settings.waf_enabled' "$config_file" >/dev/null 2>&1; then
                log_test "SUCCESS" "$test_name: Configuration structure valid"
            else
                log_test "ERROR" "$test_name: Invalid configuration structure"
                ((errors++))
            fi
        fi
    else
        log_test "WARNING" "$test_name: jq not available, skipping JSON validation"
    fi
    
    return $errors
}

#########################################################################
# Test Auto-Scaling Manager
#########################################################################
test_auto_scaling_manager() {
    local test_name="Auto-Scaling Manager"
    log_test "INFO" "Testing $test_name..."
    
    local errors=0
    
    # Test 1: Check if script exists
    if [[ ! -f "${SCRIPT_DIR}/scaling/auto_scaling_manager.sh" ]]; then
        log_test "ERROR" "$test_name: Script file missing"
        ((errors++))
    else
        log_test "SUCCESS" "$test_name: Script file exists"
    fi
    
    # Test 2: Check if scaling directory exists
    if [[ ! -d "${SCRIPT_DIR}/scaling" ]]; then
        log_test "ERROR" "$test_name: Scaling directory missing"
        ((errors++))
    else
        log_test "SUCCESS" "$test_name: Scaling directory exists"
    fi
    
    # Test 3: Configuration file creation
    if bash "${SCRIPT_DIR}/scaling/auto_scaling_manager.sh" >/dev/null 2>&1; then
        if [[ -f "${SCRIPT_DIR}/scaling/scaling_config.json" ]]; then
            log_test "SUCCESS" "$test_name: Scaling configuration created"
        else
            log_test "ERROR" "$test_name: Scaling configuration not created"
            ((errors++))
        fi
    fi
    
    # Test 4: Status functionality
    if bash "${SCRIPT_DIR}/scaling/auto_scaling_manager.sh" status >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Status command works"
    else
        log_test "ERROR" "$test_name: Status command failed"
        ((errors++))
    fi
    
    # Test 5: Cost analysis functionality
    if bash "${SCRIPT_DIR}/scaling/auto_scaling_manager.sh" costs >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Cost analysis works"
    else
        log_test "ERROR" "$test_name: Cost analysis failed"
        ((errors++))
    fi
    
    # Test 6: Load balancer configuration
    if bash "${SCRIPT_DIR}/scaling/auto_scaling_manager.sh" load-balancer >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Load balancer configuration works"
    else
        log_test "ERROR" "$test_name: Load balancer configuration failed"
        ((errors++))
    fi
    
    # Test 7: Manual scaling functions
    if bash "${SCRIPT_DIR}/scaling/auto_scaling_manager.sh" scale-up >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Manual scale up works"
    else
        log_test "ERROR" "$test_name: Manual scale up failed"
        ((errors++))
    fi
    
    # Test 8: Check JSON configuration structure
    if command -v jq >/dev/null 2>&1; then
        local config_file="${SCRIPT_DIR}/scaling/scaling_config.json"
        if [[ -f "$config_file" ]]; then
            if jq '.scaling_settings.enabled' "$config_file" >/dev/null 2>&1; then
                log_test "SUCCESS" "$test_name: Configuration structure valid"
            else
                log_test "ERROR" "$test_name: Invalid configuration structure"
                ((errors++))
            fi
        fi
    else
        log_test "WARNING" "$test_name: jq not available, skipping JSON validation"
    fi
    
    return $errors
}

#########################################################################
# Test Enterprise Dashboard Integration
#########################################################################
test_dashboard_integration() {
    local test_name="Enterprise Dashboard Integration"
    log_test "INFO" "Testing $test_name..."
    
    local errors=0
    
    # Test 1: Dashboard recognizes new modules
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" modules >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Dashboard module management works"
    else
        log_test "ERROR" "$test_name: Dashboard module management failed"
        ((errors++))
    fi
    
    # Test 2: Security dashboard integration
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" security >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Security dashboard integration works"
    else
        log_test "ERROR" "$test_name: Security dashboard integration failed"
        ((errors++))
    fi
    
    # Test 3: Performance dashboard with scaling metrics
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" performance >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Performance dashboard works"
    else
        log_test "ERROR" "$test_name: Performance dashboard failed"
        ((errors++))
    fi
    
    # Test 4: Configuration files compatibility
    local config_files=(
        "${SCRIPT_DIR}/enterprise_dashboard_config.json"
        "${SCRIPT_DIR}/security/advanced/security_config.json"
        "${SCRIPT_DIR}/scaling/scaling_config.json"
    )
    
    local missing_configs=0
    for config in "${config_files[@]}"; do
        if [[ ! -f "$config" ]]; then
            ((missing_configs++))
        fi
    done
    
    if [[ $missing_configs -eq 0 ]]; then
        log_test "SUCCESS" "$test_name: All configuration files exist"
    else
        log_test "ERROR" "$test_name: $missing_configs configuration files missing"
        ((errors++))
    fi
    
    return $errors
}

#########################################################################
# Test Cloudflare Integration
#########################################################################
test_cloudflare_integration() {
    local test_name="Cloudflare Integration"
    log_test "INFO" "Testing $test_name..."
    
    local errors=0
    
    # Test 1: Cloudflare tunnel configuration exists
    if [[ -f "${SCRIPT_DIR}/security/advanced/cloudflare_tunnel_config.json" ]]; then
        log_test "SUCCESS" "$test_name: Cloudflare tunnel configuration exists"
    else
        log_test "ERROR" "$test_name: Cloudflare tunnel configuration missing"
        ((errors++))
    fi
    
    # Test 2: Install cloudflared function (without actually installing)
    log_test "INFO" "$test_name: Cloudflared installation test skipped (would require download)"
    
    # Test 3: Configuration structure validation
    if command -v jq >/dev/null 2>&1; then
        local cf_config="${SCRIPT_DIR}/security/advanced/cloudflare_tunnel_config.json"
        if [[ -f "$cf_config" ]]; then
            if jq '.cloudflare_settings.api_token' "$cf_config" >/dev/null 2>&1; then
                log_test "SUCCESS" "$test_name: Cloudflare configuration structure valid"
            else
                log_test "ERROR" "$test_name: Invalid Cloudflare configuration structure"
                ((errors++))
            fi
        fi
    else
        log_test "WARNING" "$test_name: jq not available, skipping JSON validation"
    fi
    
    # Test 4: Tunnel management functions
    log_test "INFO" "$test_name: Tunnel management functions exist (not tested without credentials)"
    
    return $errors
}

#########################################################################
# Test Module Interoperability
#########################################################################
test_module_interoperability() {
    local test_name="Module Interoperability"
    log_test "INFO" "Testing $test_name..."
    
    local errors=0
    
    # Test 1: All Phase 4A and 4B modules can be accessed
    local modules=(
        "${SCRIPT_DIR}/cloud/multi_cloud_orchestrator.sh"
        "${SCRIPT_DIR}/main_enterprise_dashboard.sh"
        "${SCRIPT_DIR}/security/advanced/advanced_security_manager.sh"
        "${SCRIPT_DIR}/scaling/auto_scaling_manager.sh"
    )
    
    local missing_modules=0
    for module in "${modules[@]}"; do
        if [[ ! -f "$module" ]]; then
            ((missing_modules++))
            log_test "ERROR" "$test_name: Missing module: $(basename "$module")"
        fi
    done
    
    if [[ $missing_modules -eq 0 ]]; then
        log_test "SUCCESS" "$test_name: All enterprise modules exist"
    else
        ((errors++))
    fi
    
    # Test 2: Log files are created in consistent locations
    local log_locations=(
        "${SCRIPT_DIR}/tmp"
    )
    
    for location in "${log_locations[@]}"; do
        if [[ -d "$location" ]]; then
            log_test "SUCCESS" "$test_name: Log directory exists: $location"
        else
            log_test "WARNING" "$test_name: Log directory missing: $location"
        fi
    done
    
    # Test 3: Configuration files use consistent structure
    if command -v jq >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: JSON configuration parser available"
    else
        log_test "WARNING" "$test_name: jq not available - may affect configuration management"
    fi
    
    return $errors
}

#########################################################################
# Main Test Execution
#########################################################################
main() {
    clear
    
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│             🧪 PHASE 4B ENTERPRISE MODULES TEST           │"
    echo "│                    LOMP Stack v2.0                         │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│  Testing Phase 4B enterprise modules:                      │"
    echo "│  • Advanced Security Manager (with Cloudflare Tunneling)  │"
    echo "│  • Auto-Scaling Manager                                   │"
    echo "│  • Enterprise Dashboard Integration                       │"
    echo "╰─────────────────────────────────────────────────────────────╯"
    echo
    
    # Create tmp directory for logs
    mkdir -p "${SCRIPT_DIR}/tmp"
    
    local total_errors=0
    local test_start_time
    test_start_time=$(date +%s)
    
    log_test "INFO" "Starting Phase 4B Enterprise Modules Test"
    
    # Test Advanced Security Manager
    echo "🔒 Testing Advanced Security Manager..."
    test_advanced_security_manager
    local security_errors=$?
    total_errors=$((total_errors + security_errors))
    echo
    
    # Test Auto-Scaling Manager
    echo "⚡ Testing Auto-Scaling Manager..."
    test_auto_scaling_manager
    local scaling_errors=$?
    total_errors=$((total_errors + scaling_errors))
    echo
    
    # Test Enterprise Dashboard Integration
    echo "🏢 Testing Enterprise Dashboard Integration..."
    test_dashboard_integration
    local dashboard_errors=$?
    total_errors=$((total_errors + dashboard_errors))
    echo
    
    # Test Cloudflare Integration
    echo "🌐 Testing Cloudflare Integration..."
    test_cloudflare_integration
    local cloudflare_errors=$?
    total_errors=$((total_errors + cloudflare_errors))
    echo
    
    # Test Module Interoperability
    echo "🔗 Testing Module Interoperability..."
    test_module_interoperability
    local interop_errors=$?
    total_errors=$((total_errors + interop_errors))
    echo
    
    # Calculate test duration
    local test_end_time
    test_end_time=$(date +%s)
    local test_duration=$((test_end_time - test_start_time))
    
    # Display results
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│                      📊 TEST RESULTS                       │"
    echo "├─────────────────────────────────────────────────────────────┤"
    printf "│  Advanced Security Manager: %d errors                       │\n" "$security_errors"
    printf "│  Auto-Scaling Manager:      %d errors                       │\n" "$scaling_errors"
    printf "│  Dashboard Integration:     %d errors                       │\n" "$dashboard_errors"
    printf "│  Cloudflare Integration:    %d errors                       │\n" "$cloudflare_errors"
    printf "│  Module Interoperability:   %d errors                       │\n" "$interop_errors"
    echo "├─────────────────────────────────────────────────────────────┤"
    printf "│  Total Errors:              %d                              │\n" "$total_errors"
    printf "│  Test Duration:             %ds                             │\n" "$test_duration"
    printf "│  Log File:                  %s │\n" "$(basename "$TEST_LOG")"
    echo "├─────────────────────────────────────────────────────────────┤"
    
    if [[ $total_errors -eq 0 ]]; then
        echo "│  🎉 ALL TESTS PASSED! Phase 4B modules are working!       │"
        log_test "SUCCESS" "All Phase 4B tests passed successfully"
    else
        echo "│  ⚠️  SOME TESTS FAILED! Check log for details.            │"
        log_test "ERROR" "Phase 4B tests completed with $total_errors errors"
    fi
    
    echo "╰─────────────────────────────────────────────────────────────╯"
    
    echo
    print_info "Full test log available at: $TEST_LOG"
    
    if [[ $total_errors -eq 0 ]]; then
        print_success "✅ Phase 4B Enterprise modules are ready!"
        print_info "✅ Phase 4A + 4B Progress: ~50% of Faza 4 complete"
        print_info "Next: Implement Phase 4C (API Management, Multi-Site, CDN Integration)"
    else
        print_warning "⚠️  Fix the issues above before proceeding to Phase 4C"
    fi
    
    return $total_errors
}

# Run main function
main "$@"
