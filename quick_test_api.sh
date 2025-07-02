#!/bin/bash
#
# quick_test_api.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Quick API Test (Windows Compatible)
# Test API functionality that works on Windows
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers/utils/functions.sh"

print_info() { color_echo cyan "[TEST] $*"; }
print_success() { color_echo green "[PASS] $*"; }
print_error() { color_echo red "[FAIL] $*"; }

#########################################################################
# Test API System Structure
#########################################################################
test_api_structure() {
    print_info "Testing API system structure..."
    
    local tests_passed=0
    local tests_total=8
    
    # Test 1: API directory
    if [ -d "${SCRIPT_DIR}/api" ]; then
        print_success "API directory exists"
        ((tests_passed++))
    else
        print_error "API directory missing"
    fi
    
    # Test 2: Main API script
    if [ -f "${SCRIPT_DIR}/api/api_management_system.sh" ]; then
        print_success "Main API script exists"
        ((tests_passed++))
    else
        print_error "Main API script missing"
    fi
    
    # Test 3: Authentication module
    if [ -f "${SCRIPT_DIR}/api/auth/auth_manager.sh" ]; then
        print_success "Authentication module exists"
        ((tests_passed++))
    else
        print_error "Authentication module missing"
    fi
    
    # Test 4: Webhook module
    if [ -f "${SCRIPT_DIR}/api/webhooks/webhook_manager.sh" ]; then
        print_success "Webhook module exists"
        ((tests_passed++))
    else
        print_error "Webhook module missing"
    fi
    
    # Test 5: API endpoints
    if [ -f "${SCRIPT_DIR}/api/endpoints/sites_api.sh" ]; then
        print_success "API endpoints exist"
        ((tests_passed++))
    else
        print_error "API endpoints missing"
    fi
    
    # Test 6: Python API server
    if [ -f "${SCRIPT_DIR}/api/api_server.py" ]; then
        print_success "Python API server exists"
        ((tests_passed++))
    else
        print_error "Python API server missing"
    fi
    
    # Test 7: Documentation generator
    if [ -f "${SCRIPT_DIR}/api/generate_docs.py" ]; then
        print_success "Documentation generator exists"
        ((tests_passed++))
    else
        print_error "Documentation generator missing"
    fi
    
    # Test 8: Dependencies installer
    if [ -f "${SCRIPT_DIR}/api/install_dependencies.sh" ]; then
        print_success "Dependencies installer exists"
        ((tests_passed++))
    else
        print_error "Dependencies installer missing"
    fi
    
    print_info "Structure tests: $tests_passed/$tests_total passed"
    return $tests_passed
}

#########################################################################
# Test API Configuration
#########################################################################
test_api_configuration() {
    print_info "Testing API configuration..."
    
    local tests_passed=0
    local tests_total=5
    
    # Initialize API if needed
    cd "${SCRIPT_DIR}/api" || return 0
    bash api_management_system.sh init >/dev/null 2>&1
    
    # Test 1: API config file
    if [ -f "api_config.json" ] && jq '.' api_config.json >/dev/null 2>&1; then
        print_success "API configuration is valid JSON"
        ((tests_passed++))
    else
        print_error "API configuration invalid or missing"
    fi
    
    # Test 2: JWT secret
    if [ -f "auth/jwt_secret.key" ] && [ -s "auth/jwt_secret.key" ]; then
        print_success "JWT secret generated"
        ((tests_passed++))
    else
        print_error "JWT secret missing or empty"
    fi
    
    # Test 3: API keys
    if [ -f "auth/api_keys.json" ] && jq '.' auth/api_keys.json >/dev/null 2>&1; then
        print_success "API keys configuration valid"
        ((tests_passed++))
    else
        print_error "API keys configuration invalid"
    fi
    
    # Test 4: Webhook config
    if [ -f "webhooks/webhook_config.json" ] && jq '.' webhooks/webhook_config.json >/dev/null 2>&1; then
        print_success "Webhook configuration valid"
        ((tests_passed++))
    else
        print_error "Webhook configuration invalid"
    fi
    
    # Test 5: Documentation generation
    if python3 generate_docs.py >/dev/null 2>&1 && [ -f "api_documentation.html" ]; then
        print_success "API documentation generated"
        ((tests_passed++))
    else
        print_error "Documentation generation failed"
    fi
    
    print_info "Configuration tests: $tests_passed/$tests_total passed"
    return $tests_passed
}

