#!/bin/bash
#
# test_phase2_modules.sh - Part of LOMP Stack v3.0
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
# test_phase2_modules.sh - Test pentru modulele implementate în Faza 2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

echo -e "${YELLOW}=== TESTARE MODULELOR FAZA 2 ===${NC}"
echo

# Test dependency manager integration
echo -e "${BLUE}--- Testare Dependency Manager Integration ---${NC}"
run_test "State Manager - Source cu dependency manager" \
    "source helpers/utils/state_manager.sh"

run_test "Database Manager - Source cu dependency manager" \
    "source helpers/utils/database_manager.sh"

run_test "UI Manager - Source cu dependency manager" \
    "source helpers/utils/ui_manager.sh"

echo

# Test State Manager functionality
echo -e "${BLUE}--- Testare State Manager ---${NC}"
source helpers/utils/state_manager.sh

run_test "State Manager - Init directories" \
    "init_state_directories"

run_test "State Manager - Set temp variable" \
    "set_state_var 'TEST_VAR' 'test_value' false"

run_test "State Manager - Get temp variable" \
    "test \"\$(get_state_var 'TEST_VAR')\" = 'test_value'"

run_test "State Manager - Set persistent variable" \
    "set_state_var 'PERSISTENT_TEST' 'persistent_value' true"

run_test "State Manager - Get persistent variable" \
    "test \"\$(get_state_var 'PERSISTENT_TEST')\" = 'persistent_value'"

echo

# Test Database Manager functionality
echo -e "${BLUE}--- Testare Database Manager ---${NC}"
source helpers/utils/database_manager.sh

run_test "Database Manager - Detect database type" \
    "detect_database_type >/dev/null"

run_test "Database Manager - Init config" \
    "init_database_config"

run_test "Database Manager - Generate password" \
    "generate_secure_password | grep -q '^[A-Za-z0-9]\\{16\\}$'"

echo

# Test UI Manager functionality  
echo -e "${BLUE}--- Testare UI Manager ---${NC}"
source helpers/utils/ui_manager.sh

run_test "UI Manager - Show header function exists" \
    "declare -f show_header >/dev/null"

run_test "UI Manager - Show progress function exists" \
    "declare -f show_progress >/dev/null"

run_test "UI Manager - Show menu function exists" \
    "declare -f show_menu >/dev/null"

echo

# Test Integration
echo -e "${BLUE}--- Testare Integrare Modulelor ---${NC}"

run_test "Integration - State Manager cu Error Handler" \
    "set_state_var 'ERROR_TEST' 'value' false 2>/dev/null"

run_test "Integration - Database Manager cu State Manager" \
    "detect_database_type && set_state_var 'DB_TYPE' \"\$(detect_database_type)\" false"

run_test "Integration - UI Manager cu Error Handler" \
    "show_header 'Test Header' >/dev/null 2>&1"

echo

# Summary
echo -e "${YELLOW}=== REZULTATE TESTARE ===${NC}"
echo -e "Total teste: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Teste trecute: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Teste eșuate: ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "\n${GREEN}🎉 TOATE TESTELE AU TRECUT! FAZA 2 IMPLEMENTATĂ CU SUCCES!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ UNELE TESTE AU EȘUAT. VERIFICĂ IMPLEMENTAREA.${NC}"
    exit 1
fi
