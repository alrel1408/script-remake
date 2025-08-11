#!/bin/bash

# AlrelShop VPN Script Installer with API Integration
# Version: 2.0 (Remake)
# Author: AlrelShop

Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
GREENBG="\033[42;37m"
REDBG="\033[41;37m"
OK="${Green}  »${FONT}"
ERROR="${RED}[ERROR]${FONT}"
GRAY="\e[1;30m"
NC='\e[0m'
red='\e[1;31m'
green='\e[0;32m'

clear

# Banner
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Developer » ALRELSHOP࿐${YELLOW}(${NC}${green} API Remake Edition ${NC}${YELLOW})${NC}"
echo -e "  » This Will Setup VPN Server with API Integration"
echo -e "  Pembuat : ${green}AlrelShop࿐® ${NC}"
echo -e "  ©SCRIPT REMAKE WITH API ${YELLOW}(${NC} 2024 ${YELLOW})${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
sleep 2

# Checking Architecture
if [[ $( uname -m | awk '{print $1}' ) == "x86_64" ]]; then
    echo -e "${OK} Your Architecture Is Supported ( ${green}$( uname -m )${NC} )"
else
    echo -e "${ERROR} Your Architecture Is Not Supported ( ${YELLOW}$( uname -m )${NC} )"
    exit 1
fi