#########################################################################
# Test API Endpoints (Shell-based)
#########################################################################
test_api_endpoints() {
    print_info "Testing API endpoints..."
    
    local tests_passed=0
    local tests_total=4
    
    cd "${SCRIPT_DIR}/api/endpoints" || return 0
    
    # Test 1: Sites list endpoint
    local list_output
    list_output=$(bash sites_api.sh list 2>/dev/null)
    if echo "$list_output" | grep -q '"success": true'; then
        print_success "Sites list endpoint works"
        ((tests_passed++))
    else
        print_error "Sites list endpoint failed"
    fi
    
    # Test 2: Site creation endpoint
    local create_output
    create_output=$(bash sites_api.sh create "test.example.com" "admin@test.com" 2>/dev/null)
    if echo "$create_output" | grep -q '"success": true'; then
        print_success "Site creation endpoint works"
        ((tests_passed++))
    else
        print_error "Site creation endpoint failed"
    fi
    
    # Test 3: Site get endpoint (expected error for non-existent)
    local get_output
    get_output=$(bash sites_api.sh get "nonexistent.com" 2>/dev/null)
    if echo "$get_output" | grep -q '"error"'; then
        print_success "Site get endpoint works (expected error)"
        ((tests_passed++))
    else
        print_error "Site get endpoint failed"
    fi
    
    # Test 4: Site deletion endpoint
    local delete_output
    delete_output=$(bash sites_api.sh delete "test.example.com" 2>/dev/null)
    if echo "$delete_output" | grep -q '"success": true'; then
        print_success "Site deletion endpoint works"
        ((tests_passed++))
    else
        print_error "Site deletion endpoint failed"
    fi
    
    print_info "Endpoint tests: $tests_passed/$tests_total passed"
    return $tests_passed
}

#########################################################################
# Test Authentication System
#########################################################################
test_authentication() {
    print_info "Testing authentication system..."
    
    local tests_passed=0
    local tests_total=3
    
    cd "${SCRIPT_DIR}/api/auth" || return 0
    
    # Test 1: JWT secret generation
    if bash auth_manager.sh generate-secret >/dev/null 2>&1 && [ -f "jwt_secret.key" ]; then
        print_success "JWT secret generation works"
        ((tests_passed++))
    else
        print_error "JWT secret generation failed"
    fi
    
    # Test 2: API key creation
    local key_output
    key_output=$(bash auth_manager.sh create-key "test-key" "sites:read" "100" 2>/dev/null)
    if echo "$key_output" | grep -q "API Key created"; then
        print_success "API key creation works"
        ((tests_passed++))
    else
        print_error "API key creation failed"
    fi
    
    # Test 3: API key validation (mock)
    local validation_result
    validation_result=$(bash auth_manager.sh validate "invalid-key" 2>/dev/null)
    if [ "$validation_result" = "false" ]; then
        print_success "API key validation works"
        ((tests_passed++))
    else
        print_error "API key validation failed"
    fi
    
    print_info "Authentication tests: $tests_passed/$tests_total passed"
    return $tests_passed
}

