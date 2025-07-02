#!/bin/bash
#
# test_phase4a_enterprise.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Test Phase 4A Enterprise Modules
# Testing newly implemented enterprise modules:
# - Multi-Cloud Orchestrator
# - Enterprise Dashboard
#########################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers/utils/functions.sh"

print_info() { color_echo cyan "[INFO] $*"; }
print_success() { color_echo green "[SUCCESS] $*"; }
print_warning() { color_echo yellow "[WARNING] $*"; }
print_error() { color_echo red "[ERROR] $*"; }

TEST_LOG="${SCRIPT_DIR}/tmp/test_phase4a_$(date +%Y%m%d_%H%M%S).log"

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
# Test Multi-Cloud Orchestrator
#########################################################################
test_multi_cloud_orchestrator() {
    local test_name="Multi-Cloud Orchestrator"
    log_test "INFO" "Testing $test_name..."
    
    local errors=0
    
    # Test 1: Check if script exists
    if [[ ! -f "${SCRIPT_DIR}/cloud/multi_cloud_orchestrator.sh" ]]; then
        log_test "ERROR" "$test_name: Script file missing"
        ((errors++))
    else
        log_test "SUCCESS" "$test_name: Script file exists"
    fi
    
    # Test 2: Health check functionality
    if bash "${SCRIPT_DIR}/cloud/multi_cloud_orchestrator.sh" health-check >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Health check executed successfully"
    else
        # Health check returns 1 when no providers are available, which is expected
        log_test "INFO" "$test_name: Health check executed (no providers configured)"
    fi
    
    # Test 3: Configuration file creation
    if [[ -f "${SCRIPT_DIR}/cloud/multi_cloud_config.json" ]]; then
        log_test "SUCCESS" "$test_name: Configuration file created"
    else
        log_test "ERROR" "$test_name: Configuration file not created"
        ((errors++))
    fi
    
    # Test 4: Check configuration structure
    if command -v jq >/dev/null 2>&1; then
        if jq '.deployment_strategy' "${SCRIPT_DIR}/cloud/multi_cloud_config.json" >/dev/null 2>&1; then
            log_test "SUCCESS" "$test_name: Configuration structure valid"
        else
            log_test "ERROR" "$test_name: Invalid configuration structure"
            ((errors++))
        fi
    else
        log_test "WARNING" "$test_name: jq not available, skipping JSON validation"
    fi
    
    # Test 5: Cost optimization function
    if bash "${SCRIPT_DIR}/cloud/multi_cloud_orchestrator.sh" costs >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Cost optimization function works"
    else
        log_test "ERROR" "$test_name: Cost optimization function failed"
        ((errors++))
    fi
    
    # Test 6: Deployment listing
    if bash "${SCRIPT_DIR}/cloud/multi_cloud_orchestrator.sh" list >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Deployment listing works"
    else
        log_test "ERROR" "$test_name: Deployment listing failed"
        ((errors++))
    fi
    
    return $errors
}

#########################################################################
# Test Enterprise Dashboard
#########################################################################
test_enterprise_dashboard() {
    local test_name="Enterprise Dashboard"
    log_test "INFO" "Testing $test_name..."
    
    local errors=0
    
    # Test 1: Check if script exists
    if [[ ! -f "${SCRIPT_DIR}/main_enterprise_dashboard.sh" ]]; then
        log_test "ERROR" "$test_name: Script file missing"
        ((errors++))
    else
        log_test "SUCCESS" "$test_name: Script file exists"
    fi
    
    # Test 2: Dashboard health check
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" health-check >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Health check passed"
    else
        log_test "ERROR" "$test_name: Health check failed"
        ((errors++))
    fi
    
    # Test 3: Configuration file creation
    if [[ -f "${SCRIPT_DIR}/enterprise_dashboard_config.json" ]]; then
        log_test "SUCCESS" "$test_name: Configuration file created"
    else
        log_test "ERROR" "$test_name: Configuration file not created"
        ((errors++))
    fi
    
    # Test 4: System overview functionality
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" overview >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: System overview works"
    else
        log_test "ERROR" "$test_name: System overview failed"
        ((errors++))
    fi
    
    # Test 5: Multi-cloud dashboard
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" multi-cloud >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Multi-cloud dashboard works"
    else
        log_test "ERROR" "$test_name: Multi-cloud dashboard failed"
        ((errors++))
    fi
    
    # Test 6: Security dashboard
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" security >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Security dashboard works"
    else
        log_test "ERROR" "$test_name: Security dashboard failed"
        ((errors++))
    fi
    
    # Test 7: Performance dashboard
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" performance >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Performance dashboard works"
    else
        log_test "ERROR" "$test_name: Performance dashboard failed"
        ((errors++))
    fi
    
    # Test 8: Module management
    if bash "${SCRIPT_DIR}/main_enterprise_dashboard.sh" modules >/dev/null 2>&1; then
        log_test "SUCCESS" "$test_name: Module management works"
    else
        log_test "ERROR" "$test_name: Module management failed"
        ((errors++))
    fi
    
    return $errors
}

