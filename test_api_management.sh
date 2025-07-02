#!/bin/bash
#
# test_api_management.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - API Management System Test Script
# Comprehensive testing for API Management System
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers/utils/functions.sh"

# Test configuration
TEST_LOG="${SCRIPT_DIR}/tmp/test_api_management.log"
API_BASE_URL="http://localhost:8080/api/v1"

# Test results counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

#########################################################################
# Test Functions
#########################################################################

# Test result tracking
test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ "$result" = "PASS" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        color_echo green "✓ $test_name: PASS - $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        color_echo red "✗ $test_name: FAIL - $message"
    fi
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $test_name: $result - $message" >> "$TEST_LOG"
}

#########################################################################
# Test API System Initialization
#########################################################################
test_api_initialization() {
    color_echo cyan "🧪 Testing API System Initialization..."
    
    # Test 1: Check if API directory exists
    if [ -d "${SCRIPT_DIR}/api" ]; then
        test_result "API Directory" "PASS" "API directory exists"
    else
        test_result "API Directory" "FAIL" "API directory not found"
    fi
    
    # Test 2: Check if main API script exists
    if [ -f "${SCRIPT_DIR}/api/api_management_system.sh" ]; then
        test_result "API Main Script" "PASS" "Main API script exists"
    else
        test_result "API Main Script" "FAIL" "Main API script not found"
    fi
    
    # Test 3: Check if API server script exists
    if [ -f "${SCRIPT_DIR}/api/api_server.py" ]; then
        test_result "API Server Script" "PASS" "API server script exists"
    else
        test_result "API Server Script" "FAIL" "API server script not found"
    fi
    
    # Test 4: Check if authentication module exists
    if [ -f "${SCRIPT_DIR}/api/auth/auth_manager.sh" ]; then
        test_result "Auth Module" "PASS" "Authentication module exists"
    else
        test_result "Auth Module" "FAIL" "Authentication module not found"
    fi
    
    # Test 5: Check if webhook module exists
    if [ -f "${SCRIPT_DIR}/api/webhooks/webhook_manager.sh" ]; then
        test_result "Webhook Module" "PASS" "Webhook module exists"
    else
        test_result "Webhook Module" "FAIL" "Webhook module not found"
    fi
}

#########################################################################
# Test API Dependencies
#########################################################################
test_api_dependencies() {
    color_echo cyan "🔧 Testing API Dependencies..."
    
    # Test 1: Check Python3
    if command -v python3 &> /dev/null; then
        test_result "Python3" "PASS" "Python3 is installed"
    else
        test_result "Python3" "FAIL" "Python3 not found"
    fi
    
    # Test 2: Check pip3
    if command -v pip3 &> /dev/null; then
        test_result "Pip3" "PASS" "Pip3 is installed"
    else
        test_result "Pip3" "FAIL" "Pip3 not found"
    fi
    
    # Test 3: Check Node.js
    if command -v node &> /dev/null; then
        test_result "Node.js" "PASS" "Node.js is installed"
    else
        test_result "Node.js" "FAIL" "Node.js not found"
    fi
    
    # Test 4: Check curl
    if command -v curl &> /dev/null; then
        test_result "cURL" "PASS" "cURL is installed"
    else
        test_result "cURL" "FAIL" "cURL not found"
    fi
    
    # Test 5: Check jq
    if command -v jq &> /dev/null; then
        test_result "jq" "PASS" "jq is installed"
    else
        test_result "jq" "FAIL" "jq not found"
    fi
}

#########################################################################
# Test API Configuration
#########################################################################
test_api_configuration() {
    color_echo cyan "⚙️ Testing API Configuration..."
    
    # Initialize API system for testing
    cd "${SCRIPT_DIR}/api" || return 1
    bash api_management_system.sh init >/dev/null 2>&1
    
    # Test 1: Check API configuration file
    if [ -f "${SCRIPT_DIR}/api/api_config.json" ]; then
        test_result "API Config" "PASS" "API configuration file exists"
    else
        test_result "API Config" "FAIL" "API configuration file not found"
    fi
    
    # Test 2: Check JWT secret file
    if [ -f "${SCRIPT_DIR}/api/auth/jwt_secret.key" ]; then
        test_result "JWT Secret" "PASS" "JWT secret file exists"
    else
        test_result "JWT Secret" "FAIL" "JWT secret file not found"
    fi
    
    # Test 3: Check API keys file
    if [ -f "${SCRIPT_DIR}/api/auth/api_keys.json" ]; then
        test_result "API Keys" "PASS" "API keys file exists"
    else
        test_result "API Keys" "FAIL" "API keys file not found"
    fi
    
    # Test 4: Check webhook configuration
    if [ -f "${SCRIPT_DIR}/api/webhooks/webhook_config.json" ]; then
        test_result "Webhook Config" "PASS" "Webhook configuration exists"
    else
        test_result "Webhook Config" "FAIL" "Webhook configuration not found"
    fi
    
    # Test 5: Validate JSON configuration files
    if jq '.' "${SCRIPT_DIR}/api/api_config.json" >/dev/null 2>&1; then
        test_result "JSON Validation" "PASS" "API configuration is valid JSON"
    else
        test_result "JSON Validation" "FAIL" "API configuration is invalid JSON"
    fi
}

