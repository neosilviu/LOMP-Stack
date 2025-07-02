#!/bin/bash
#
# ui_manager.sh - Part of LOMP Stack v3.0
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
# ui_manager.sh - Sistem îmbunătățit pentru interfața utilizator

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependency_manager.sh"
source "$SCRIPT_DIR/error_handler.sh"
source "$SCRIPT_DIR/state_manager.sh"

# Initialize error handling
setup_error_handlers
DEBUG_MODE=true

# Constante pentru UI
readonly UI_WIDTH=80
readonly PROGRESS_CHAR="█"
readonly EMPTY_CHAR="░"

# Culori pentru interfață
readonly UI_PRIMARY='\033[1;36m'    # Cyan bold
readonly UI_SUCCESS='\033[1;32m'    # Green bold
readonly UI_WARNING='\033[1;33m'    # Yellow bold
readonly UI_ERROR='\033[1;31m'      # Red bold
readonly UI_INFO='\033[1;34m'       # Blue bold
readonly UI_MUTED='\033[0;37m'      # Light gray
readonly UI_RESET='\033[0m'         # Reset

# Funcție pentru afișarea unui header frumos
show_header() {
    local title="$1"
    local subtitle="${2:-}"
    
    clear
    echo -e "${UI_PRIMARY}"
    echo "╔$(printf '═%.0s' $(seq 1 $((UI_WIDTH-2))))╗"
    
    local title_padding=$(( (UI_WIDTH - ${#title} - 2) / 2 ))
    printf "║%*s%s%*s║\n" $title_padding "" "$title" $((UI_WIDTH - ${#title} - title_padding - 2)) ""
    
    if [[ -n "$subtitle" ]]; then
        echo "╠$(printf '═%.0s' $(seq 1 $((UI_WIDTH-2))))╣"
        local subtitle_padding=$(( (UI_WIDTH - ${#subtitle} - 2) / 2 ))
        printf "║%*s%s%*s║\n" $subtitle_padding "" "$subtitle" $((UI_WIDTH - ${#subtitle} - subtitle_padding - 2)) ""
    fi
    
    echo "╚$(printf '═%.0s' $(seq 1 $((UI_WIDTH-2))))╝"
    echo -e "${UI_RESET}"
}

# Funcție pentru afișarea unei bare de progres
show_progress() {
    local current="$1"
    local total="$2"
    local description="${3:-Processing...}"
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Construiește bara de progres
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="$PROGRESS_CHAR"
    done
    for ((i=0; i<empty; i++)); do
        bar+="$EMPTY_CHAR"
    done
    
    # Afișează bara de progres
    printf "\r${UI_INFO}[%s] %3d%% - %s${UI_RESET}" "$bar" "$percentage" "$description"
    
    # Newline la final
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Funcție pentru afișarea unui meniu cu opțiuni
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo -e "${UI_PRIMARY}$title${UI_RESET}"
    echo "$(printf '─%.0s' $(seq 1 ${#title}))"
    echo
    
    for i in "${!options[@]}"; do
        local option_num=$((i + 1))
        echo -e "${UI_INFO}  $option_num.${UI_RESET} ${options[$i]}"
    done
    
    echo -e "${UI_ERROR}  0.${UI_RESET} Exit"
    echo
}

# Funcție pentru citirea unei selecții din meniu
read_menu_selection() {
    local max_option="$1"
    local prompt="${2:-Choose an option}"
    local selection
    
    while true; do
        echo -e -n "${UI_PRIMARY}$prompt [0-$max_option]: ${UI_RESET}"
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 0 ]] && [[ "$selection" -le "$max_option" ]]; then
            echo "$selection"
            return 0
        else
            echo -e "${UI_ERROR}Invalid selection. Please choose a number between 0 and $max_option.${UI_RESET}"
        fi
    done
}

# Funcție pentru confirmarea unei acțiuni
confirm_action() {
    local message="$1"
    local default="${2:-n}"  # y/n
    local response
    
    while true; do
        if [[ "$default" == "y" ]]; then
            echo -e -n "${UI_WARNING}$message [Y/n]: ${UI_RESET}"
        else
            echo -e -n "${UI_WARNING}$message [y/N]: ${UI_RESET}"
        fi
        
        read -r response
        
        # Folosește default-ul dacă nu s-a introdus nimic
        if [[ -z "$response" ]]; then
            response="$default"
        fi
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo -e "${UI_ERROR}Please answer yes or no.${UI_RESET}"
                ;;
        esac
    done
}

# Funcție pentru citirea unei valori cu validare
read_input() {
    local prompt="$1"
    local validation_func="${2:-}"  # Funcție opțională de validare
    local default="${3:-}"
    local is_password="${4:-false}"
    local value
    
    while true; do
        if [[ -n "$default" ]]; then
            echo -e -n "${UI_INFO}$prompt [$default]: ${UI_RESET}"
        else
            echo -e -n "${UI_INFO}$prompt: ${UI_RESET}"
        fi
        
        if [[ "$is_password" == "true" ]]; then
            read -s -r value
            echo  # Newline după password input
        else
            read -r value
        fi
        
        # Folosește default-ul dacă nu s-a introdus nimic
        if [[ -z "$value" && -n "$default" ]]; then
            value="$default"
        fi
        
        # Validare dacă este specificată o funcție
        if [[ -n "$validation_func" ]]; then
            if $validation_func "$value"; then
                echo "$value"
                return 0
            else
                echo -e "${UI_ERROR}Invalid input. Please try again.${UI_RESET}"
            fi
        else
            echo "$value"
            return 0
        fi
    done
}

# Funcții de validare comune
validate_domain() {
    local domain="$1"
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        echo -e "${UI_ERROR}Invalid domain format${UI_RESET}"
        return 1
    fi
}

validate_username() {
    local username="$1"
    if [[ "$username" =~ ^[a-z]([a-z0-9_]{0,30}[a-z0-9])?$ ]]; then
        return 0
    else
        echo -e "${UI_ERROR}Username must start with a letter and contain only lowercase letters, numbers, and underscores${UI_RESET}"
        return 1
    fi
}

validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        echo -e "${UI_ERROR}Invalid email format${UI_RESET}"
        return 1
    fi
}

# Funcție pentru afișarea stării sistemului
show_system_status() {
    echo -e "${UI_PRIMARY}=== SYSTEM STATUS ===${UI_RESET}"
    
    # Verifică serviciile principale
    local services=("nginx" "apache2" "lsws" "mariadb" "mysql" "redis-server" "php*-fpm")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${UI_SUCCESS}✓${UI_RESET} $service: ${UI_SUCCESS}Running${UI_RESET}"
        else
            echo -e "${UI_MUTED}✗${UI_RESET} $service: ${UI_MUTED}Not running${UI_RESET}"
        fi
    done
    
    echo
    
    # Afișează informații despre disk
    echo -e "${UI_INFO}Disk Usage:${UI_RESET}"
    df -h / | tail -1 | awk '{printf "  Root: %s used of %s (%s)\n", $3, $2, $5}'
    
    # Afișează informații despre memorie
    echo -e "${UI_INFO}Memory Usage:${UI_RESET}"
    free -h | awk 'NR==2{printf "  RAM: %s used of %s\n", $3, $2}'
    
    echo
}

# Funcție pentru afișarea unei liste cu paginare
show_paginated_list() {
    local title="$1"
    shift
    local items=("$@")
    local per_page=10
    local total_items=${#items[@]}
    local total_pages=$(( (total_items + per_page - 1) / per_page ))
    local current_page=1
    
    while true; do
        clear
        echo -e "${UI_PRIMARY}$title (Page $current_page of $total_pages)${UI_RESET}"
        echo "$(printf '─%.0s' $(seq 1 ${#title}))"
        echo
        
        local start_idx=$(( (current_page - 1) * per_page ))
        local end_idx=$(( start_idx + per_page - 1 ))
        
        for i in $(seq $start_idx $end_idx); do
            if [[ $i -lt $total_items ]]; then
                echo -e "  ${UI_INFO}$((i + 1)).${UI_RESET} ${items[$i]}"
            fi
        done
        
        echo
        echo -e "${UI_MUTED}Navigation: [n]ext, [p]revious, [q]uit${UI_RESET}"
        echo -e -n "${UI_PRIMARY}Choice: ${UI_RESET}"
        
        read -r choice
        case "$choice" in
            [Nn]|[Nn][Ee][Xx][Tt])
                if [[ $current_page -lt $total_pages ]]; then
                    ((current_page++))
                fi
                ;;
            [Pp]|[Pp][Rr][Ee][Vv])
                if [[ $current_page -gt 1 ]]; then
                    ((current_page--))
                fi
                ;;
            [Qq]|[Qq][Uu][Ii][Tt])
                return 0
                ;;
            [0-9]*)
                if [[ "$choice" -ge 1 ]] && [[ "$choice" -le $total_items ]]; then
                    echo "$choice"
                    return 0
                else
                    echo -e "${UI_ERROR}Invalid selection${UI_RESET}"
                    sleep 2
                fi
                ;;
        esac
    done
}

# Funcție pentru afișarea unui spinner de loading
show_spinner() {
    local pid="$1"
    local message="${2:-Loading...}"
    local spin_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        local char="${spin_chars:$i:1}"
        printf "\r${UI_INFO}%s %s${UI_RESET}" "$char" "$message"
        i=$(( (i + 1) % ${#spin_chars} ))
        sleep 0.1
    done
    
    printf "\r${UI_SUCCESS}✓ %s${UI_RESET}\n" "$message"
}

# Export funcții pentru utilizare globală
export -f show_header show_progress show_menu read_menu_selection confirm_action
export -f read_input validate_domain validate_username validate_email
export -f show_system_status show_paginated_list show_spinner