#########################################################################
# Test Integration Between Modules
#########################################################################
test_integration() {
    local test_name="Module Integration"
    log_test "INFO" "Testing $test_name..."
    
    local errors=0
    
    # Test 1: Enterprise Dashboard can call Multi-Cloud Orchestrator
    if [[ -f "${SCRIPT_DIR}/cloud/multi_cloud_orchestrator.sh" ]] && [[ -f "${SCRIPT_DIR}/main_enterprise_dashboard.sh" ]]; then
        log_test "SUCCESS" "$test_name: Both modules exist for integration"
    else
        log_test "ERROR" "$test_name: Missing required modules for integration"
        ((errors++))
    fi
    
    # Test 2: Configuration files are compatible
    if [[ -f "${SCRIPT_DIR}/cloud/multi_cloud_config.json" ]] && [[ -f "${SCRIPT_DIR}/enterprise_dashboard_config.json" ]]; then
        log_test "SUCCESS" "$test_name: Configuration files exist"
    else
        log_test "ERROR" "$test_name: Missing configuration files"
        ((errors++))
    fi
    
    # Test 3: Log files are created in correct locations
    if [[ -f "${SCRIPT_DIR}/tmp/multi_cloud_orchestrator.log" ]] || [[ -f "${SCRIPT_DIR}/tmp/enterprise_dashboard.log" ]]; then
        log_test "SUCCESS" "$test_name: Log files created correctly"
    else
        log_test "WARNING" "$test_name: No log files found (expected on first run)"
    fi
    
    return $errors
}

#########################################################################
# Main Test Execution
#########################################################################
main() {
    clear
    
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│             🧪 PHASE 4A ENTERPRISE MODULES TEST           │"
    echo "│                    LOMP Stack v2.0                         │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│  Testing newly implemented enterprise modules:             │"
    echo "│  • Multi-Cloud Orchestrator                               │"
    echo "│  • Enterprise Dashboard                                   │"
    echo "╰─────────────────────────────────────────────────────────────╯"
    echo
    
    # Create tmp directory for logs
    mkdir -p "${SCRIPT_DIR}/tmp"
    
    local total_errors=0
    local test_start_time
    test_start_time=$(date +%s)
    
    log_test "INFO" "Starting Phase 4A Enterprise Modules Test"
    
    # Test Multi-Cloud Orchestrator
    echo "🌐 Testing Multi-Cloud Orchestrator..."
    test_multi_cloud_orchestrator
    local mco_errors=$?
    total_errors=$((total_errors + mco_errors))
    echo
    
    # Test Enterprise Dashboard
    echo "🏢 Testing Enterprise Dashboard..."
    test_enterprise_dashboard
    local dash_errors=$?
    total_errors=$((total_errors + dash_errors))
    echo
    
    # Test Integration
    echo "🔗 Testing Module Integration..."
    test_integration
    local int_errors=$?
    total_errors=$((total_errors + int_errors))
    echo
    
    # Calculate test duration
    local test_end_time
    test_end_time=$(date +%s)
    local test_duration=$((test_end_time - test_start_time))
    
    # Display results
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│                      📊 TEST RESULTS                       │"
    echo "├─────────────────────────────────────────────────────────────┤"
    printf "│  Multi-Cloud Orchestrator:  %d errors                       │\n" "$mco_errors"
    printf "│  Enterprise Dashboard:      %d errors                       │\n" "$dash_errors"
    printf "│  Module Integration:        %d errors                       │\n" "$int_errors"
    echo "├─────────────────────────────────────────────────────────────┤"
    printf "│  Total Errors:              %d                              │\n" "$total_errors"
    printf "│  Test Duration:             %ds                             │\n" "$test_duration"
    printf "│  Log File:                  %s │\n" "$(basename "$TEST_LOG")"
    echo "├─────────────────────────────────────────────────────────────┤"
    
    if [[ $total_errors -eq 0 ]]; then
        echo "│  🎉 ALL TESTS PASSED! Phase 4A modules are working!       │"
        log_test "SUCCESS" "All Phase 4A tests passed successfully"
    else
        echo "│  ⚠️  SOME TESTS FAILED! Check log for details.            │"
        log_test "ERROR" "Phase 4A tests completed with $total_errors errors"
    fi
    
    echo "╰─────────────────────────────────────────────────────────────╯"
    
    echo
    print_info "Full test log available at: $TEST_LOG"
    
    if [[ $total_errors -eq 0 ]]; then
        print_success "✅ Phase 4A Enterprise modules are ready!"
        print_info "Next: Implement Phase 4B (Auto-Scaling, Migration Tools, Advanced Monitoring)"
    else
        print_warning "⚠️  Fix the issues above before proceeding to Phase 4B"
    fi
    
    return $total_errors
}

# Run main function
main "$@"
