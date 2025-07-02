#!/bin/bash
#
# redis_config_helper.sh - Part of LOMP Stack v3.0
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
# redis_config_helper.sh - Funcții pentru configurare și test Redis (general, nu per user)
. "$(dirname "$0")/../utils/functions.sh"

# Setează socketul Redis (default: /var/run/redis/redis-server.sock)
set_redis_socket() {
  local socket="${1:-/var/run/redis/redis-server.sock}"
  sudo sed -i "s|^#* *unixsocket .*|unixsocket $socket|" /etc/redis/redis.conf
  sudo systemctl restart redis-server
  color_echo green "[Redis] Socket setat la $socket"
}

# Setează portul Redis (default: 6379)
set_redis_port() {
  local port="${1:-6379}"
  sudo sed -i "s|^# *port .*|port $port|" /etc/redis/redis.conf
  sudo systemctl restart redis-server
  color_echo green "[Redis] Port setat la $port"
}

# Activează/dezactivează requirepass (autentificare)
set_redis_password() {
  local pass="$1"
  if [[ -z "$pass" ]]; then
    sudo sed -i '/^requirepass /d' /etc/redis/redis.conf
    color_echo yellow "[Redis] requirepass dezactivat (fără parolă)"
  else
    sudo sed -i "/^requirepass /d" /etc/redis/redis.conf
    echo "requirepass $pass" | sudo tee -a /etc/redis/redis.conf > /dev/null
    color_echo green "[Redis] requirepass activat"
  fi
  sudo systemctl restart redis-server
}

# Testează conexiunea la Redis (TCP sau socket, cu/fără parolă)
test_redis_connection() {
  local mode="${1:-tcp}" pass="$2"
  if [[ "$mode" == "socket" ]]; then
    if [[ -n "$pass" ]]; then
      redis-cli -s /var/run/redis/redis-server.sock -a "$pass" ping
    else
      redis-cli -s /var/run/redis/redis-server.sock ping
    fi
  else
    if [[ -n "$pass" ]]; then
      redis-cli -h 127.0.0.1 -p 6379 -a "$pass" ping
    else
      redis-cli -h 127.0.0.1 -p 6379 ping
    fi
  fi
}

# Afișează statusul și configurarea curentă
show_redis_status() {
  sudo systemctl status redis-server
  sudo grep -E '^(port|unixsocket|requirepass)' /etc/redis/redis.conf || true
}
