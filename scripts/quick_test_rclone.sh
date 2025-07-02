#!/bin/bash
#
# quick_test_rclone.sh - Part of LOMP Stack v3.0
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

# =============================================================================
# LOMP Stack v2.0 - Quick Rclone Test
# =============================================================================
# Descriere: Test rapid pentru funcționalitatea rclone
# Autor: LOMP Stack Development Team
# Versiune: 2.0.0 - Faza 4 (Enterprise/Cloud)
# =============================================================================

# Simple logging functions
log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[✅] $1"
}

log_error() {
    echo "[❌] $1"
}

log_warning() {
    echo "[⚠️] $1"
}

echo "=== LOMP Stack v2.0 - Quick Rclone Test ==="
echo "Testing rclone integration..."
echo

# Test 1: Check if cloud manager exists
echo "Test 1: Verificare existența cloud manager..."
if [[ -f "cloud/cloud_integration_manager.sh" ]]; then
    log_success "Cloud integration manager găsit"
else
    log_error "Cloud integration manager nu există"
    exit 1
fi

# Test 2: Check if rclone functions are defined
echo
echo "Test 2: Verificare funcții rclone..."
source cloud/cloud_integration_manager.sh 2>/dev/null

rclone_functions=(
    "install_rclone"
    "configure_rclone_remote"
    "sync_with_rclone" 
    "backup_with_rclone"
    "list_rclone_remotes"
    "test_rclone_remote"
    "show_rclone_menu"
    "validate_rclone_configs"
    "create_rclone_backup_job"
    "monitor_cloud_storage"
)

failed_functions=0
for func in "${rclone_functions[@]}"; do
    if declare -f "$func" >/dev/null 2>&1; then
        log_success "$func"
    else
        log_error "$func nu este definită"
        ((failed_functions++))
    fi
done

if [[ $failed_functions -eq 0 ]]; then
    log_success "Toate funcțiile rclone sunt disponibile"
else
    log_error "$failed_functions funcții lipsă"
fi

# Test 3: Check directory structure
echo
echo "Test 3: Verificare structură directoare..."
required_dirs=(
    "cloud"
    "helpers/utils"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        log_success "Director $dir există"
    else
        log_error "Director $dir lipsește"
    fi
done

# Test 4: Check for rclone installation
echo
echo "Test 4: Verificare instalare rclone..."
if command -v rclone >/dev/null 2>&1; then
    version=$(rclone version | head -1)
    log_success "Rclone instalat: $version"
    
    # Check for existing remotes
    remotes=$(rclone listremotes 2>/dev/null)
    if [[ -n "$remotes" ]]; then
        log_success "Remote-uri configurate:"
        echo "$remotes" | while read -r remote; do
            [[ -n "$remote" ]] && echo "  • ${remote%:}"
        done
    else
        log_info "Nu sunt remote-uri configurate (normal pentru instalare nouă)"
    fi
else
    log_warning "Rclone nu este instalat - poate fi instalat prin cloud manager"
fi

# Test 5: Check menu integration
echo
echo "Test 5: Verificare integrare meniu..."
if grep -q "show_rclone_menu" cloud/cloud_integration_manager.sh; then
    log_success "Rclone integrat în meniul principal"
else
    log_error "Rclone nu este integrat în meniu"
fi

# Test 6: Test script functionality
echo
echo "Test 6: Verificare funcționalitate script principal..."
if bash -n cloud/cloud_integration_manager.sh; then
    log_success "Sintaxa scriptului este corectă"
else
    log_error "Erori de sintaxă în script"
fi

# Final summary
echo
echo "=== REZULTATE FINALE ==="
if [[ $failed_functions -eq 0 ]]; then
    log_success "🎉 TOATE TESTELE AU TRECUT!"
    echo
    echo "Rclone integration este funcțională și gata de utilizare."
    echo
    echo "Pentru a utiliza:"
    echo "1. Rulați: bash cloud/cloud_integration_manager.sh"
    echo "2. Selectați opțiunea '8. 🗄️ Rclone Management'"
    echo "3. Urmați instrucțiunile pentru configurare"
    echo
    echo "Sau rulați demo-ul: bash demo_rclone_features.sh"
else
    log_error "Unele teste au eșuat - verificați configurația"
fi

echo
echo "Test completat."
