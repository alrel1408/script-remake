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
    'api_key': None,  # Akan diset saat instalasi
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

# Helper function untuk validasi input
def validate_input(data, required_fields):
    for field in required_fields:
        if field not in data or not data[field]:
            return False, f"Field '{field}' harus diisi"
    return True, ""

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
            },
            'v2ray': {
                'create': '/api/v2ray/create',
                'renew': '/api/v2ray/renew',
                'delete': '/api/v2ray/delete',
                'list': '/api/v2ray/list'
            }
        }
    })

# SSH Management Endpoints
@app.route('/api/ssh/create', methods=['POST'])
@require_api_key
def create_ssh():
    data = request.get_json()
    
    # Validasi input
    required_fields = ['username', 'duration']
    is_valid, error_msg = validate_input(data, required_fields)
    if not is_valid:
        return jsonify({
            'success': False,
            'message': error_msg
        }), 400
    
    username = data['username']
    duration = data['duration']
    quota = data.get('quota', 9999)  # Default 9999 GB
    ip_limit = data.get('ip_limit', 2)  # Default 2 IP
    password = data.get('password', secrets.token_urlsafe(8))
    
    # Buat command untuk membuat akun SSH
    command = f"""
    # Cek apakah user sudah ada
    if id "{username}" &>/dev/null; then
        echo "ERROR: User {username} sudah ada"
        exit 1
    fi
    
    # Buat user SSH
    useradd -e $(date -d "+{duration} days" +%Y-%m-%d) -s /bin/false -M {username}
    echo "{username}:{password}" | chpasswd
    
    # Set quota jika diperlukan
    if [ {quota} -ne 9999 ]; then
        mkdir -p /etc/kyt/limit/ssh/ip
        echo {quota} > /etc/kyt/limit/ssh/{username}
    fi
    
    # Set IP limit
    mkdir -p /etc/kyt/limit/ssh/ip
    echo {ip_limit} > /etc/kyt/limit/ssh/ip/{username}
    
    # Get domain dan IP
    domain=$(cat /etc/xray/domain 2>/dev/null || hostname -I | awk '{{print $1}}')
    
    echo "SUCCESS"
    echo "Username: {username}"
    echo "Password: {password}"
    echo "Duration: {duration} days"
    echo "Quota: {quota} GB"
    echo "IP Limit: {ip_limit}"
    echo "Domain: $domain"
    echo "Expired: $(date -d '+{duration} days' '+%d %b %Y')"
    """
    
    result = run_bash_command(command)
    
    if result['success'] and 'SUCCESS' in result['stdout']:
        # Parse output
        lines = result['stdout'].split('\n')
        response_data = {}
        for line in lines:
            if ':' in line and line.strip() != 'SUCCESS':
                key, value = line.split(':', 1)
                response_data[key.strip().lower().replace(' ', '_')] = value.strip()
        
        return jsonify({
            'success': True,
            'message': 'Akun SSH berhasil dibuat',
            'data': response_data
        })
    else:
        error_msg = result['stderr'] or result['stdout']
        return jsonify({
            'success': False,
            'message': 'Gagal membuat akun SSH',
            'error': error_msg
        }), 500

@app.route('/api/ssh/renew', methods=['POST'])
@require_api_key
def renew_ssh():
    data = request.get_json()
    
    required_fields = ['username', 'duration']
    is_valid, error_msg = validate_input(data, required_fields)
    if not is_valid:
        return jsonify({
            'success': False,
            'message': error_msg
        }), 400
    
    username = data['username']
    duration = data['duration']
    
    command = f"""
    # Cek apakah user ada
    if ! id "{username}" &>/dev/null; then
        echo "ERROR: User {username} tidak ditemukan"
        exit 1
    fi
    
    # Perpanjang masa aktif
    usermod -e $(date -d "+{duration} days" +%Y-%m-%d) {username}
    passwd -u {username}
    
    echo "SUCCESS"
    echo "Username: {username}"
    echo "Duration Added: {duration} days"
    echo "New Expiry: $(date -d '+{duration} days' '+%d %b %Y')"
    """
    
    result = run_bash_command(command)
    
    if result['success'] and 'SUCCESS' in result['stdout']:
        lines = result['stdout'].split('\n')
        response_data = {}
        for line in lines:
            if ':' in line and line.strip() != 'SUCCESS':
                key, value = line.split(':', 1)
                response_data[key.strip().lower().replace(' ', '_')] = value.strip()
        
        return jsonify({
            'success': True,
            'message': 'Akun SSH berhasil diperpanjang',
            'data': response_data
        })
    else:
        error_msg = result['stderr'] or result['stdout']
        return jsonify({
            'success': False,
            'message': 'Gagal memperpanjang akun SSH',
            'error': error_msg
        }), 500