#########################################################################
# Test API Authentication
#########################################################################
test_api_authentication() {
    color_echo cyan "🔐 Testing API Authentication..."
    
    cd "${SCRIPT_DIR}/api/auth" || return 1
    
    # Test 1: Generate JWT secret
    if bash auth_manager.sh generate-secret >/dev/null 2>&1; then
        test_result "JWT Generation" "PASS" "JWT secret generated successfully"
    else
        test_result "JWT Generation" "FAIL" "Failed to generate JWT secret"
    fi
    
    # Test 2: Create API key
    local api_key_output
    api_key_output=$(bash auth_manager.sh create-key "test-key" "sites:read" "100" 2>/dev/null)
    if echo "$api_key_output" | grep -q "API Key created"; then
        test_result "API Key Creation" "PASS" "API key created successfully"
    else
        test_result "API Key Creation" "FAIL" "Failed to create API key"
    fi
    
    # Test 3: Validate API key (mock test)
    local validation_result
    validation_result=$(bash auth_manager.sh validate "dummy-key" 2>/dev/null)
    if [ "$validation_result" = "false" ]; then
        test_result "API Key Validation" "PASS" "API key validation works"
    else
        test_result "API Key Validation" "FAIL" "API key validation failed"
    fi
}

#########################################################################
# Test Webhook System
#########################################################################
test_webhook_system() {
    color_echo cyan "🕸️ Testing Webhook System..."
    
    cd "${SCRIPT_DIR}/api/webhooks" || return 1
    
    # Test 1: Initialize webhook configuration
    if bash webhook_manager.sh init >/dev/null 2>&1; then
        test_result "Webhook Init" "PASS" "Webhook system initialized"
    else
        test_result "Webhook Init" "FAIL" "Failed to initialize webhook system"
    fi
    
    # Test 2: Add webhook endpoint
    local webhook_output
    webhook_output=$(bash webhook_manager.sh add "test-webhook" "https://example.com/webhook" "site.created" "secret123" 2>/dev/null)
    if echo "$webhook_output" | grep -q "Webhook added"; then
        test_result "Webhook Add" "PASS" "Webhook endpoint added successfully"
    else
        test_result "Webhook Add" "FAIL" "Failed to add webhook endpoint"
    fi
    
    # Test 3: Send webhook
    local send_output
    send_output=$(bash webhook_manager.sh send "site.created" '{"domain":"test.com"}' 2>/dev/null)
    if echo "$send_output" | grep -q "Sending webhook"; then
        test_result "Webhook Send" "PASS" "Webhook sent successfully"
    else
        test_result "Webhook Send" "FAIL" "Failed to send webhook"
    fi
    
    # Test 4: List webhooks
    local list_output
    list_output=$(bash webhook_manager.sh list 2>/dev/null)
    if [ -n "$list_output" ]; then
        test_result "Webhook List" "PASS" "Webhook listing works"
    else
        test_result "Webhook List" "FAIL" "Failed to list webhooks"
    fi
}

