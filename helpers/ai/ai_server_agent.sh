#!/bin/bash
#
# ai_server_agent.sh - Part of LOMP Stack v3.0
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
# ai_server_agent.sh - Instalează AI Dashboard (opțional)


# Source translation system
. "$(dirname "$0")/functions.sh"
. "$(dirname "$0")/lang.sh"
color_echo cyan "$(tr_lang ai_agent_install)"


# Instalare Node.js + git
color_echo cyan "$(tr_lang ai_agent_nodegit)"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs git

# Creează directorul cu permisiuni corecte
sudo mkdir -p /opt/ai-dashboard-demo
sudo chown $USER:$USER /opt/ai-dashboard-demo


git clone https://github.com/example/ai-dashboard-demo.git /opt/ai-dashboard-demo || color_echo yellow "$(tr_lang ai_agent_clone_fail)"
cd /opt/ai-dashboard-demo || { color_echo red "$(tr_lang ai_agent_cd_fail)"; exit 0; }
npm install || color_echo yellow "$(tr_lang ai_agent_npm_fail)"
npm run build || color_echo yellow "$(tr_lang ai_agent_build_fail)"

# Creează un serviciu systemd demo
cat <<EOF | sudo tee /etc/systemd/system/ai_dashboard.service
[Unit]
Description=AI Dashboard Demo
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/ai-dashboard-demo
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ai_dashboard
sudo systemctl start ai_dashboard

color_echo green "$(tr_lang ai_agent_done)"