#########################################################################
# Test Webhook System
#########################################################################
test_webhooks() {
    print_info "Testing webhook system..."
    
    local tests_passed=0
    local tests_total=3
    
    cd "${SCRIPT_DIR}/api/webhooks" || return 0
    
    # Test 1: Webhook initialization
    if bash webhook_manager.sh init >/dev/null 2>&1; then
        print_success "Webhook initialization works"
        ((tests_passed++))
    else
        print_error "Webhook initialization failed"
    fi
    
    # Test 2: Webhook addition
    local add_output
    add_output=$(bash webhook_manager.sh add "test-webhook" "https://example.com/webhook" "site.created" "secret123" 2>/dev/null)
    if echo "$add_output" | grep -q "Webhook added"; then
        print_success "Webhook addition works"
        ((tests_passed++))
    else
        print_error "Webhook addition failed"
    fi
    
    # Test 3: Webhook sending
    local send_output
    send_output=$(bash webhook_manager.sh send "site.created" '{"domain":"test.com"}' 2>/dev/null)
    if echo "$send_output" | grep -q "Sending webhook"; then
        print_success "Webhook sending works"
        ((tests_passed++))
    else
        print_error "Webhook sending failed"
    fi
    
    print_info "Webhook tests: $tests_passed/$tests_total passed"
    return $tests_passed
}

#########################################################################
# Test Dashboard Integration
#########################################################################
test_dashboard_integration() {
    print_info "Testing dashboard integration..."
    
    local tests_passed=0
    local tests_total=2
    
    # Test 1: Dashboard file exists
    if [ -f "${SCRIPT_DIR}/main_enterprise_dashboard.sh" ]; then
        print_success "Enterprise dashboard exists"
        ((tests_passed++))
    else
        print_error "Enterprise dashboard missing"
    fi
    
    # Test 2: API option in dashboard
    if grep -q "API Management" "${SCRIPT_DIR}/main_enterprise_dashboard.sh" 2>/dev/null; then
        print_success "API Management integrated in dashboard"
        ((tests_passed++))
    else
        print_error "API Management not integrated in dashboard"
    fi
    
    print_info "Dashboard integration tests: $tests_passed/$tests_total passed"
    return $tests_passed
}

#########################################################################
# Main Test Execution
#########################################################################
main() {
    color_echo cyan "🚀 LOMP Stack v2.0 - API Management Quick Test"
    echo "================================================="
    
    local total_passed=0
    local total_tests=0
    
    # Run all test suites
    test_api_structure
    structure_result=$?
    total_passed=$((total_passed + structure_result))
    total_tests=$((total_tests + 8))
    
    test_api_configuration
    config_result=$?
    total_passed=$((total_passed + config_result))
    total_tests=$((total_tests + 5))
    
    test_api_endpoints
    endpoint_result=$?
    total_passed=$((total_passed + endpoint_result))
    total_tests=$((total_tests + 4))
    
    test_authentication
    auth_result=$?
    total_passed=$((total_passed + auth_result))
    total_tests=$((total_tests + 3))
    
    test_webhooks
    webhook_result=$?
    total_passed=$((total_passed + webhook_result))
    total_tests=$((total_tests + 3))
    
    test_dashboard_integration
    dashboard_result=$?
    total_passed=$((total_passed + dashboard_result))
    total_tests=$((total_tests + 2))
    
    echo "================================================="
    color_echo cyan "🏁 Test Summary"
    
    local success_rate=$((total_passed * 100 / total_tests))
    
    echo "Total Tests: $total_tests"
    color_echo green "Passed: $total_passed"
    color_echo red "Failed: $((total_tests - total_passed))"
    color_echo yellow "Success Rate: ${success_rate}%"
    
    if [ $success_rate -ge 90 ]; then
        color_echo green "🎉 Excellent! API Management System is ready for production"
    elif [ $success_rate -ge 80 ]; then
        color_echo yellow "✅ Good! API Management System is functional with minor issues"
    elif [ $success_rate -ge 70 ]; then
        color_echo yellow "⚠️  API Management System needs some attention"
    else
        color_echo red "❌ API Management System needs significant work"
    fi
    
    # Return appropriate exit code
    if [ $success_rate -ge 80 ]; then
        return 0
    else
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
