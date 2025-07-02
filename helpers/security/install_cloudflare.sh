#!/bin/bash
#
# install_cloudflare.sh - Part of LOMP Stack v3.0
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
# install_cloudflare.sh - Instalează Cloudflare Tunnel (opțional)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"
. "$UTILS_DIR/functions.sh"
. "$UTILS_DIR/lang.sh"
color_echo cyan "$(tr_lang cf_install)"

# Instalează cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Parametri user/domain
DOMAIN_CREATED="$2"
CF_DIR="$HOME/.cloudflared"
mkdir -p "$CF_DIR"

# 1. Asigură autentificarea cloudflared (o singură dată/manual)
if ! cloudflared tunnel list &>/dev/null; then
  color_echo cyan "[INFO] Se deschide browserul pentru autentificare Cloudflare (o singură dată per server). Continuă în browser..."
  cloudflared tunnel login || { color_echo red "[EROARE] Autentificare Cloudflare eșuată!"; exit 1; }
fi

# 2. Creează tunel nou pentru domeniu (dacă nu există deja)
TUNNEL_NAME="$DOMAIN_CREATED"
TUNNEL_ID=$(cloudflared tunnel list | awk -F',' -v dom="$TUNNEL_NAME" 'NR>1 && $2==dom {print $1}')
if [ -z "$TUNNEL_ID" ]; then
  TUNNEL_ID=$(cloudflared tunnel create "$TUNNEL_NAME" | grep -oE 'Tunnel ID: ([a-z0-9-]+)' | awk '{print $3}')
  color_echo green "[OK] Tunel Cloudflare creat pentru $TUNNEL_NAME ($TUNNEL_ID)"
else
  color_echo cyan "[INFO] Tunelul Cloudflare pentru $TUNNEL_NAME există deja ($TUNNEL_ID)"
fi

# 3. Găsește fișierul de credentiale
CRED_FILE=$(find "$CF_DIR" -name "$TUNNEL_ID.json" | head -n1)
if [ ! -f "$CRED_FILE" ]; then
  color_echo red "[EROARE] Fișierul de credentiale $TUNNEL_ID.json nu a fost găsit! Verifică cloudflared tunnel create."
  exit 1
fi

# 4. Generează config.yml personalizat
CF_CONFIG="$CF_DIR/config.yml"
cat > "$CF_CONFIG" <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CRED_FILE
ingress:
  - hostname: $DOMAIN_CREATED
    service: http://localhost:80
  - service: http_status:404
EOF
color_echo green "[OK] config.yml generat pentru $DOMAIN_CREATED."

# 5. Instalează serviciul cloudflared pentru tunel
sudo cloudflared service install "$TUNNEL_ID"
color_echo green "[OK] Cloudflare Tunnel configurat și serviciul instalat pentru $DOMAIN_CREATED."

color_echo green "$(tr_lang cf_done)"

install_cloudflare_tunnel_if_confirmed() {
  local username="$1"
  local domain="$2"
  if [[ "$STACK_CF_TUNNEL" == "1" ]]; then
    bash "$(dirname "$0")/../security/install_cloudflare.sh" "$username" "$domain"
    if pgrep -f "cloudflared.*$domain" >/dev/null 2>&1 || sudo systemctl is-active --quiet cloudflared; then
      echo "[INFO] Tunel Cloudflare activ pentru $domain. Se va folosi tunelul în loc de SSL Let's Encrypt."
      export STACK_CF_TUNNEL=1
      echo "STACK_CF_TUNNEL=1" >> /tmp/stack_user_env
    else
      export STACK_CF_TUNNEL=0
      echo "STACK_CF_TUNNEL=0" >> /tmp/stack_user_env
      echo "[INFO] Tunel Cloudflare nu este activ. Se va folosi SSL Let's Encrypt dacă este posibil."
    fi
  fi
}
