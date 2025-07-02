#!/bin/bash
#
# ui_ux_manager.sh - Part of LOMP Stack v3.0
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
# ui_ux_manager.sh - Sistem avansat de UI/UX improvements

# Load dependency manager and error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dependency_manager.sh"
source "$SCRIPT_DIR/error_handler.sh"
source "$SCRIPT_DIR/state_manager.sh"
source "$SCRIPT_DIR/ui_manager.sh"

# Initialize error handling
setup_error_handlers

# Source helpers using dependency manager
source_stack_helper "functions"

# Constante pentru UI/UX
readonly UI_THEME_DIR="/tmp/stack_themes"

# Detectează capabilitățile terminalului
detect_terminal_capabilities() {
    log_debug "Detectare capabilități terminal..."
    
    # Detectează suportul pentru culori
    local color_support="basic"
    if [[ $TERM =~ 256 ]] || [[ $COLORTERM =~ (truecolor|24bit) ]]; then
        color_support="256"
    elif [[ $COLORTERM =~ (truecolor|24bit) ]]; then
        color_support="truecolor"
    fi
    
    # Detectează dimensiunea terminalului
    local terminal_width
    local terminal_height
    terminal_width=$(tput cols 2>/dev/null || echo "80")
    terminal_height=$(tput lines 2>/dev/null || echo "24")
    
    # Detectează suportul Unicode
    local unicode_support="false"
    if [[ $LANG =~ UTF-8 ]] || [[ $LC_ALL =~ UTF-8 ]]; then
        unicode_support="true"
    fi
    
    # Salvează configurația
    set_state_var "TERMINAL_COLOR_SUPPORT" "$color_support" false
    set_state_var "TERMINAL_WIDTH" "$terminal_width" false
    set_state_var "TERMINAL_HEIGHT" "$terminal_height" false
    set_state_var "UNICODE_SUPPORT" "$unicode_support" false
    
    log_debug "Terminal: ${terminal_width}x${terminal_height}, Colors: $color_support, Unicode: $unicode_support"
    
    return 0
}

# Configurează tema UI
configure_ui_theme() {
    local theme_name="${1:-default}"
    
    log_info "Configurare temă UI: $theme_name" "cyan"
    
    mkdir -p "$UI_THEME_DIR"
    
    # Definește temele disponibile
    case "$theme_name" in
        "default")
            configure_default_theme
            ;;
        "dark")
            configure_dark_theme
            ;;
        "minimal")
            configure_minimal_theme
            ;;
        "colorful")
            configure_colorful_theme
            ;;
        *)
            log_warning "Temă necunoscută: $theme_name, folosesc default"
            configure_default_theme
            ;;
    esac
    
    set_state_var "UI_THEME" "$theme_name" true
    
    return 0
}

# Tema default
configure_default_theme() {
    cat > "$UI_THEME_DIR/default.conf" << 'EOF'
# Default Theme Configuration
PRIMARY_COLOR="\e[1;34m"      # Blue bold
SECONDARY_COLOR="\e[1;36m"    # Cyan bold
SUCCESS_COLOR="\e[1;32m"      # Green bold
WARNING_COLOR="\e[1;33m"      # Yellow bold
ERROR_COLOR="\e[1;31m"        # Red bold
ACCENT_COLOR="\e[1;35m"       # Magenta bold
RESET_COLOR="\e[0m"           # Reset

# UI Elements
HEADER_STYLE="box_double"
MENU_STYLE="numbered"
PROGRESS_STYLE="bar"
SEPARATOR_CHAR="─"
BULLET_CHAR="•"

# Unicode support
USE_UNICODE="auto"
EOF
    
    log_debug "Tema default configurată"
}

# Tema dark
configure_dark_theme() {
    cat > "$UI_THEME_DIR/dark.conf" << 'EOF'
# Dark Theme Configuration
PRIMARY_COLOR="\e[38;5;39m"      # Bright blue
SECONDARY_COLOR="\e[38;5;51m"    # Bright cyan
SUCCESS_COLOR="\e[38;5;46m"      # Bright green
WARNING_COLOR="\e[38;5;226m"     # Bright yellow
ERROR_COLOR="\e[38;5;196m"       # Bright red
ACCENT_COLOR="\e[38;5;201m"      # Bright magenta
RESET_COLOR="\e[0m"              # Reset

# UI Elements
HEADER_STYLE="box_rounded"
MENU_STYLE="bullets"
PROGRESS_STYLE="blocks"
SEPARATOR_CHAR="━"
BULLET_CHAR="▶"

# Unicode support
USE_UNICODE="true"
EOF
    
    log_debug "Tema dark configurată"
}