# Checking System
if [[ $( cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g' ) == "ubuntu" ]]; then
    OS_VERSION=$(cat /etc/os-release | grep -w VERSION_ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/VERSION_ID//g')
    if [[ $OS_VERSION == "18.04" ]] || [[ $OS_VERSION == "20.04" ]] || [[ $OS_VERSION == "22.04" ]] || [[ $OS_VERSION == "24.04" ]] || [[ $OS_VERSION == "25.04" ]]; then
        echo -e "${OK} Your OS Is Supported ( ${green}$( cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g' )${NC} )"
    else
        echo -e "${ERROR} Your Ubuntu Version Is Not Supported ( ${YELLOW}$OS_VERSION${NC} )"
        exit 1
    fi
elif [[ $( cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g' ) == "debian" ]]; then
    OS_VERSION=$(cat /etc/os-release | grep -w VERSION_ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/VERSION_ID//g')
    if [[ $OS_VERSION == "9" ]] || [[ $OS_VERSION == "10" ]] || [[ $OS_VERSION == "11" ]] || [[ $OS_VERSION == "12" ]]; then
        echo -e "${OK} Your OS Is Supported ( ${green}$( cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g' )${NC} )"
    else
        echo -e "${ERROR} Your Debian Version Is Not Supported ( ${YELLOW}$OS_VERSION${NC} )"
        exit 1
    fi
else
    echo -e "${ERROR} Your OS Is Not Supported"
    exit 1
fi

# IP Address Validating
export IP=$( curl -sS icanhazip.com )
if [[ $IP == "" ]]; then
    echo -e "${ERROR} IP Address ( ${YELLOW}Not Detected${NC} )"
else
    echo -e "${OK} IP Address ( ${green}$IP${NC} )"
fi

echo ""
read -p "$( echo -e "Press ${GRAY}[ ${NC}${green}Enter${NC} ${GRAY}]${NC} For Starting Installation") "
echo ""
clear

# Check if running as root
if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as root"
    exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo "OpenVZ is not supported"
    exit 1
fi

# Install dependencies
echo -e "${green}Installing dependencies...${NC}"
apt update
apt install ruby -y
gem install lolcat
apt install wondershaper -y
apt install curl wget screen rsync ca-certificates lsb-release -y
apt install python3 python3-pip python3-venv -y

clear

# Install original VPN script first
echo -e "${green}Installing base VPN script...${NC}"
mkdir -p /tmp/vpn-install
cd /tmp/vpn-install

# Download and install base script
wget -q https://raw.githubusercontent.com/alrel1408/scriptaku/main/ubu20-deb10-stable.sh
chmod +x ubu20-deb10-stable.sh

# Run base installation (with modifications for API)
echo -e "${green}Running base VPN installation...${NC}"
./ubu20-deb10-stable.sh

clear

# Install API Server
echo -e "${green}Installing VPN API Server...${NC}"

# Create API directory
mkdir -p /etc/vpn-api
mkdir -p /opt/vpn-api
mkdir -p /var/log/vpn-api

# Copy API files
echo -e "${green}Setting up API files...${NC}"
cd /opt/vpn-api

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.3
Flask-CORS==4.0.0
gunicorn==21.2.0
requests==2.31.0
EOF

# Create main API app
cat > app.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VPN Management API Server
Dibuat untuk AlrelShop VPN Panel
Author: AlrelShop
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess
import json
import os
import datetime
from functools import wraps
import hashlib
import secrets

app = Flask(__name__)
CORS(app)

# Konfigurasi API
API_CONFIG = {
    'api_key': None,
    'port': 5000,
    'host': '0.0.0.0',
    'debug': False
}

# Load konfigurasi dari file
def load_config():
    config_file = '/etc/vpn-api/config.json'
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            global API_CONFIG
            API_CONFIG.update(json.load(f))

# Middleware untuk autentikasi API key
def require_api_key(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.headers.get('X-API-Key') or request.args.get('api_key')
        if not api_key or api_key != API_CONFIG.get('api_key'):
            return jsonify({
                'success': False,
                'message': 'API key tidak valid',
                'error': 'Unauthorized'
            }), 401
        return f(*args, **kwargs)
    return decorated_function

# Helper function untuk menjalankan bash command
def run_bash_command(command, timeout=30):
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return {
            'success': result.returncode == 0,
            'stdout': result.stdout.strip(),
            'stderr': result.stderr.strip(),
            'returncode': result.returncode
        }
    except subprocess.TimeoutExpired:
        return {
            'success': False,
            'stdout': '',
            'stderr': 'Command timeout',
            'returncode': -1
        }
    except Exception as e:
        return {
            'success': False,
            'stdout': '',
            'stderr': str(e),
            'returncode': -1
        }

@app.route('/', methods=['GET'])
def index():
    return jsonify({
        'success': True,
        'message': 'VPN Management API Server',
        'version': '1.0.0',
        'author': 'AlrelShop',
        'endpoints': {
            'ssh': {
                'create': '/api/ssh/create',
                'renew': '/api/ssh/renew',
                'delete': '/api/ssh/delete',
                'list': '/api/ssh/list'
            },
            'trojan': {
                'create': '/api/trojan/create',
                'renew': '/api/trojan/renew', 
                'delete': '/api/trojan/delete',
                'list': '/api/trojan/list'
            }
        }
    })

# SSH Endpoints (simplified for installer)
@app.route('/api/ssh/create', methods=['POST'])
@require_api_key
def create_ssh():
    data = request.get_json()
    username = data.get('username')
    duration = data.get('duration', 30)
    quota = data.get('quota', 9999)
    ip_limit = data.get('ip_limit', 2)
    password = data.get('password', secrets.token_urlsafe(8))
    
    command = f'''
    if id "{username}" &>/dev/null; then
        echo "ERROR: User exists"
        exit 1
    fi
    
    useradd -e $(date -d "+{duration} days" +%Y-%m-%d) -s /bin/false -M {username}
    echo "{username}:{password}" | chpasswd
    
    domain=$(cat /etc/xray/domain 2>/dev/null || hostname -I | awk '{{print $1}}')
    
    echo "SUCCESS"
    echo "Username: {username}"
    echo "Password: {password}"
    echo "Domain: $domain"
    echo "Duration: {duration} days"
    echo "Quota: {quota} GB"
    echo "Expired: $(date -d '+{duration} days' '+%d %b %Y')"
    '''
    
    result = run_bash_command(command)
    
    if result['success'] and 'SUCCESS' in result['stdout']:
        lines = result['stdout'].split('\n')
        response_data = {}
        for line in lines:
            if ':' in line and 'SUCCESS' not in line:
                key, value = line.split(':', 1)
                response_data[key.strip().lower().replace(' ', '_')] = value.strip()
        
        return jsonify({
            'success': True,
            'message': 'SSH account created successfully',
            'data': response_data
        })
    else:
        return jsonify({
            'success': False,
            'message': 'Failed to create SSH account',
            'error': result['stderr'] or result['stdout']
        }), 500

if __name__ == '__main__':
    load_config()
    app.run(
        host=API_CONFIG['host'],
        port=API_CONFIG['port'],
        debug=API_CONFIG['debug']
    )
EOF

# Setup Python virtual environment
echo -e "${green}Setting up Python virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Generate API key and create config
echo -e "${green}Generating API configuration...${NC}"
API_KEY=$(openssl rand -hex 32)

cat > /etc/vpn-api/config.json << EOF
{
    "api_key": "$API_KEY",
    "port": 5000,
    "host": "0.0.0.0",
    "debug": false
}
EOF

# Create systemd service
echo -e "${green}Creating systemd service...${NC}"
cat > /etc/systemd/system/vpn-api.service << 'EOF'
[Unit]
Description=VPN Management API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vpn-api
Environment=PATH=/opt/vpn-api/venv/bin
ExecStart=/opt/vpn-api/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 4 --timeout 60 app:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start API service
systemctl daemon-reload
systemctl enable vpn-api
systemctl start vpn-api

# Install updated menu scripts
echo -e "${green}Installing updated menu scripts...${NC}"
mkdir -p /usr/local/bin/vpn-menu

# Download menu scripts from remake folder
SCRIPT_BASE="https://raw.githubusercontent.com/alrel1408/script-remake/main/menu"

# Download main menu scripts
wget -q -O /usr/local/bin/addssh "$SCRIPT_BASE/addssh"
wget -q -O /usr/local/bin/addtr "$SCRIPT_BASE/addtr"
wget -q -O /usr/local/bin/renewssh "$SCRIPT_BASE/renewssh"

chmod +x /usr/local/bin/addssh
chmod +x /usr/local/bin/addtr
chmod +x /usr/local/bin/renewssh

# Create symlinks for easy access
ln -sf /usr/local/bin/addssh /usr/bin/addssh
ln -sf /usr/local/bin/addtr /usr/bin/addtr
ln -sf /usr/local/bin/renewssh /usr/bin/renewssh

# Create API management command
cat > /usr/local/bin/requestapi << 'EOF'
#!/bin/bash

# API Key Display Script
API_CONFIG="/etc/vpn-api/config.json"

if [ -f "$API_CONFIG" ]; then
    API_KEY=$(grep -o '"api_key": "[^"]*"' $API_CONFIG | cut -d'"' -f4)
    API_STATUS=$(systemctl is-active vpn-api)
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                    VPN API INFORMATION                   "
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "API Key    : $API_KEY"
    echo "API URL    : http://$(curl -s icanhazip.com):5000"
    echo "Status     : $API_STATUS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Salin API Key dan URL di atas untuk digunakan di panel web Anda"
else
    echo "API configuration not found!"
fi
EOF

chmod +x /usr/local/bin/requestapi
ln -sf /usr/local/bin/requestapi /usr/bin/requestapi

# Setup firewall for API port
echo -e "${green}Configuring firewall...${NC}"
ufw allow 5000/tcp

# Clean up
cd /
rm -rf /tmp/vpn-install

clear

# Installation complete
echo -e "${GREENBG}                                                        ${NC}"
echo -e "${GREENBG}          ✅ INSTALASI BERHASIL DISELESAIKAN ✅          ${NC}"
echo -e "${GREENBG}                                                        ${NC}"
echo ""
echo -e "${green}🎉 AlrelShop VPN Script dengan API telah berhasil diinstall!${NC}"
echo ""
echo -e "${YELLOW}📝 INFORMASI PENTING:${NC}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${green}🔑 API Key     : ${YELLOW}$API_KEY${NC}"
echo -e "${green}🌐 API URL     : ${YELLOW}http://$IP:5000${NC}"
echo -e "${green}📋 Web Panel   : Upload file web/index.html ke hosting Anda${NC}"
echo -e "${green}⚡ Get API Info : ${YELLOW}requestapi${NC}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}🚀 CARA PENGGUNAAN:${NC}"
echo -e "${green}1. Upload file 'web/index.html' ke hosting/panel web Anda${NC}"
echo -e "${green}2. Buka panel web dan masukkan API URL dan API Key${NC}"
echo -e "${green}3. Sekarang Anda bisa membuat akun VPN dari web!${NC}"
echo ""
echo -e "${YELLOW}📞 SUPPORT:${NC}"
echo -e "${green}Telegram: @alrelshop${NC}"
echo -e "${green}GitHub: https://github.com/alrel1408/script-remake${NC}"
echo ""
echo -e "${green}Reboot server dalam 10 detik...${NC}"
sleep 10
reboot

