#!/bin/bash
#
# test_functions.sh - Part of LOMP Stack v3.0
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
# unit/test_functions.sh - Unit tests for helpers/utils/functions.sh

source "$(dirname "$0")/../../utils/functions.sh"

pass=0
fail=0

test_log_info() {
  local test_msg="Test info message"
  log_info "$test_msg"
  grep -q "$test_msg" "$LOG_FILE" && echo "log_info: PASS" && pass=$((pass+1)) || { echo "log_info: FAIL"; fail=$((fail+1)); }
}

test_log_error() {
  local test_msg="Test error message"
  log_error "$test_msg"
  grep -q "$test_msg" "$LOG_FILE" && echo "log_error: PASS" && pass=$((pass+1)) || { echo "log_error: FAIL"; fail=$((fail+1)); }
}

# Run tests
true > "$LOG_FILE"
test_log_info
test_log_error

echo "Tests passed: $pass"
echo "Tests failed: $fail"
exit $fail
