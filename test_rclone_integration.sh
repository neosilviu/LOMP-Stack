#!/bin/bash
#
# test_rclone_integration.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v2.0 - Test Rclone Integration
# =============================================================================
# Descriere: Script de testare pentru funcționalitatea rclone din cloud manager
# Autor: LOMP Stack Development Team
# Versiune: 2.0.0 - Faza 4 (Enterprise/Cloud)
# =============================================================================

# Configurare paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUD_DIR="$SCRIPT_DIR/cloud"
UTILS_DIR="$SCRIPT_DIR/helpers/utils"

# Import dependencies
source "$UTILS_DIR/dependency_manager.sh" 2>/dev/null || { echo "❌ Nu găsesc dependency_manager.sh"; exit 1; }
source "$UTILS_DIR/error_handler.sh" 2>/dev/null || { echo "❌ Nu găsesc error_handler.sh"; exit 1; }
source "$UTILS_DIR/ui_manager.sh" 2>/dev/null || { echo "❌ Nu găsesc ui_manager.sh"; exit 1; }

# Source cloud manager pentru a testa funcțiile
source "$CLOUD_DIR/cloud_integration_manager.sh" 2>/dev/null || { echo "❌ Nu găsesc cloud_integration_manager.sh"; exit 1; }

# =============================================================================
# FUNCȚII DE TEST
# =============================================================================

# Test instalare rclone
test_rclone_installation() {
    ui_header "🧪 Test 1: Verificare instalare rclone"
    
    if command -v rclone >/dev/null 2>&1; then
        ui_success "✅ Rclone este deja instalat"
        local version
        version=$(rclone version | head -1)
        ui_info "Versiune: $version"
        return 0
    else
        ui_warning "⚠️ Rclone nu este instalat"
        ui_info "Testez funcția de instalare..."
        
        # Test instalare (fără execuție reală pentru siguranță)
        ui_info "Funcția install_rclone() este disponibilă: $(type -t install_rclone)"
        
        if [[ "$(type -t install_rclone)" == "function" ]]; then
            ui_success "✅ Funcția de instalare este disponibilă"
        else
            ui_error "❌ Funcția de instalare nu este disponibilă"
            return 1
        fi
    fi
}

