#!/bin/bash
#
# install_redis.sh - Part of LOMP Stack v3.0
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
# install_redis.sh - Instalează Redis Cache (opțional)


# Stabilire director utilitare robust (bazat pe BASH_SOURCE)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"
. "$UTILS_DIR/lang.sh"
. "$UTILS_DIR/functions.sh"

# Instalează și configurează Redis, cu test pe socket și TCP
install_redis() {
  # === MOD: Configurare Redis doar pe socket (fără TCP) ===
  # Verificare și instalare redis-server dacă lipsește
  if ! command -v redis-server >/dev/null 2>&1; then
    color_echo cyan "[INFO] Redis nu este instalat. Se încearcă instalarea..."
    sudo apt update && sudo apt install -y redis-server
    if ! command -v redis-server >/dev/null 2>&1; then
      color_echo red "[EROARE] Instalarea Redis a eșuat! Se omite configurarea."
      return 1
    fi
    color_echo green "[OK] Redis a fost instalat. Continuăm cu configurarea."
  fi
  # ...eliminat mesaj redundant despre configurare socket-only...
  # Verifică existența fișierului de configurare
  if [ ! -f /etc/redis/redis.conf ]; then
    color_echo cyan "[INFO] Fișierul /etc/redis/redis.conf nu există. Se omite configurarea Redis. (Nu se afișează warning inutil)"
    return 0
  fi
  # Permite mod dual (TCP+socket) sau doar socket (port 0) prin parametru: install_redis [socket-only]
  local mode="${1:-socket-only}"
  if [[ "$mode" == "socket-only" ]]; then
    # ...configurare silentioasă pentru socket-only...
    sudo sed -i 's/^port .*/port 0/' /etc/redis/redis.conf
  elif [[ "$mode" == "tcp-only" ]]; then
    color_echo cyan "[INFO] Configurare Redis doar pe TCP (port 6379, fără socket)."
    sudo sed -i 's/^port .*/port 6379/' /etc/redis/redis.conf
    sudo sed -i '/^unixsocket /d' /etc/redis/redis.conf
    sudo sed -i '/^unixsocketperm /d' /etc/redis/redis.conf
  else
    color_echo cyan "[INFO] Configurare Redis cu TCP (port 6379) și socket."
    sudo sed -i 's/^port .*/port 6379/' /etc/redis/redis.conf
    sudo sed -i 's|^#* *unixsocket .*|unixsocket /run/redis/redis.sock|' /etc/redis/redis.conf
    sudo sed -i 's|^#* *unixsocketperm .*|unixsocketperm 770|' /etc/redis/redis.conf
  fi
  # Asigură existența directorului pentru socket
  if [ ! -d /run/redis ]; then
    sudo mkdir -p /run/redis
    sudo chown redis:redis /run/redis
    sudo chmod 755 /run/redis
    color_echo cyan "[INFO] Directorul pentru socket /run/redis a fost creat."
  fi

  # Asigură existența directorului de lucru Redis (pentru WSL și nu numai)
  if [ ! -d /var/lib/redis ]; then
    sudo mkdir -p /var/lib/redis
    sudo chown redis:redis /var/lib/redis
  fi
  # Asigură existența directorului de log Redis (pentru WSL și nu numai)
  if [ ! -d /var/log/redis ]; then
    sudo mkdir -p /var/log/redis
    sudo chown redis:redis /var/log/redis
  fi
  # Adaugă utilizatorul curent în grupul redis (dacă nu e deja)
  if ! id -nG "$USER" | grep -qw redis; then
    sudo usermod -aG redis "$USER"
    color_echo cyan "[INFO] Utilizatorul $USER a fost adăugat în grupul redis. Deconectează-te și reconectează-te pentru ca modificarea să aibă efect."
  fi
  # Restart Redis (systemd sau manual pentru WSL)
  if grep -qi microsoft /proc/version 2>/dev/null; then
    sudo pkill redis-server 2>/dev/null || true
    # Asigură că directoarele Redis există în WSL
    sudo mkdir -p /var/run/redis /var/lib/redis /var/log/redis
    sudo chown redis:redis /var/run/redis /var/lib/redis /var/log/redis
    # Pornește Redis în background
    nohup sudo redis-server /etc/redis/redis.conf > "$HOME/redis_wsl.log" 2>&1 &
    sleep 3
    # Asigură pornirea automată la login shell (doar dacă nu există deja)
    setup_redis_autostart_wsl
  else
    sudo systemctl restart redis-server || sudo systemctl restart redis || true
    sleep 2
  fi
  # Testare socket principal strict pentru socket-only
  if [[ "$mode" == "socket-only" ]]; then
    if [ -S /run/redis/redis.sock ]; then
      if redis-cli -s /run/redis/redis.sock ping | grep -q PONG; then
        color_echo green "[Redis] Socket OK (/run/redis/redis.sock): FUNCȚIONAL (PONG)"
        color_echo cyan "[INFO] Configurare Redis doar pe socket finalizată. Pentru acces, folosește: redis-cli -s /run/redis/redis.sock"
        return 0
      else
        color_echo red   "[Redis] Socket există dar nu răspunde corect (NU FUNCȚIONEAZĂ)"
        return 1
      fi
    fi
    # Fallback: verifică socketul clasic
    if [ -S /var/run/redis/redis-server.sock ]; then
      if redis-cli -s /var/run/redis/redis-server.sock ping | grep -q PONG; then
        color_echo yellow "[Redis] Socketul /run/redis/redis.sock nu a fost creat, dar /var/run/redis/redis-server.sock este FUNCȚIONAL. Pentru acces, folosește: redis-cli -s /var/run/redis/redis-server.sock"
        return 0
      else
        color_echo red   "[Redis] Socketul /var/run/redis/redis-server.sock există dar nu răspunde corect (NU FUNCȚIONEAZĂ)"
        return 1
      fi
    fi
    color_echo red "[Redis] Niciun socket Unix nu a fost creat sau nu funcționează! Verifică logurile Redis. (log: $HOME/redis_wsl.log)"
    return 1
  fi

  # Backup configurație Redis
  if [ -f /etc/redis/redis.conf ]; then
    sudo cp /etc/redis/redis.conf "/etc/redis/redis.conf.backup.dual.$(date +%Y%m%d_%H%M%S)"
    color_echo cyan "[INFO] Backup configurație Redis salvat."
  fi

  # Configurare duală: TCP + socket (asigură liniile corecte în config)
  sudo sed -i 's|^#* *unixsocket .*|unixsocket /var/run/redis/redis-server.sock|' /etc/redis/redis.conf
  sudo sed -i 's|^#* *unixsocketperm .*|unixsocketperm 770|' /etc/redis/redis.conf
  sudo sed -i 's|^bind .*|bind 127.0.0.1 ::1|' /etc/redis/redis.conf
  sudo sed -i 's|^# *port .*|port 6379|' /etc/redis/redis.conf

  color_echo cyan "$(tr_lang redis_install)"
  log_info "$(tr_lang redis_install)"
  sudo apt update && sudo apt install -y redis-server php-redis || { log_error "Redis install failed"; return 1; }

  # Detectează dacă rulează în WSL
  if grep -qi microsoft /proc/version 2>/dev/null; then
    color_echo cyan "[INFO] Detectat WSL: configurare Redis pentru socket și TCP (fără systemd)"
    sudo pkill redis-server 2>/dev/null || true
    nohup sudo redis-server /etc/redis/redis.conf > "$HOME/redis_wsl.log" 2>&1 &
    sleep 2
    # Testare TCP
    if redis-cli ping >/dev/null 2>&1; then
      color_echo green "[WSL] Redis TCP (127.0.0.1:6379): FUNCȚIONAL"
    else
      color_echo red   "[WSL] Redis TCP: NU FUNCȚIONEAZĂ"
    fi
    # Testare socket
    if [ -S /var/run/redis/redis-server.sock ]; then
      if redis-cli -s /var/run/redis/redis-server.sock ping >/dev/null 2>&1; then
        color_echo green "[WSL] Redis Socket (/var/run/redis/redis-server.sock): FUNCȚIONAL"
      else
        color_echo red   "[WSL] Redis Socket: NU FUNCȚIONEAZĂ (deși fișierul există)"
      fi
    else
      color_echo yellow "[WSL] Redis Socket: NU A FOST CREAT (limitare WSL, folosește TCP)"
    fi
    color_echo yellow "[WSL] Redis a fost configurat pentru rulare manuală. Pentru a porni Redis, folosește:"
    color_echo yellow "    sudo redis-server /etc/redis/redis.conf &"
    color_echo yellow "Poți adăuga această comandă în ~/.bashrc sau să o rulezi la fiecare sesiune."
  else
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
    sleep 2
    # Testare TCP
    if redis-cli ping >/dev/null 2>&1; then
      color_echo green "[Redis] TCP (127.0.0.1:6379): FUNCȚIONAL"
    else
      color_echo red   "[Redis] TCP: NU FUNCȚIONEAZĂ"
    fi
    # Testare socket
    if [ -S /var/run/redis/redis-server.sock ]; then
      if redis-cli -s /var/run/redis/redis-server.sock ping >/dev/null 2>&1; then
        color_echo green "[Redis] Socket (/var/run/redis/redis-server.sock): FUNCȚIONAL"
      else
        color_echo red   "[Redis] Socket: NU FUNCȚIONEAZĂ (deși fișierul există)"
      fi
    else
      color_echo yellow "[Redis] Socket: NU A FOST CREAT (verifică permisiuni/config)"
    fi
  fi

  color_echo cyan "[INFO] Configurare Redis dual mode completă. TCP și socket verificate."

  # ...health-check eliminat, se face doar din monitoring...

  # ...existing code...
}

# Configurează pornirea automată Redis în WSL prin ~/.bashrc
setup_redis_autostart_wsl() {
  local bashrc_file="$HOME/.bashrc"
  local redis_start_cmd="# Auto-start Redis for WordPress Stack (WSL)
if ! pgrep redis-server >/dev/null 2>&1; then
  nohup sudo redis-server /etc/redis/redis.conf >/dev/null 2>&1 &
fi"
  
  # Verifică dacă nu există deja configurarea
  if ! grep -q "Auto-start Redis for WordPress Stack" "$bashrc_file" 2>/dev/null; then
    echo "$redis_start_cmd" >> "$bashrc_file"
    color_echo cyan "[INFO] Redis va porni automat la următoarele sesiuni WSL."
  fi
}

# Execută instalarea la rulare directă
type install_redis &>/dev/null && install_redis "dual"
