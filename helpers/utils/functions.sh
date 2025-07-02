# shellcheck shell=bash
# functions.sh - Funcții utilitare comune pentru toate scripturile installerului.
# Include color_echo și detect_environment pentru uz general.

color_echo() {
  local color="$1"; shift
  case $color in
    red) code="\033[1;31m";;
    green) code="\033[1;32m";;
    yellow) code="\033[1;33m";;
    blue) code="\033[1;34m";;
    magenta) code="\033[1;35m";;
    cyan) code="\033[1;36m";;
    *) code="\033[0m";;
  esac
  echo -e "${code}$*\033[0m"
}

# Adaugă pornire automată Redis în ~/.profile dacă rulează pe WSL și systemd nu e disponibil
setup_redis_autostart_wsl() {
  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null && ! pgrep -x systemd >/dev/null; then
    local profile_file="$HOME/.profile"
    local redis_start_cmd='if ! pgrep -x redis-server >/dev/null; then\n  nohup redis-server /etc/redis/redis.conf >/dev/null 2>&1 &\nfi'
    if ! grep -q 'redis-server /etc/redis/redis.conf' "$profile_file" 2>/dev/null; then
      echo -e "\n# Pornire automată Redis la login (doar pentru WSL, fără systemd)\n$redis_start_cmd" >> "$profile_file"
      color_echo green "[WSL] Pornirea automată Redis a fost adăugată în $profile_file. Redis va porni la fiecare login shell dacă nu rulează deja."
    else
      color_echo yellow "[WSL] Pornirea automată Redis este deja prezentă în $profile_file."
    fi
  fi
}

# Modular confirmation function for destructive actions
confirm_action() {
  local msg="$1"
  # Confirmare pe aceeași linie, fără newline înainte
  echo -ne "\033[1;33m[?]\033[0m $msg [y/N]: "
  read -r confirm
  [[ "$confirm" =~ ^[Yy]$ ]]
}

# === Logging functions ===
LOG_FILE="${LOG_FILE:-/tmp/stack_installer.log}"

log_info() {
  local msg
  msg="[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"
  echo "$msg" | tee -a "$LOG_FILE"
}

log_error() {
  local msg
  msg="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*"
  echo "$msg" | tee -a "$LOG_FILE" >&2
}

# Source logo display if available
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/logo.sh" ]]; then
  . "$(dirname "${BASH_SOURCE[0]}")/logo.sh"
fi

# Detectează mediul de rulare: WSL, Docker, Proxmox, Debian, Ubuntu
detect_environment() {
  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    echo "WSL"
  elif [ -f /.dockerenv ] || grep -qa docker /proc/1/cgroup 2>/dev/null; then
    echo "DOCKER"
  elif [ -f /etc/pve ]; then
    echo "PROXMOX"
  elif [ -f /etc/debian_version ]; then
    if grep -qi ubuntu /etc/os-release 2>/dev/null; then
      echo "UBUNTU"
    else
      echo "DEBIAN"
    fi
  else
    echo "UNKNOWN"
  fi
}
