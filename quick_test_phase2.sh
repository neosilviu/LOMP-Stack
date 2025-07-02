#!/bin/bash
#
# quick_test_phase2.sh - Part of LOMP Stack v3.0
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
# quick_test_phase2.sh - Test rapid pentru modulele din Faza 2

echo "=== QUICK TEST FAZA 2 ==="
echo

echo "Testing State Manager..."
source helpers/utils/state_manager.sh
set_state_var "TEST_VAR" "test123" false
result=$(get_state_var "TEST_VAR")
if [[ "$result" == "test123" ]]; then
    echo "✓ State Manager: PASS"
else
    echo "✗ State Manager: FAIL"
fi

echo "Testing Database Manager..."
source helpers/utils/database_manager.sh
db_type=$(detect_database_type)
echo "✓ Database Manager: Detected type: $db_type"

echo "Testing UI Manager..."
source helpers/utils/ui_manager.sh
if declare -f show_header >/dev/null; then
    echo "✓ UI Manager: Functions available"
else
    echo "✗ UI Manager: Functions missing"
fi

echo
echo "=== FAZA 2 INTEGRATION TEST COMPLETE ==="