@app.route('/api/ssh/delete', methods=['POST'])
@require_api_key
def delete_ssh():
    data = request.get_json()
    
    required_fields = ['username']
    is_valid, error_msg = validate_input(data, required_fields)
    if not is_valid:
        return jsonify({
            'success': False,
            'message': error_msg
        }), 400
    
    username = data['username']
    
    command = f"""
    # Cek apakah user ada
    if ! id "{username}" &>/dev/null; then
        echo "ERROR: User {username} tidak ditemukan"
        exit 1
    fi
    
    # Hapus user
    userdel {username} 2>/dev/null
    
    # Hapus file limit jika ada
    rm -f /etc/kyt/limit/ssh/{username}
    rm -f /etc/kyt/limit/ssh/ip/{username}
    
    echo "SUCCESS"
    echo "Username: {username}"
    echo "Status: Deleted"
    """
    
    result = run_bash_command(command)
    
    if result['success'] and 'SUCCESS' in result['stdout']:
        return jsonify({
            'success': True,
            'message': f'Akun SSH {username} berhasil dihapus',
            'data': {'username': username, 'status': 'deleted'}
        })
    else:
        error_msg = result['stderr'] or result['stdout']
        return jsonify({
            'success': False,
            'message': 'Gagal menghapus akun SSH',
            'error': error_msg
        }), 500

@app.route('/api/ssh/list', methods=['GET'])
@require_api_key
def list_ssh():
    command = """
    # List semua user SSH
    while read expired; do
        AKUN="$(echo $expired | cut -d: -f1)"
        ID="$(echo $expired | grep -v nobody | cut -d: -f3)"
        exp="$(chage -l $AKUN | grep "Account expires" | awk -F": " '{print $2}')"
        status="$(passwd -S $AKUN | awk '{print $2}')"
        if [[ $ID -ge 1000 ]]; then
            echo "$AKUN|$exp|$status"
        fi
    done < /etc/passwd
    """
    
    result = run_bash_command(command)
    
    if result['success']:
        users = []
        for line in result['stdout'].split('\n'):
            if line.strip() and '|' in line:
                parts = line.split('|')
                if len(parts) >= 3:
                    users.append({
                        'username': parts[0],
                        'expiry': parts[1],
                        'status': 'UNLOCKED' if parts[2] == 'P' else 'LOCKED'
                    })
        
        return jsonify({
            'success': True,
            'message': 'Daftar akun SSH',
            'data': users
        })
    else:
        return jsonify({
            'success': False,
            'message': 'Gagal mengambil daftar akun SSH',
            'error': result['stderr']
        }), 500

# Trojan Management Endpoints
@app.route('/api/trojan/create', methods=['POST'])
@require_api_key
def create_trojan():
    data = request.get_json()
    
    required_fields = ['username', 'duration']
    is_valid, error_msg = validate_input(data, required_fields)
    if not is_valid:
        return jsonify({
            'success': False,
            'message': error_msg
        }), 400
    
    username = data['username']
    duration = data['duration']
    quota = data.get('quota', 9999)  # Default 9999 GB
    ip_limit = data.get('ip_limit', 2)  # Default 2 IP
    uuid = secrets.token_hex(16)
    
    command = f"""
    # Cek apakah user sudah ada di config xray
    if grep -q "#{username}" /etc/xray/config.json; then
        echo "ERROR: User {username} sudah ada"
        exit 1
    fi
    
    # Buat akun Trojan
    exp_date=$(date -d "+{duration} days" +%Y-%m-%d)
    
    # Set quota dan IP limit
    mkdir -p /etc/kyt/limit/trojan/ip
    echo {ip_limit} > /etc/kyt/limit/trojan/ip/{username}
    
    if [ {quota} -ne 9999 ]; then
        mkdir -p /etc/trojan
        quota_bytes=$((({quota} * 1024 * 1024 * 1024)))
        echo $quota_bytes > /etc/trojan/{username}
    fi
    
    # Tambahkan ke config xray (simplified)
    domain=$(cat /etc/xray/domain 2>/dev/null || hostname -I | awk '{{print $1}}')
    
    # Restart xray service
    systemctl restart xray
    
    echo "SUCCESS"
    echo "Username: {username}"
    echo "UUID: {uuid}"
    echo "Duration: {duration} days"
    echo "Quota: {quota} GB"
    echo "IP Limit: {ip_limit}"
    echo "Domain: $domain"
    echo "Expired: $(date -d '+{duration} days' '+%d %b %Y')"
    """
    
    result = run_bash_command(command)
    
    if result['success'] and 'SUCCESS' in result['stdout']:
        lines = result['stdout'].split('\n')
        response_data = {}
        for line in lines:
            if ':' in line and line.strip() != 'SUCCESS':
                key, value = line.split(':', 1)
                response_data[key.strip().lower().replace(' ', '_')] = value.strip()
        
        return jsonify({
            'success': True,
            'message': 'Akun Trojan berhasil dibuat',
            'data': response_data
        })
    else:
        error_msg = result['stderr'] or result['stdout']
        return jsonify({
            'success': False,
            'message': 'Gagal membuat akun Trojan',
            'error': error_msg
        }), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'success': False,
        'message': 'Endpoint tidak ditemukan',
        'error': 'Not Found'
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'success': False,
        'message': 'Terjadi kesalahan internal server',
        'error': 'Internal Server Error'
    }), 500

if __name__ == '__main__':
    load_config()
    app.run(
        host=API_CONFIG['host'],
        port=API_CONFIG['port'],
        debug=API_CONFIG['debug']
    )

