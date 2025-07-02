#!/bin/bash
#==============================================================================
# LOMP Stack v3.0 - Core Dependencies Checker (Wrapper)
# 
# Wrapper for check_core_dependencies_enhanced.sh with --ultra
# 
# Author: Silviu Ilie
# Email: neosilviu@gmail.com
# Company: aemdPC
# License: MIT
# Version: 3.0
# 
# Description: Simple wrapper script that calls the enhanced core dependencies
# checker with ultra mode enabled for comprehensive dependency validation.
#==============================================================================

# shellcheck shell=bash
# Wrapper pentru check_core_dependencies_enhanced.sh cu --ultra

bash "$(dirname "$0")/check_core_dependencies_enhanced.sh" --ultra
