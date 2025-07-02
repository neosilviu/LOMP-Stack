#!/bin/bash
#==============================================================================
# LOMP Stack v3.0 - Dependency Manager
# 
# Centralized system for dependency management between scripts
# 
# Author: Silviu Ilie
# Email: neosilviu@gmail.com
# Company: aemdPC
# License: MIT
# Version: 3.0
# 
# Description: Provides centralized dependency management functionality
# for the LOMP Stack, ensuring safe sourcing of helper scripts and
# managing dependencies between different modules.
#==============================================================================

# Mapat global pentru dependențe încărcate
declare -A LOADED_DEPENDENCIES=()

# Funcție centralizată pentru source-area sigură a dependențelor
source_stack_helper() {
    local helper_name="$1"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local full_path=""
    
    # Încearcă să găsească root-ul proiectului
    local project_root="$script_dir"
    while [[ "$project_root" != "/" && ! -d "$project_root/helpers" ]]; do
        project_root="$(dirname "$project_root")"
    done
    
    # Încearcă mai multe căi posibile pentru helper-e cu și fără extensie .sh
    local possible_paths=(
        "$script_dir/$helper_name.sh"
        "$script_dir/../$helper_name.sh"
        "$project_root/$helper_name.sh"
        "$project_root/helpers/$helper_name.sh"
        "$project_root/helpers/utils/$helper_name.sh"
        "$(dirname "$script_dir")/$helper_name.sh"
        "$(cd "$script_dir/../../" 2>/dev/null && pwd)/$helper_name.sh"
        "$(cd "$script_dir/../.." 2>/dev/null && pwd)/helpers/$helper_name.sh"
        "$(cd "$script_dir/../.." 2>/dev/null && pwd)/helpers/utils/$helper_name.sh"
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            full_path="$path"
            break
        fi
    done
    
    if [[ -z "$full_path" ]]; then
        echo "[ERROR] Nu pot găsi helper-ul: $helper_name" >&2
        echo "[ERROR] Căi încercate: ${possible_paths[*]}" >&2
        return 1
    fi
    
    # Verifică dacă dependența a fost deja încărcată
    local normalized_path
    normalized_path="$(realpath "$full_path" 2>/dev/null || echo "$full_path")"
    if [[ "${LOADED_DEPENDENCIES[$normalized_path]:-}" == "1" ]]; then
        return 0  # Deja încărcat
    fi
    
    # Source-ează fișierul și marchează ca încărcat
    # shellcheck disable=SC1090
    if source "$full_path"; then
        LOADED_DEPENDENCIES["$normalized_path"]="1"
        return 0
    else
        echo "[ERROR] Eșec la source-area: $full_path" >&2
        return 1
    fi
}

# Verifică dacă toate dependințele necesare sunt disponibile
check_required_dependencies() {
    local dependencies=("$@")
    local missing=()
    
    for dep in "${dependencies[@]}"; do
        if ! source_stack_helper "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[ERROR] Dependințe lipsă: ${missing[*]}" >&2
        return 1
    fi
    
    return 0
}

# Funcție pentru cleanup dependențe
cleanup_dependencies() {
    unset LOADED_DEPENDENCIES
    declare -gA LOADED_DEPENDENCIES=()
}

# Inițializează dependențele de bază necesare pentru toate scripturile
init_core_dependencies() {
    local core_deps=(
        "utils/functions.sh"
        "utils/lang.sh"
    )
    
    check_required_dependencies "${core_deps[@]}" || {
        echo "[FATAL] Nu pot încărca dependențele de bază!" >&2
        exit 1
    }
}

# Funcție pentru afișarea informațiilor despre autor
show_dependency_manager_info() {
    echo "=============================================="
    echo "   LOMP Stack v3.0 - Dependency Manager"
    echo "=============================================="
    echo "Author: Silviu Ilie"
    echo "Email: neosilviu@gmail.com"
    echo "Company: aemdPC"
    echo "License: MIT"
    echo "Version: 3.0"
    echo "=============================================="
    echo
    echo "Dependency Manager Module - Centralized dependency management"
    echo "Provides safe sourcing of helper scripts and manages"
    echo "dependencies between different LOMP Stack modules."
    echo "=============================================="
}

# Auto-export pentru disponibilitate globală
export -f source_stack_helper
export -f check_required_dependencies
export -f cleanup_dependencies
export -f init_core_dependencies
export -f show_dependency_manager_info