#########################################################################
# Test API Endpoints
#########################################################################
test_api_endpoints() {
    color_echo cyan "🌐 Testing API Endpoints..."
    
    cd "${SCRIPT_DIR}/api/endpoints" || return 1
    
    # Test 1: List sites endpoint
    local sites_output
    sites_output=$(bash sites_api.sh list 2>/dev/null)
    if echo "$sites_output" | grep -q '"success": true'; then
        test_result "Sites List API" "PASS" "Sites list endpoint works"
    else
        test_result "Sites List API" "FAIL" "Sites list endpoint failed"
    fi
    
    # Test 2: Get site endpoint
    local site_output
    site_output=$(bash sites_api.sh get "test.com" 2>/dev/null)
    if echo "$site_output" | grep -q '"error"'; then
        test_result "Site Get API" "PASS" "Site get endpoint works (expected error for non-existent site)"
    else
        test_result "Site Get API" "FAIL" "Site get endpoint failed"
    fi
    
    # Test 3: Create site endpoint
    local create_output
    create_output=$(bash sites_api.sh create "test.com" "admin@test.com" 2>/dev/null)
    if echo "$create_output" | grep -q '"success": true'; then
        test_result "Site Create API" "PASS" "Site create endpoint works"
    else
        test_result "Site Create API" "FAIL" "Site create endpoint failed"
    fi
    
    # Test 4: Delete site endpoint
    local delete_output
    delete_output=$(bash sites_api.sh delete "test.com" 2>/dev/null)
    if echo "$delete_output" | grep -q '"success": true'; then
        test_result "Site Delete API" "PASS" "Site delete endpoint works"
    else
        test_result "Site Delete API" "FAIL" "Site delete endpoint failed"
    fi
}

#########################################################################
# Test API Server Health
#########################################################################
test_api_server_health() {
    color_echo cyan "❤️ Testing API Server Health..."
    
    # Test 1: Check if PM2 is available
    if command -v pm2 &> /dev/null; then
        test_result "PM2 Available" "PASS" "PM2 process manager is available"
    else
        test_result "PM2 Available" "FAIL" "PM2 process manager not found"
        return
    fi
    
    # Test 2: Start API server (if not running)
    cd "${SCRIPT_DIR}/api" || return 1
    local server_status
    server_status=$(pm2 list | grep lomp-api | awk '{print $10}' 2>/dev/null)
    
    if [ "$server_status" = "online" ]; then
        test_result "API Server Status" "PASS" "API server is running"
    else
        # Try to start the server
        bash api_management_system.sh start >/dev/null 2>&1
        sleep 3
        server_status=$(pm2 list | grep lomp-api | awk '{print $10}' 2>/dev/null)
        
        if [ "$server_status" = "online" ]; then
            test_result "API Server Start" "PASS" "API server started successfully"
        else
            test_result "API Server Start" "FAIL" "Failed to start API server"
        fi
    fi
    
    # Test 3: Health check endpoint (if server is running)
    if [ "$server_status" = "online" ]; then
        local health_response
        health_response=$(curl -s "$API_BASE_URL/health" 2>/dev/null)
        
        if echo "$health_response" | grep -q '"status": "healthy"'; then
            test_result "Health Endpoint" "PASS" "Health endpoint responds correctly"
        else
            test_result "Health Endpoint" "FAIL" "Health endpoint not responding"
        fi
        
        # Test 4: System status endpoint
        local status_response
        status_response=$(curl -s "$API_BASE_URL/system/status" 2>/dev/null)
        
        if echo "$status_response" | grep -q '"success": true'; then
            test_result "System Status" "PASS" "System status endpoint works"
        else
            test_result "System Status" "FAIL" "System status endpoint failed"
        fi
    fi
}

#########################################################################
# Test API Performance
#########################################################################
test_api_performance() {
    color_echo cyan "⚡ Testing API Performance..."
    
    # Test 1: Response time for health endpoint
    local start_time
    local end_time
    local response_time
    
    start_time=$(date +%s%N)
    curl -s "$API_BASE_URL/health" >/dev/null 2>&1
    end_time=$(date +%s%N)
    
    response_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    if [ "$response_time" -lt 1000 ]; then
        test_result "Response Time" "PASS" "Health endpoint responds in ${response_time}ms"
    else
        test_result "Response Time" "FAIL" "Health endpoint slow: ${response_time}ms"
    fi
    
    # Test 2: Multiple concurrent requests
    local concurrent_success=true
    for i in {1..5}; do
        curl -s "$API_BASE_URL/health" >/dev/null 2>&1 &
    done
    wait
    
    if [ "$concurrent_success" = true ]; then
        test_result "Concurrent Requests" "PASS" "Multiple concurrent requests handled"
    else
        test_result "Concurrent Requests" "FAIL" "Failed to handle concurrent requests"
    fi
}