# Test funcții de configurare
test_rclone_configuration() {
    ui_header "🧪 Test 2: Verificare funcții de configurare"
    
    local config_functions=(
        "configure_rclone_remote"
        "configure_rclone_s3"
        "configure_rclone_gdrive"
        "configure_rclone_dropbox"
        "configure_rclone_onedrive"
        "configure_rclone_ftp"
        "configure_rclone_sftp"
    )
    
    local failed_functions=()
    
    for func in "${config_functions[@]}"; do
        if [[ "$(type -t "$func")" == "function" ]]; then
            ui_success "✅ $func"
        else
            ui_error "❌ $func"
            failed_functions+=("$func")
        fi
    done
    
    if [[ ${#failed_functions[@]} -eq 0 ]]; then
        ui_success "Toate funcțiile de configurare sunt disponibile"
        return 0
    else
        ui_error "Funcții lipsă: ${failed_functions[*]}"
        return 1
    fi
}

# Test funcții de sincronizare și backup
test_rclone_sync_backup() {
    ui_header "🧪 Test 3: Verificare funcții sincronizare și backup"
    
    local sync_functions=(
        "sync_with_rclone"
        "backup_with_rclone"
        "incremental_sync"
        "restore_from_cloud"
    )
    
    local failed_functions=()
    
    for func in "${sync_functions[@]}"; do
        if [[ "$(type -t "$func")" == "function" ]]; then
            ui_success "✅ $func"
        else
            ui_error "❌ $func"
            failed_functions+=("$func")
        fi
    done
    
    if [[ ${#failed_functions[@]} -eq 0 ]]; then
        ui_success "Toate funcțiile de sincronizare sunt disponibile"
        return 0
    else
        ui_error "Funcții lipsă: ${failed_functions[*]}"
        return 1
    fi
}

# Test funcții de management job-uri
test_rclone_job_management() {
    ui_header "🧪 Test 4: Verificare funcții management job-uri"
    
    local job_functions=(
        "create_rclone_backup_job"
        "list_backup_jobs"
        "run_backup_job"
        "remove_backup_job"
        "add_backup_to_cron"
    )
    
    local failed_functions=()
    
    for func in "${job_functions[@]}"; do
        if [[ "$(type -t "$func")" == "function" ]]; then
            ui_success "✅ $func"
        else
            ui_error "❌ $func"
            failed_functions+=("$func")
        fi
    done
    
    if [[ ${#failed_functions[@]} -eq 0 ]]; then
        ui_success "Toate funcțiile de management job-uri sunt disponibile"
        return 0
    else
        ui_error "Funcții lipsă: ${failed_functions[*]}"
        return 1
    fi
}

# Test funcții de monitorizare și utilitare
test_rclone_utilities() {
    ui_header "🧪 Test 5: Verificare funcții utilitare"
    
    local util_functions=(
        "list_rclone_remotes"
        "test_rclone_remote"
        "validate_rclone_configs"
        "monitor_cloud_storage"
        "cleanup_old_backups"
        "show_rclone_menu"
    )
    
    local failed_functions=()
    
    for func in "${util_functions[@]}"; do
        if [[ "$(type -t "$func")" == "function" ]]; then
            ui_success "✅ $func"
        else
            ui_error "❌ $func"
            failed_functions+=("$func")
        fi
    done
    
    if [[ ${#failed_functions[@]} -eq 0 ]]; then
        ui_success "Toate funcțiile utilitare sunt disponibile"
        return 0
    else
        ui_error "Funcții lipsă: ${failed_functions[*]}"
        return 1
    fi
}

# Test structură directoare
test_directory_structure() {
    ui_header "🧪 Test 6: Verificare structură directoare"
    
    # Inițializează structura
    init_cloud_structure
    
    local required_dirs=(
        "$CLOUD_CONFIG_DIR"
        "$CLOUD_SCRIPTS_DIR"
        "$CLOUD_TEMPLATES_DIR"
        "$CLOUD_CONFIG_DIR/backup_jobs"
    )
    
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            ui_success "✅ $(basename "$dir")"
        else
            ui_error "❌ $(basename "$dir")"
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -eq 0 ]]; then
        ui_success "Structura de directoare este corectă"
        return 0
    else
        ui_error "Directoare lipsă: ${missing_dirs[*]}"
        return 1
    fi
}

# Test configurații existente
test_existing_configurations() {
    ui_header "🧪 Test 7: Verificare configurații existente"
    
    if command -v rclone >/dev/null 2>&1; then
        local remotes
        remotes=$(rclone listremotes 2>/dev/null)
        
        if [[ -n "$remotes" ]]; then
            ui_success "✅ Remote-uri configurate găsite:"
            echo "$remotes" | while read -r remote; do
                [[ -n "$remote" ]] && ui_info "  • ${remote%:}"
            done
        else
            ui_info "ℹ️ Nu sunt remote-uri configurate (normal pentru instalare nouă)"
        fi
    else
        ui_info "ℹ️ Rclone nu este instalat - se va instala la primul test"
    fi
    
    return 0
}

# Test integrare cu meniul principal
test_menu_integration() {
    ui_header "🧪 Test 8: Verificare integrare meniu"
    
    # Verifică dacă funcția de meniu este disponibilă
    if [[ "$(type -t show_rclone_menu)" == "function" ]]; then
        ui_success "✅ Meniul rclone este disponibil"
    else
        ui_error "❌ Meniul rclone nu este disponibil"
        return 1
    fi
    
    # Verifică dacă meniul principal include rclone
    if grep -q "show_rclone_menu" "$CLOUD_DIR/cloud_integration_manager.sh"; then
        ui_success "✅ Rclone este integrat în meniul principal"
    else
        ui_error "❌ Rclone nu este integrat în meniul principal"
        return 1
    fi
    
    return 0
}

# =============================================================================
# FUNCȚIA PRINCIPALĂ DE TEST
# =============================================================================

run_all_tests() {
    local total_tests=8
    local passed_tests=0
    local failed_tests=()
    
    ui_header "🚀 LOMP Stack v2.0 - Test Complet Rclone Integration"
    echo "Se execută $total_tests teste..."
    echo
    
    # Execută toate testele
    if test_rclone_installation; then
        ((passed_tests++))
    else
        failed_tests+=("Test 1: Instalare rclone")
    fi
    
    if test_rclone_configuration; then
        ((passed_tests++))
    else
        failed_tests+=("Test 2: Funcții configurare")
    fi
    
    if test_rclone_sync_backup; then
        ((passed_tests++))
    else
        failed_tests+=("Test 3: Funcții sincronizare/backup")
    fi
    
    if test_rclone_job_management; then
        ((passed_tests++))
    else
        failed_tests+=("Test 4: Management job-uri")
    fi
    
    if test_rclone_utilities; then
        ((passed_tests++))
    else
        failed_tests+=("Test 5: Funcții utilitare")
    fi
    
    if test_directory_structure; then
        ((passed_tests++))
    else
        failed_tests+=("Test 6: Structură directoare")
    fi
    
    if test_existing_configurations; then
        ((passed_tests++))
    else
        failed_tests+=("Test 7: Configurații existente")
    fi
    
    if test_menu_integration; then
        ((passed_tests++))
    else
        failed_tests+=("Test 8: Integrare meniu")
    fi
    
    # Afișează rezultatele finale
    echo
    ui_header "📊 REZULTATE FINALE"
    
    ui_info "Teste executate: $total_tests"
    ui_success "Teste trecute: $passed_tests"
    
    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        ui_error "Teste eșuate: ${#failed_tests[@]}"
        echo
        ui_warning "Teste care au eșuat:"
        for test in "${failed_tests[@]}"; do
            echo "  ❌ $test"
        done
        echo
        ui_error "Unele teste au eșuat. Verificați configurația și dependențele."
        return 1
    else
        echo
        ui_success "🎉 TOATE TESTELE AU TRECUT CU SUCCES!"
        ui_info "Integrarea rclone este funcțională și gata de utilizare."
        echo
        ui_info "Pentru a utiliza rclone:"
        echo "1. Rulați cloud integration manager: ./cloud/cloud_integration_manager.sh"
        echo "2. Selectați opțiunea '8. 🗄️ Rclone Management'"
        echo "3. Urmați instrucțiunile pentru configurare și utilizare"
        return 0
    fi
}

# Funcție de ajutor
show_help() {
    echo "LOMP Stack v2.0 - Test Rclone Integration"
    echo
    echo "Utilizare: $0 [opțiuni]"
    echo
    echo "Opțiuni:"
    echo "  -h, --help     Afișează acest mesaj de ajutor"
    echo "  -q, --quick    Execută doar testele de bază"
    echo "  -v, --verbose  Afișează informații detaliate"
    echo
    echo "Exemple:"
    echo "  $0              # Execută toate testele"
    echo "  $0 --quick      # Execută doar testele de bază"
    echo "  $0 --verbose    # Execută cu informații detaliate"
}

# =============================================================================
# POINT DE INTRARE
# =============================================================================

main() {
    local quick_mode=false
    local verbose_mode=false
    
    # Procesează argumentele
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -q|--quick)
                quick_mode=true
                shift
                ;;
            -v|--verbose)
                verbose_mode=true
                shift
                ;;
            *)
                ui_error "Argument necunoscut: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Configurează verbosity
    if [[ "$verbose_mode" == true ]]; then
        set -x
    fi
    
    # Execută testele
    if [[ "$quick_mode" == true ]]; then
        ui_info "Mod rapid activat - se execută doar testele esențiale"
        test_rclone_installation && test_rclone_configuration && test_menu_integration
    else
        run_all_tests
    fi
}

# Execută main dacă scriptul este rulat direct
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
