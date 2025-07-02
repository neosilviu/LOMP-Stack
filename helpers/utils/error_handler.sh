#!/bin/bash
#==============================================================================
# LOMP Stack v3.0 - Error Handler
# 
# Centralized system for error handling and logging
# 
# Author: Silviu Ilie
# Email: neosilviu@gmail.com
# Company: aemdPC
# License: MIT
# Version: 3.0
# 
# Description: Provides centralized error handling and logging functionality
# for the LOMP Stack, including colored output, logging to files, and
# comprehensive error catching and reporting mechanisms.
#==============================================================================

# Variabile globale pentru error handling
SCRIPT_NAME="${0##*/}"

# Folosește un director de log local pe Windows/WSL pentru evitarea problemelor de permisiuni
if [[ -d "/tmp" ]]; then
    ERROR_LOG="${ERROR_LOG:-/tmp/stack_errors.log}"
else
    ERROR_LOG="${ERROR_LOG:-./stack_errors.log}"
fi

DEBUG_MODE="${DEBUG_MODE:-0}"
STRICT_MODE="${STRICT_MODE:-0}"

# Culori pentru output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Funcție pentru afișare mesaj cu culoare și timestamp
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local color=""
    
    case "$level" in
        "ERROR") color="$RED" ;;
        "WARN")  color="$YELLOW" ;;
        "INFO")  color="$GREEN" ;;
        "DEBUG") color="$BLUE" ;;
        *)       color="$NC" ;;
    esac
    
    # Afișează în consolă cu culoare
    echo -e "${color}[$timestamp] [$level] [$SCRIPT_NAME] $message${NC}" >&2
    
    # Salvează în log fără culori
    echo "[$timestamp] [$level] [$SCRIPT_NAME] $message" >> "$ERROR_LOG"
}

# Funcții wrapper pentru diferite nivele de logging
log_error() {
    log_message "ERROR" "$1" "${RED}"
    if [[ "$STRICT_MODE" == "1" ]]; then
        exit 1
    fi
}

log_warning() {
    log_message "WARN" "$1" "${YELLOW}"
}

log_warn() {
    log_warning "$1"
}

log_info() {
    local message="$1"
    local color_name="${2:-}"
    local color=""
    
    # Mapează numele culorilor la codurile de culoare
    case "$color_name" in
        red) color="${RED}" ;;
        yellow) color="${YELLOW}" ;;
        green) color="${GREEN}" ;;
        blue) color="${BLUE}" ;;
        cyan) color='\033[0;36m' ;;
        magenta) color='\033[0;35m' ;;
        *) color="" ;;
    esac
    
    log_message "INFO" "$message" "$color"
}

log_debug() {
    if [[ "$DEBUG_MODE" == "1" ]]; then
        log_message "DEBUG" "$1"
    fi
}

# Funcție pentru catch-area erorilor cu context
catch_error() {
    local exit_code="$1"
    local line_number="$2"
    local command="$3"
    
    if [[ "$exit_code" -ne 0 ]]; then
        log_error "Command failed (exit code: $exit_code) at line $line_number: $command"
        if [[ "$STRICT_MODE" == "1" ]]; then
            exit "$exit_code"
        fi
    fi
}

# Funcție pentru executarea unei comenzi cu error handling
safe_execute() {
    local description="$1"
    shift
    local command=("$@")
    
    log_info "Executing: $description"
    log_debug "Command: ${command[*]}"
    
    if "${command[@]}"; then
        log_info "Success: $description"
        return 0
    else
        local exit_code=$?
        log_error "Failed: $description (exit code: $exit_code)"
        return $exit_code
    fi
}

# Funcție pentru verificarea unei condiții cu mesaj custom
assert_condition() {
    local condition="$1"
    local error_message="$2"
    
    if ! eval "$condition"; then
        log_error "Assertion failed: $error_message"
        log_debug "Failed condition: $condition"
        return 1
    fi
    
    return 0
}

# Funcție pentru verificarea existenței unui fișier/director
assert_exists() {
    local path="$1"
    local type="${2:-file}"  # file|directory
    
    case "$type" in
        "file")
            assert_condition "[[ -f '$path' ]]" "File not found: $path"
            ;;
        "directory")
            assert_condition "[[ -d '$path' ]]" "Directory not found: $path"
            ;;
        *)
            assert_condition "[[ -e '$path' ]]" "Path not found: $path"
            ;;
    esac
}

# Funcție pentru verificarea unei comenzi/dependințe
assert_command() {
    local cmd_name="$1"
    local install_hint="${2:-}"
    
    if ! command -v "$cmd_name" >/dev/null 2>&1; then
        local msg="Command not found: $cmd_name"
        if [[ -n "$install_hint" ]]; then
            msg="$msg. Install with: $install_hint"
        fi
        log_error "$msg"
        return 1
    fi
    
    log_debug "Command available: $cmd_name"
    return 0
}

# Funcție pentru setup signal handlers
setup_error_handlers() {
    # Activează strict mode dacă este setat
    if [[ "$STRICT_MODE" == "1" ]]; then
        set -euo pipefail
    fi
    
    # Setup trap pentru ERR dacă nu este în strict mode
    if [[ "$STRICT_MODE" != "1" ]]; then
        trap 'catch_error $? $LINENO "$BASH_COMMAND"' ERR
    fi
    
    # Setup trap pentru cleanup la exit
    trap 'cleanup_on_exit' EXIT
    
    # Setup trap pentru semnale
    trap 'log_warn "Script interrupted by user"; exit 130' INT
    trap 'log_warn "Script terminated"; exit 143' TERM
}

# Funcție de cleanup la ieșire
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log_info "Script completed successfully"
    else
        log_error "Script exited with code: $exit_code"
    fi
}

# Funcție pentru validarea parametrilor
validate_parameters() {
    local required_params=("$@")
    local missing=()
    
    for param in "${required_params[@]}"; do
        if [[ -z "${!param:-}" ]]; then
            missing+=("$param")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required parameters: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Funcție pentru afișarea informațiilor despre autor
show_error_handler_info() {
    echo -e "${BLUE}=============================================="
    echo -e "   LOMP Stack v3.0 - Error Handler"
    echo -e "==============================================\033[0m"
    echo -e "${GREEN}Author: Silviu Ilie"
    echo -e "Email: neosilviu@gmail.com"
    echo -e "Company: aemdPC"
    echo -e "License: MIT"
    echo -e "Version: 3.0\033[0m"
    echo -e "${BLUE}=============================================="
    echo
    echo "Error Handler Module - Centralized error handling and logging"
    echo "Provides colored output, file logging, and comprehensive"
    echo "error catching and reporting for the LOMP Stack."
    echo -e "==============================================\033[0m"
}

# Export funcții pentru utilizare globală
export -f log_message log_error log_warn log_info log_debug
export -f catch_error safe_execute assert_condition assert_exists assert_command
export -f setup_error_handlers cleanup_on_exit validate_parameters show_error_handler_info
