#!/bin/bash
#
# test_error_handler.sh - Part of LOMP Stack v3.0
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
# test_error_handler.sh - Teste pentru error handler

# Culori pentru teste
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0
TEST_LOG="/tmp/test_error_handler.log"

print_test_result() {
    local test_name="$1"
    local result="$2"
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓ PASS${NC} - $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} - $test_name"
        ((TESTS_FAILED++))
    fi
}

echo -e "${YELLOW}=== Testing Error Handler ===${NC}"
echo

# Setup test environment
export ERROR_LOG="$TEST_LOG"
rm -f "$TEST_LOG"

# Test 1: Încărcare error handler
echo "Test 1: Loading error handler..."
if source "$SCRIPT_DIR/helpers/utils/error_handler.sh" 2>/dev/null; then
    print_test_result "Load error_handler.sh" "PASS"
else
    print_test_result "Load error_handler.sh" "FAIL"
fi

# Test 2: Funcțiile de logging există
echo "Test 2: Check if logging functions exist..."
if declare -f log_info >/dev/null && declare -f log_error >/dev/null && declare -f log_warn >/dev/null; then
    print_test_result "Logging functions exist" "PASS"
else
    print_test_result "Logging functions exist" "FAIL"
fi

# Test 3: Logging la fișier
echo "Test 3: Test logging to file..."
log_info "Test info message"
if grep -q "Test info message" "$TEST_LOG" 2>/dev/null; then
    print_test_result "Log info to file" "PASS"
else
    print_test_result "Log info to file" "FAIL"
fi

# Test 4: Log error
echo "Test 4: Test error logging..."
export STRICT_MODE=0  # Disable strict mode for testing
log_error "Test error message"
if grep -q "Test error message" "$TEST_LOG" 2>/dev/null; then
    print_test_result "Log error to file" "PASS"
else
    print_test_result "Log error to file" "FAIL"
fi

# Test 5: Safe execute cu comandă valabilă
echo "Test 5: Test safe_execute with valid command..."
if safe_execute "Test valid command" echo "test" >/dev/null 2>&1; then
    print_test_result "Safe execute valid command" "PASS"
else
    print_test_result "Safe execute valid command" "FAIL"
fi

# Test 6: Safe execute cu comandă invalidă
echo "Test 6: Test safe_execute with invalid command..."
if ! safe_execute "Test invalid command" false >/dev/null 2>&1; then
    print_test_result "Safe execute invalid command fails correctly" "PASS"
else
    print_test_result "Safe execute invalid command fails correctly" "FAIL"
fi

# Test 7: Assert condition cu condiție adevărată
echo "Test 7: Test assert_condition with true condition..."
if assert_condition "true" "This should pass" >/dev/null 2>&1; then
    print_test_result "Assert true condition" "PASS"
else
    print_test_result "Assert true condition" "FAIL"
fi

# Test 8: Assert condition cu condiție falsă
echo "Test 8: Test assert_condition with false condition..."
if ! assert_condition "false" "This should fail" >/dev/null 2>&1; then
    print_test_result "Assert false condition fails correctly" "PASS"
else
    print_test_result "Assert false condition fails correctly" "FAIL"
fi

# Test 9: Assert exists cu fișier existent
echo "Test 9: Test assert_exists with existing file..."
if assert_exists "/etc/passwd" "file" >/dev/null 2>&1; then
    print_test_result "Assert existing file" "PASS"
else
    print_test_result "Assert existing file" "FAIL"
fi

# Test 10: Assert exists cu fișier inexistent
echo "Test 10: Test assert_exists with non-existing file..."
if ! assert_exists "/nonexistent/file" "file" >/dev/null 2>&1; then
    print_test_result "Assert non-existing file fails correctly" "PASS"
else
    print_test_result "Assert non-existing file fails correctly" "FAIL"
fi

# Test 11: Assert command cu comandă existentă
echo "Test 11: Test assert_command with existing command..."
if assert_command "echo" >/dev/null 2>&1; then
    print_test_result "Assert existing command" "PASS"
else
    print_test_result "Assert existing command" "FAIL"
fi

# Test 12: Assert command cu comandă inexistentă
echo "Test 12: Test assert_command with non-existing command..."
if ! assert_command "nonexistentcommand123" >/dev/null 2>&1; then
    print_test_result "Assert non-existing command fails correctly" "PASS"
else
    print_test_result "Assert non-existing command fails correctly" "FAIL"
fi

# Test 13: Setup error handlers
echo "Test 13: Test setup_error_handlers..."
if setup_error_handlers >/dev/null 2>&1; then
    print_test_result "Setup error handlers" "PASS"
else
    print_test_result "Setup error handlers" "FAIL"
fi

# Cleanup
rm -f "$TEST_LOG"

echo
echo -e "${YELLOW}=== Test Results ===${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