#########################################################################
# Test API Documentation
#########################################################################
test_api_documentation() {
    color_echo cyan "📚 Testing API Documentation..."
    
    cd "${SCRIPT_DIR}/api" || return 1
    
    # Test 1: Generate documentation
    if python3 generate_docs.py >/dev/null 2>&1; then
        test_result "Doc Generation" "PASS" "API documentation generated"
    else
        test_result "Doc Generation" "FAIL" "Failed to generate documentation"
    fi
    
    # Test 2: Check if documentation file exists
    if [ -f "${SCRIPT_DIR}/api/api_documentation.html" ]; then
        test_result "Doc File" "PASS" "Documentation file exists"
    else
        test_result "Doc File" "FAIL" "Documentation file not found"
    fi
    
    # Test 3: Validate HTML content
    if grep -q "LOMP Stack API" "${SCRIPT_DIR}/api/api_documentation.html" 2>/dev/null; then
        test_result "Doc Content" "PASS" "Documentation content is valid"
    else
        test_result "Doc Content" "FAIL" "Documentation content is invalid"
    fi
}

#########################################################################
# Test Integration with Main Dashboard
#########################################################################
test_dashboard_integration() {
    color_echo cyan "🏢 Testing Dashboard Integration..."
    
    # Test 1: Check if main dashboard exists
    if [ -f "${SCRIPT_DIR}/main_enterprise_dashboard.sh" ]; then
        test_result "Dashboard Exists" "PASS" "Main dashboard file exists"
    else
        test_result "Dashboard Exists" "FAIL" "Main dashboard file not found"
    fi
    
    # Test 2: Check if API option is in dashboard menu
    if grep -q "API Management" "${SCRIPT_DIR}/main_enterprise_dashboard.sh" 2>/dev/null; then
        test_result "Dashboard Menu" "PASS" "API Management option in dashboard menu"
    else
        test_result "Dashboard Menu" "FAIL" "API Management option not in dashboard menu"
    fi
}

#########################################################################
# Generate Test Report
#########################################################################
generate_test_report() {
    local report_file="${SCRIPT_DIR}/tmp/api_management_test_report.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>API Management System Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .summary { background: #ecf0f1; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .pass { color: #27ae60; font-weight: bold; }
        .fail { color: #e74c3c; font-weight: bold; }
        .test-results { margin: 20px 0; }
        .test-item { padding: 5px 0; border-bottom: 1px solid #ddd; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔌 API Management System Test Report</h1>
        <p>Generated on: $(date +'%Y-%m-%d %H:%M:%S')</p>
    </div>
    
    <div class="summary">
        <h2>📊 Test Summary</h2>
        <p><strong>Total Tests:</strong> $TESTS_TOTAL</p>
        <p><strong class="pass">Passed:</strong> $TESTS_PASSED</p>
        <p><strong class="fail">Failed:</strong> $TESTS_FAILED</p>
        <p><strong>Success Rate:</strong> $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%</p>
    </div>
    
    <div class="test-results">
        <h2>📋 Detailed Results</h2>
EOF
    
    if [ -f "$TEST_LOG" ]; then
        while IFS= read -r line; do
            if echo "$line" | grep -q "PASS"; then
                echo "        <div class=\"test-item pass\">✓ $line</div>" >> "$report_file"
            else
                echo "        <div class=\"test-item fail\">✗ $line</div>" >> "$report_file"
            fi
        done < "$TEST_LOG"
    fi
    
    cat >> "$report_file" << EOF
    </div>
</body>
</html>
EOF
    
    color_echo green "Test report generated: $report_file"
}

#########################################################################
# Main Test Execution
#########################################################################
main() {
    color_echo cyan "🧪 Starting API Management System Tests..."
    echo "======================================================="
    
    # Create log directory
    mkdir -p "${SCRIPT_DIR}/tmp"
    
    # Clear previous test log
    > "$TEST_LOG"
    
    # Run all test suites
    test_api_initialization
    test_api_dependencies
    test_api_configuration
    test_api_authentication
    test_webhook_system
    test_api_endpoints
    test_api_server_health
    test_api_performance
    test_api_documentation
    test_dashboard_integration
    
    echo "======================================================="
    color_echo cyan "🏁 Test Execution Complete"
    
    # Display summary
    echo ""
    color_echo yellow "📊 TEST SUMMARY:"
    echo "Total Tests: $TESTS_TOTAL"
    color_echo green "Passed: $TESTS_PASSED"
    color_echo red "Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        color_echo green "🎉 ALL TESTS PASSED!"
    else
        color_echo yellow "⚠️  Some tests failed. Check the log for details."
    fi
    
    # Generate HTML report
    generate_test_report
    
    # Return appropriate exit code
    if [ $TESTS_FAILED -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