# Tema minimal
configure_minimal_theme() {
    cat > "$UI_THEME_DIR/minimal.conf" << 'EOF'
# Minimal Theme Configuration
PRIMARY_COLOR="\e[1m"          # Bold only
SECONDARY_COLOR="\e[2m"        # Dim
SUCCESS_COLOR="\e[1;32m"       # Green bold only
WARNING_COLOR="\e[1;33m"       # Yellow bold only
ERROR_COLOR="\e[1;31m"         # Red bold only
ACCENT_COLOR="\e[4m"           # Underline
RESET_COLOR="\e[0m"            # Reset

# UI Elements
HEADER_STYLE="simple"
MENU_STYLE="simple"
PROGRESS_STYLE="simple"
SEPARATOR_CHAR="-"
BULLET_CHAR="*"

# Unicode support
USE_UNICODE="false"
EOF
    
    log_debug "Tema minimal configurată"
}

# Tema colorful
configure_colorful_theme() {
    cat > "$UI_THEME_DIR/colorful.conf" << 'EOF'
# Colorful Theme Configuration
PRIMARY_COLOR="\e[38;5;33m"      # Blue
SECONDARY_COLOR="\e[38;5;87m"    # Cyan
SUCCESS_COLOR="\e[38;5;82m"      # Green
WARNING_COLOR="\e[38;5;214m"     # Orange
ERROR_COLOR="\e[38;5;196m"       # Red
ACCENT_COLOR="\e[38;5;213m"      # Pink
RESET_COLOR="\e[0m"              # Reset

# UI Elements
HEADER_STYLE="gradient"
MENU_STYLE="colorful"
PROGRESS_STYLE="rainbow"
SEPARATOR_CHAR="═"
BULLET_CHAR="◆"

# Unicode support
USE_UNICODE="true"
EOF
    
    log_debug "Tema colorful configurată"
}

# Încarcă tema curentă
load_current_theme() {
    local current_theme
    current_theme=$(get_state_var "UI_THEME" "default")
    local theme_file="$UI_THEME_DIR/${current_theme}.conf"
    
    # shellcheck source=/tmp/stack_themes/default.conf
    # shellcheck source=/tmp/stack_themes/dark.conf
    # shellcheck source=/tmp/stack_themes/minimal.conf
    # shellcheck source=/tmp/stack_themes/colorful.conf
    if [[ -f "$theme_file" ]]; then
        source "$theme_file"
        log_debug "Tema încărcată: $current_theme"
    else
        log_warning "Fișierul temei nu există: $theme_file"
        configure_default_theme
        source "$UI_THEME_DIR/default.conf"
    fi
}

# Header avansat cu styling
show_advanced_header() {
    local title="$1"
    local subtitle="${2:-}"
    local style="${3:-auto}"
    
    # Încarcă tema
    load_current_theme
    
    # Detectează stilul automat
    if [[ "$style" == "auto" ]]; then
        style="$HEADER_STYLE"
    fi
    
    local width
    width=$(get_state_var "TERMINAL_WIDTH" "80")
    
    echo
    case "$style" in
        "box_double")
            show_double_box_header "$title" "$subtitle" "$width"
            ;;
        "box_rounded")
            show_rounded_box_header "$title" "$subtitle" "$width"
            ;;
        "gradient")
            show_gradient_header "$title" "$subtitle" "$width"
            ;;
        "simple"|*)
            show_simple_header "$title" "$subtitle" "$width"
            ;;
    esac
    echo
}

