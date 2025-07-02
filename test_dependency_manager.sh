#!/bin/bash
#
# test_dependency_manager.sh - Part of LOMP Stack v3.0
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
# test_dependency_manager.sh - Teste pentru dependency manager

# Culori pentru teste
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

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

echo -e "${YELLOW}=== Testing Dependency Manager ===${NC}"
echo

# Test 1: Încărcare dependency manager
echo "Test 1: Loading dependency manager..."
if source "$SCRIPT_DIR/helpers/utils/dependency_manager.sh" 2>/dev/null; then
    print_test_result "Load dependency_manager.sh" "PASS"
else
    print_test_result "Load dependency_manager.sh" "FAIL"
fi

# Test 2: Funcția source_stack_helper există
echo "Test 2: Check if source_stack_helper function exists..."
if declare -f source_stack_helper >/dev/null; then
    print_test_result "source_stack_helper function exists" "PASS"
else
    print_test_result "source_stack_helper function exists" "FAIL"
fi

# Test 3: Source un helper existent
echo "Test 3: Source existing helper..."
if source_stack_helper "utils/functions.sh" >/dev/null 2>&1; then
    print_test_result "Source existing helper (utils/functions.sh)" "PASS"
else
    print_test_result "Source existing helper (utils/functions.sh)" "FAIL"
fi

# Test 4: Source un helper inexistent (ar trebui să eșueze)
echo "Test 4: Source non-existing helper (should fail)..."
if ! source_stack_helper "nonexistent/helper.sh" >/dev/null 2>&1; then
    print_test_result "Source non-existing helper fails correctly" "PASS"
else
    print_test_result "Source non-existing helper fails correctly" "FAIL"
fi

# Test 5: Verificare dependențe multiple
echo "Test 5: Check multiple dependencies..."
if check_required_dependencies "utils/functions.sh" "utils/lang.sh" >/dev/null 2>&1; then
    print_test_result "Check multiple valid dependencies" "PASS"
else
    print_test_result "Check multiple valid dependencies" "FAIL"
fi

# Test 6: Verificare dependențe cu una lipsă
echo "Test 6: Check dependencies with one missing..."
if ! check_required_dependencies "utils/functions.sh" "nonexistent.sh" >/dev/null 2>&1; then
    print_test_result "Check dependencies with missing file fails correctly" "PASS"
else
    print_test_result "Check dependencies with missing file fails correctly" "FAIL"
fi

# Test 7: Inițializare core dependencies
echo "Test 7: Initialize core dependencies..."
if init_core_dependencies >/dev/null 2>&1; then
    print_test_result "Initialize core dependencies" "PASS"
else
    print_test_result "Initialize core dependencies" "FAIL"
fi

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
