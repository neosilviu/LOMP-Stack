#!/bin/bash
#
# quick_test_phase3.sh - Part of LOMP Stack v3.0
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
# quick_test_phase3.sh - Test rapid pentru modulele Fazei 3

set -e

# Detectează locația scriptului
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Test rapid Faza 3 - LOMP Stack v2.0"
echo "======================================="

# Test 1: Performance Manager
echo "📊 Test Performance Manager..."
if source "$SCRIPT_DIR/helpers/utils/performance_manager.sh" 2>/dev/null; then
    echo "✓ Performance Manager încărcat cu succes"
    if declare -f run_full_optimization >/dev/null; then
        echo "✓ Funcții performance disponibile"
    fi
else
    echo "✗ Eroare la încărcarea Performance Manager"
fi

# Test 2: Monitoring Manager
echo "📈 Test Monitoring Manager..."
if source "$SCRIPT_DIR/helpers/utils/monitoring_manager.sh" 2>/dev/null; then
    echo "✓ Monitoring Manager încărcat cu succes"
    if declare -f collect_system_metrics >/dev/null; then
        echo "✓ Funcții monitoring disponibile"
    fi
else
    echo "✗ Eroare la încărcarea Monitoring Manager"
fi

# Test 3: Backup Recovery Manager
echo "💾 Test Backup Recovery Manager..."
if source "$SCRIPT_DIR/helpers/utils/backup_recovery_manager.sh" 2>/dev/null; then
    echo "✓ Backup Recovery Manager încărcat cu succes"
    if declare -f execute_full_backup >/dev/null; then
        echo "✓ Funcții backup disponibile"
    fi
else
    echo "✗ Eroare la încărcarea Backup Recovery Manager"
fi

# Test 4: UI/UX Manager
echo "🎨 Test UI/UX Manager..."
if source "$SCRIPT_DIR/helpers/utils/ui_ux_manager.sh" 2>/dev/null; then
    echo "✓ UI/UX Manager încărcat cu succes"
    if declare -f show_advanced_header >/dev/null; then
        echo "✓ Funcții UI/UX disponibile"
    fi
else
    echo "✗ Eroare la încărcarea UI/UX Manager"
fi

echo
echo "🎉 Test rapid completat!"
echo "Pentru teste detaliate, rulați: bash test_phase3_modules.sh"