# Header cu casetă dublă
show_double_box_header() {
    local title="$1"
    local subtitle="$2"
    local width="$3"
    
    local title_len=${#title}
    local subtitle_len=${#subtitle}
    local content_width=$((width - 4))
    
    # Top border
    echo -e "${PRIMARY_COLOR}╔$(printf '═%.0s' $(seq 1 $((width - 2))))╗${RESET_COLOR}"
    
    # Title line
    local title_padding=$(( (content_width - title_len) / 2 ))
    printf "${PRIMARY_COLOR}║${RESET_COLOR}"
    printf "%*s" $title_padding ""
    echo -e "${PRIMARY_COLOR}${title}${RESET_COLOR}"
    printf "%*s" $((content_width - title_len - title_padding)) ""
    echo -e "${PRIMARY_COLOR}║${RESET_COLOR}"
    
    # Subtitle line (dacă există)
    if [[ -n "$subtitle" ]]; then
        echo -e "${PRIMARY_COLOR}╠$(printf '═%.0s' $(seq 1 $((width - 2))))╣${RESET_COLOR}"
        local subtitle_padding=$(( (content_width - subtitle_len) / 2 ))
        printf "${PRIMARY_COLOR}║${RESET_COLOR}"
        printf "%*s" $subtitle_padding ""
        echo -e "${SECONDARY_COLOR}${subtitle}${RESET_COLOR}"
        printf "%*s" $((content_width - subtitle_len - subtitle_padding)) ""
        echo -e "${PRIMARY_COLOR}║${RESET_COLOR}"
    fi
    
    # Bottom border
    echo -e "${PRIMARY_COLOR}╚$(printf '═%.0s' $(seq 1 $((width - 2))))╝${RESET_COLOR}"
}

# Header cu casetă rotunjită
show_rounded_box_header() {
    local title="$1"
    local subtitle="$2"
    local width="$3"
    
    local unicode_support
    unicode_support=$(get_state_var "UNICODE_SUPPORT" "false")
    
    if [[ "$unicode_support" == "true" ]]; then
        # Unicode box characters
        echo -e "${PRIMARY_COLOR}╭$(printf '─%.0s' $(seq 1 $((width - 2))))╮${RESET_COLOR}"
        echo -e "${PRIMARY_COLOR}│${RESET_COLOR} ${title} ${PRIMARY_COLOR}│${RESET_COLOR}"
        [[ -n "$subtitle" ]] && echo -e "${PRIMARY_COLOR}│${RESET_COLOR} ${SECONDARY_COLOR}${subtitle}${RESET_COLOR} ${PRIMARY_COLOR}│${RESET_COLOR}"
        echo -e "${PRIMARY_COLOR}╰$(printf '─%.0s' $(seq 1 $((width - 2))))╯${RESET_COLOR}"
    else
        # ASCII fallback
        echo -e "${PRIMARY_COLOR}+$(printf '-%.0s' $(seq 1 $((width - 2))))+${RESET_COLOR}"
        echo -e "${PRIMARY_COLOR}|${RESET_COLOR} ${title} ${PRIMARY_COLOR}|${RESET_COLOR}"
        [[ -n "$subtitle" ]] && echo -e "${PRIMARY_COLOR}|${RESET_COLOR} ${SECONDARY_COLOR}${subtitle}${RESET_COLOR} ${PRIMARY_COLOR}|${RESET_COLOR}"
        echo -e "${PRIMARY_COLOR}+$(printf '-%.0s' $(seq 1 $((width - 2))))+${RESET_COLOR}"
    fi
}

# Header cu gradient
show_gradient_header() {
    local title="$1"
    local subtitle="$2"
    local width="$3"
    
    # Simulează gradient cu culori diferite
    local colors=(196 202 208 214 220 226)
    local title_len=${#title}
    
    # Afișează titlul cu gradient
    echo -e "${PRIMARY_COLOR}$(printf '═%.0s' $(seq 1 $width))${RESET_COLOR}"
    
    local color_index=0
    printf " "
    for (( i=0; i<title_len; i++ )); do
        local char="${title:$i:1}"
        local color=${colors[$((color_index % ${#colors[@]}))]}
        printf "\e[38;5;${color}m%s\e[0m" "$char"
        color_index=$((color_index + 1))
    done
    echo
    
    [[ -n "$subtitle" ]] && echo -e " ${SECONDARY_COLOR}${subtitle}${RESET_COLOR}"
    echo -e "${PRIMARY_COLOR}$(printf '═%.0s' $(seq 1 $width))${RESET_COLOR}"
}

# Header simplu
show_simple_header() {
    local title="$1"
    local subtitle="$2"
    local width="$3"
    
    echo -e "${PRIMARY_COLOR}$(printf '=%.0s' $(seq 1 $width))${RESET_COLOR}"
    echo -e "${PRIMARY_COLOR}${title}${RESET_COLOR}"
    [[ -n "$subtitle" ]] && echo -e "${SECONDARY_COLOR}${subtitle}${RESET_COLOR}"
    echo -e "${PRIMARY_COLOR}$(printf '=%.0s' $(seq 1 $width))${RESET_COLOR}"
}

# Meniu avansat cu styling
show_advanced_menu() {
    local menu_title="$1"
    shift
    local options=("$@")
    
    load_current_theme
    
    echo -e "${PRIMARY_COLOR}${menu_title}${RESET_COLOR}"
    echo
    
    local style="$MENU_STYLE"
    
    case "$style" in
        "numbered")
            show_numbered_menu "${options[@]}"
            ;;
        "bullets")
            show_bullets_menu "${options[@]}"
            ;;
        "colorful")
            show_colorful_menu "${options[@]}"
            ;;
        "simple"|*)
            show_simple_menu "${options[@]}"
            ;;
    esac
    
    echo
}

# Meniu numerotat
show_numbered_menu() {
    local options=("$@")
    
    for i in "${!options[@]}"; do
        echo -e "  ${ACCENT_COLOR}$((i + 1)).${RESET_COLOR} ${options[$i]}"
    done
}

# Meniu cu bullets
show_bullets_menu() {
    local options=("$@")
    
    for option in "${options[@]}"; do
        echo -e "  ${ACCENT_COLOR}${BULLET_CHAR}${RESET_COLOR} ${option}"
    done
}

# Meniu colorat
show_colorful_menu() {
    local options=("$@")
    local colors=(33 87 82 214 196 213)
    
    for i in "${!options[@]}"; do
        local color=${colors[$((i % ${#colors[@]}))]}
        echo -e "  \e[38;5;${color}m$((i + 1)).\e[0m ${options[$i]}"
    done
}

# Meniu simplu
show_simple_menu() {
    local options=("$@")
    
    for i in "${!options[@]}"; do
        echo "  $((i + 1)). ${options[$i]}"
    done
}

# Progress bar avansat
show_advanced_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing...}"
    local style="${4:-auto}"
    
    load_current_theme
    
    if [[ "$style" == "auto" ]]; then
        style="$PROGRESS_STYLE"
    fi
    
    case "$style" in
        "bar")
            show_bar_progress "$current" "$total" "$message"
            ;;
        "blocks")
            show_blocks_progress "$current" "$total" "$message"
            ;;
        "rainbow")
            show_rainbow_progress "$current" "$total" "$message"
            ;;
        "simple"|*)
            show_simple_progress "$current" "$total" "$message"
            ;;
    esac
}

# Progress bar clasic
show_bar_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    local percent=$((current * 100 / total))
    local width=50
    local filled=$((current * width / total))
    
    printf "\r${message} ["
    printf "%*s" $filled "" | tr ' ' '█'
    printf "%*s" $((width - filled)) "" | tr ' ' '░'
    printf "] %d%%" $percent
}

# Progress cu blocuri
show_blocks_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    local percent=$((current * 100 / total))
    local width=30
    local filled=$((current * width / total))
    
    printf "\r${SUCCESS_COLOR}${message}${RESET_COLOR} "
    
    for ((i=0; i<width; i++)); do
        if ((i < filled)); then
            printf "${SUCCESS_COLOR}█${RESET_COLOR}"
        else
            printf "${SECONDARY_COLOR}░${RESET_COLOR}"
        fi
    done
    
    printf " ${ACCENT_COLOR}%d%%${RESET_COLOR}" $percent
}

# Progress rainbow
show_rainbow_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    local percent=$((current * 100 / total))
    local colors=(196 202 208 214 220 226 46 51 45 39 33 27)
    local width=40
    local filled=$((current * width / total))
    
    printf "\r${message} "
    
    for ((i=0; i<width; i++)); do
        if ((i < filled)); then
            local color=${colors[$((i % ${#colors[@]}))]}
            printf "\e[38;5;${color}m█\e[0m"
        else
            printf "░"
        fi
    done
    
    printf " %d%%" $percent
}

# Progress simplu
show_simple_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    local percent=$((current * 100 / total))
    printf "\r%s [%d/%d] %d%%" "$message" "$current" "$total" "$percent"
}

# Separator avansat
show_advanced_separator() {
    local width="${1:-80}"
    local style="${2:-auto}"
    
    load_current_theme
    
    if [[ "$style" == "auto" ]]; then
        style="$SEPARATOR_CHAR"
    fi
    
    echo -e "${SECONDARY_COLOR}$(printf "${style}%.0s" $(seq 1 "$width"))${RESET_COLOR}"
}

# Dialog de confirmare avansat
show_advanced_confirm() {
    local message="$1"
    local default="${2:-y}"
    
    load_current_theme
    
    while true; do
        if [[ "$default" == "y" ]]; then
            echo -e "${WARNING_COLOR}${message}${RESET_COLOR} ${SECONDARY_COLOR}[Y/n]${RESET_COLOR}: "
        else
            echo -e "${WARNING_COLOR}${message}${RESET_COLOR} ${SECONDARY_COLOR}[y/N]${RESET_COLOR}: "
        fi
        
        read -r response
        
        case "$response" in
            ""|"y"|"Y"|"yes"|"YES")
                [[ "$default" == "y" || "$response" =~ ^[yY] ]] && return 0
                [[ "$default" == "n" && "$response" == "" ]] && return 1
                ;;
            "n"|"N"|"no"|"NO")
                return 1
                ;;
            *)
                echo -e "${ERROR_COLOR}Vă rog răspundeți cu 'y' pentru da sau 'n' pentru nu.${RESET_COLOR}"
                ;;
        esac
    done
}

# Input avansat cu validare
read_advanced_input() {
    local prompt="$1"
    local default="$2"
    local validator="${3:-}"
    local max_attempts="${4:-3}"
    
    load_current_theme
    
    local attempts=0
    local user_input
    
    while ((attempts < max_attempts)); do
        if [[ -n "$default" ]]; then
            echo -e "${PRIMARY_COLOR}${prompt}${RESET_COLOR} ${SECONDARY_COLOR}[${default}]${RESET_COLOR}: "
        else
            echo -e "${PRIMARY_COLOR}${prompt}${RESET_COLOR}: "
        fi
        
        read -r user_input
        
        # Folosește valoarea default dacă nu s-a introdus nimic
        [[ -z "$user_input" && -n "$default" ]] && user_input="$default"
        
        # Validează input-ul
        if [[ -n "$validator" ]]; then
            if ! "$validator" "$user_input"; then
                attempts=$((attempts + 1))
                echo -e "${ERROR_COLOR}Input invalid. Încercări rămase: $((max_attempts - attempts))${RESET_COLOR}"
                continue
            fi
        fi
        
        echo "$user_input"
        return 0
    done
    
    echo -e "${ERROR_COLOR}Numărul maxim de încercări a fost depășit.${RESET_COLOR}"
    return 1
}

# Loading animation
show_loading_animation() {
    local message="${1:-Loading...}"
    local duration="${2:-5}"
    
    load_current_theme
    
    local frames=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
    local frame_count=${#frames[@]}
    local frame_index=0
    
    echo -ne "${message} "
    
    for ((i=0; i<duration*10; i++)); do
        printf "\r${message} ${ACCENT_COLOR}${frames[$frame_index]}${RESET_COLOR}"
        frame_index=$(((frame_index + 1) % frame_count))
        sleep 0.1
    done
    
    printf "\r${message} ${SUCCESS_COLOR}✓${RESET_COLOR}\n"
}

# Status indicator
show_status_indicator() {
    local status="$1"
    local message="$2"
    
    load_current_theme
    
    case "$status" in
        "success"|"ok")
            echo -e " ${SUCCESS_COLOR}✓${RESET_COLOR} ${message}"
            ;;
        "error"|"fail")
            echo -e " ${ERROR_COLOR}✗${RESET_COLOR} ${message}"
            ;;
        "warning"|"warn")
            echo -e " ${WARNING_COLOR}⚠${RESET_COLOR} ${message}"
            ;;
        "info")
            echo -e " ${ACCENT_COLOR}ℹ${RESET_COLOR} ${message}"
            ;;
        "pending"|"wait")
            echo -e " ${SECONDARY_COLOR}⏳${RESET_COLOR} ${message}"
            ;;
        *)
            echo -e " ${message}"
            ;;
    esac
}

# Inițializare automată
detect_terminal_capabilities
configure_ui_theme "default"

# Export funcții pentru utilizare externă
export -f show_advanced_header show_advanced_menu show_advanced_progress
export -f show_advanced_separator show_advanced_confirm read_advanced_input
export -f show_loading_animation show_status_indicator configure_ui_theme

log_debug "UI/UX Manager încărcat cu succes"
