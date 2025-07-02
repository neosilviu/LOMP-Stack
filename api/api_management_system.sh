#!/bin/bash
#
# api_management_system.sh - Part of LOMP Stack v3.0
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

#########################################################################
# LOMP Stack v2.0 - API Management System
# Enterprise-grade REST API with authentication, rate limiting, and webhooks
# 
# Features:
# - Complete REST API for all LOMP operations
# - JWT and API key authentication
# - Rate limiting and quota management
# - Webhook system for external integrations
# - Auto-generated API documentation
# - API analytics and monitoring
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

# Define print functions using color_echo
print_info() { color_echo cyan "[API-INFO] $*"; }
print_success() { color_echo green "[API-SUCCESS] $*"; }
print_warning() { color_echo yellow "[API-WARNING] $*"; }
print_error() { color_echo red "[API-ERROR] $*"; }

# API configuration
API_CONFIG="${SCRIPT_DIR}/api_config.json"
API_LOG="${SCRIPT_DIR}/../tmp/api_management.log"
API_PORT="${API_PORT:-8080}"
API_HOST="${API_HOST:-localhost}"
API_BASE_PATH="${API_BASE_PATH:-/api/v1}"

# Authentication configuration
JWT_SECRET_FILE="${SCRIPT_DIR}/auth/jwt_secret.key"
API_KEYS_FILE="${SCRIPT_DIR}/auth/api_keys.json"

# Webhook configuration
WEBHOOK_CONFIG="${SCRIPT_DIR}/webhooks/webhook_config.json"

#########################################################################
# Logging Function
#########################################################################
log_api() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$API_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize API Configuration
#########################################################################
init_api_config() {
    log_api "INFO" "Initializing API Management System configuration..."
    
    # Create API configuration
    cat > "$API_CONFIG" << 'EOF'
{
    "api": {
        "version": "1.0.0",
        "host": "localhost",
        "port": 8080,
        "base_path": "/api/v1",
        "ssl_enabled": false,
        "cors_enabled": true,
        "rate_limiting": {
            "enabled": true,
            "requests_per_minute": 100,
            "burst_limit": 20
        },
        "authentication": {
            "jwt_enabled": true,
            "api_key_enabled": true,
            "session_timeout": 3600
        },
        "logging": {
            "level": "info",
            "access_log": true,
            "error_log": true
        }
    },
    "endpoints": {
        "sites": {
            "enabled": true,
            "auth_required": true,
            "rate_limit": 50
        },
        "users": {
            "enabled": true,
            "auth_required": true,
            "rate_limit": 30
        },
        "backups": {
            "enabled": true,
            "auth_required": true,
            "rate_limit": 10
        },
        "monitoring": {
            "enabled": true,
            "auth_required": false,
            "rate_limit": 200
        }
    },
    "webhooks": {
        "enabled": true,
        "max_endpoints": 50,
        "retry_attempts": 3,
        "timeout": 30
    }
}
EOF
    
    log_api "SUCCESS" "API configuration initialized"
}

#########################################################################
# Install API Dependencies
#########################################################################
install_api_dependencies() {
    log_api "INFO" "Installing API dependencies..."
    
    # Install Node.js and npm if not present
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Install Python and pip if not present  
    if ! command -v python3 &> /dev/null; then
        print_info "Installing Python 3..."
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    fi
    
    # Install required Python packages
    pip3 install flask flask-jwt-extended flask-limiter flask-cors requests sqlite3
    
    # Install PM2 for process management
    sudo npm install -g pm2
    
    log_api "SUCCESS" "API dependencies installed"
}

#########################################################################
# Generate JWT Secret
#########################################################################
generate_jwt_secret() {
    log_api "INFO" "Generating JWT secret..."
    
    # Generate secure random secret
    openssl rand -base64 64 > "$JWT_SECRET_FILE"
    chmod 600 "$JWT_SECRET_FILE"
    
    log_api "SUCCESS" "JWT secret generated"
}

#########################################################################
# Initialize API Keys Database
#########################################################################
init_api_keys() {
    log_api "INFO" "Initializing API keys database..."
    
    # Create API keys configuration
    cat > "$API_KEYS_FILE" << 'EOF'
{
    "api_keys": [
        {
            "id": "admin-key-001",
            "key": "sk_live_admin_$(openssl rand -hex 32)",
            "name": "Admin Master Key",
            "permissions": ["*"],
            "rate_limit": 1000,
            "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
            "last_used": null,
            "active": true
        },
        {
            "id": "monitoring-key-001", 
            "key": "sk_live_monitor_$(openssl rand -hex 32)",
            "name": "Monitoring Key",
            "permissions": ["monitoring:read", "sites:read"],
            "rate_limit": 500,
            "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
            "last_used": null,
            "active": true
        }
    ]
}
EOF
    
    # Replace placeholders with actual values
    sed -i "s/\$(openssl rand -hex 32)/$(openssl rand -hex 32)/g" "$API_KEYS_FILE"
    sed -i "s/\$(date -u +%Y-%m-%dT%H:%M:%SZ)/$(date -u +%Y-%m-%dT%H:%M:%SZ)/g" "$API_KEYS_FILE"
    
    chmod 600 "$API_KEYS_FILE"
    log_api "SUCCESS" "API keys database initialized"
}

#########################################################################
# Create Main API Server
#########################################################################
create_api_server() {
    log_api "INFO" "Creating main API server..."
    
    cat > "${SCRIPT_DIR}/api_server.py" << 'EOF'
#!/usr/bin/env python3

import os
import json
import sqlite3
import subprocess
import hashlib
import time
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, g
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS
import logging

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
app.config['JWT_SECRET_KEY'] = open('/tmp/jwt_secret.key', 'r').read().strip()
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=1)

# Initialize extensions
jwt = JWTManager(app)
limiter = Limiter(app, key_func=get_remote_address)

# Logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

#########################################################################
# Authentication Functions
#########################################################################

def load_api_keys():
    """Load API keys from configuration file"""
    try:
        with open('auth/api_keys.json', 'r') as f:
            return json.load(f)
    except:
        return {"api_keys": []}

def validate_api_key(api_key):
    """Validate API key and return permissions"""
    keys_data = load_api_keys()
    for key_data in keys_data.get('api_keys', []):
        if key_data['key'] == api_key and key_data['active']:
            return key_data
    return None

def check_permission(key_data, required_permission):
    """Check if API key has required permission"""
    permissions = key_data.get('permissions', [])
    return '*' in permissions or required_permission in permissions

#########################################################################
# Rate Limiting Functions
#########################################################################

def init_rate_limit_db():
    """Initialize rate limiting database"""
    conn = sqlite3.connect('auth/rate_limits.db')
    conn.execute('''
        CREATE TABLE IF NOT EXISTS rate_limits (
            api_key TEXT PRIMARY KEY,
            requests INTEGER DEFAULT 0,
            window_start INTEGER
        )
    ''')
    conn.commit()
    conn.close()

def check_rate_limit(api_key, limit_per_minute=100):
    """Check if API key is within rate limits"""
    conn = sqlite3.connect('auth/rate_limits.db')
    cursor = conn.cursor()
    
    current_time = int(time.time())
    window_start = current_time - (current_time % 60)  # Start of current minute
    
    # Get current usage
    cursor.execute('SELECT requests, window_start FROM rate_limits WHERE api_key = ?', (api_key,))
    result = cursor.fetchone()
    
    if result:
        requests, last_window = result
        if last_window == window_start:
            if requests >= limit_per_minute:
                conn.close()
                return False
            # Increment counter
            cursor.execute('UPDATE rate_limits SET requests = requests + 1 WHERE api_key = ?', (api_key,))
        else:
            # New window, reset counter
            cursor.execute('UPDATE rate_limits SET requests = 1, window_start = ? WHERE api_key = ?', 
                         (window_start, api_key))
    else:
        # First request for this key
        cursor.execute('INSERT INTO rate_limits (api_key, requests, window_start) VALUES (?, 1, ?)', 
                     (api_key, window_start))
    
    conn.commit()
    conn.close()
    return True

#########################################################################
# API Authentication Decorator
#########################################################################

def api_auth_required(permission=None):
    """Decorator for API authentication and authorization"""
    def decorator(f):
        def decorated_function(*args, **kwargs):
            # Check for API key in headers
            api_key = request.headers.get('X-API-Key')
            
            if not api_key:
                return jsonify({'error': 'API key required'}), 401
            
            # Validate API key
            key_data = validate_api_key(api_key)
            if not key_data:
                return jsonify({'error': 'Invalid API key'}), 401
            
            # Check permission if specified
            if permission and not check_permission(key_data, permission):
                return jsonify({'error': 'Insufficient permissions'}), 403
            
            # Check rate limits
            rate_limit = key_data.get('rate_limit', 100)
            if not check_rate_limit(api_key, rate_limit):
                return jsonify({'error': 'Rate limit exceeded'}), 429
            
            # Add key data to request context
            g.api_key_data = key_data
            
            return f(*args, **kwargs)
        
        decorated_function.__name__ = f.__name__
        return decorated_function
    return decorator

#########################################################################
# Site Management Endpoints
#########################################################################

@app.route('/api/v1/sites', methods=['GET'])
@api_auth_required('sites:read')
def list_sites():
    """List all WordPress sites"""
    try:
        # Execute shell command to get sites
        result = subprocess.run(['bash', '../helpers/wp/wp_helpers.sh', 'list_sites'], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            sites = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    sites.append({'domain': line.strip()})
            
            return jsonify({
                'success': True,
                'data': {'sites': sites},
                'count': len(sites)
            })
        else:
            return jsonify({'error': 'Failed to retrieve sites'}), 500
    
    except Exception as e:
        logger.error(f"Error listing sites: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/sites', methods=['POST'])
@api_auth_required('sites:create')
def create_site():
    """Create a new WordPress site"""
    try:
        data = request.get_json()
        domain = data.get('domain')
        email = data.get('email')
        
        if not domain or not email:
            return jsonify({'error': 'Domain and email are required'}), 400
        
        # Execute site creation
        result = subprocess.run(['bash', '../component_manager.sh', 'install_wordpress', domain, email],
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            return jsonify({
                'success': True,
                'message': f'Site {domain} created successfully',
                'data': {'domain': domain, 'email': email}
            })
        else:
            return jsonify({'error': 'Failed to create site'}), 500
    
    except Exception as e:
        logger.error(f"Error creating site: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/sites/<domain>', methods=['DELETE'])
@api_auth_required('sites:delete')
def delete_site(domain):
    """Delete a WordPress site"""
    try:
        # Execute site deletion
        result = subprocess.run(['bash', '../helpers/wp/wp_helpers.sh', 'delete_site', domain],
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            return jsonify({
                'success': True,
                'message': f'Site {domain} deleted successfully'
            })
        else:
            return jsonify({'error': 'Failed to delete site'}), 500
    
    except Exception as e:
        logger.error(f"Error deleting site: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

#########################################################################
# Backup Management Endpoints
#########################################################################

@app.route('/api/v1/backups', methods=['GET'])
@api_auth_required('backups:read')
def list_backups():
    """List all backups"""
    try:
        result = subprocess.run(['bash', '../helpers/utils/backup_helpers.sh', 'list_backups'],
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            backups = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    backups.append({'name': line.strip()})
            
            return jsonify({
                'success': True,
                'data': {'backups': backups},
                'count': len(backups)
            })
        else:
            return jsonify({'error': 'Failed to retrieve backups'}), 500
    
    except Exception as e:
        logger.error(f"Error listing backups: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/backups', methods=['POST'])
@api_auth_required('backups:create')
def create_backup():
    """Create a new backup"""
    try:
        data = request.get_json()
        domain = data.get('domain')
        backup_type = data.get('type', 'full')
        
        if not domain:
            return jsonify({'error': 'Domain is required'}), 400
        
        # Execute backup creation
        result = subprocess.run(['bash', '../helpers/utils/backup_helpers.sh', 'create_backup', domain, backup_type],
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            return jsonify({
                'success': True,
                'message': f'Backup for {domain} created successfully',
                'data': {'domain': domain, 'type': backup_type}
            })
        else:
            return jsonify({'error': 'Failed to create backup'}), 500
    
    except Exception as e:
        logger.error(f"Error creating backup: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

#########################################################################
# System Monitoring Endpoints
#########################################################################

@app.route('/api/v1/system/status', methods=['GET'])
@limiter.limit("200 per minute")
def system_status():
    """Get system status"""
    try:
        # Get system information
        result = subprocess.run(['bash', '../helpers/monitoring/system_helpers.sh', 'get_system_info'],
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            return jsonify({
                'success': True,
                'data': {
                    'status': 'healthy',
                    'timestamp': datetime.utcnow().isoformat(),
                    'system_info': result.stdout.strip()
                }
            })
        else:
            return jsonify({'error': 'Failed to retrieve system status'}), 500
    
    except Exception as e:
        logger.error(f"Error getting system status: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/system/metrics', methods=['GET'])
@api_auth_required('monitoring:read')
def system_metrics():
    """Get detailed system metrics"""
    try:
        # Get detailed metrics
        result = subprocess.run(['bash', '../helpers/monitoring/system_helpers.sh', 'get_detailed_metrics'],
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            return jsonify({
                'success': True,
                'data': {
                    'metrics': result.stdout.strip(),
                    'timestamp': datetime.utcnow().isoformat()
                }
            })
        else:
            return jsonify({'error': 'Failed to retrieve system metrics'}), 500
    
    except Exception as e:
        logger.error(f"Error getting system metrics: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

#########################################################################
# Health Check Endpoint
#########################################################################

@app.route('/api/v1/health', methods=['GET'])
def health_check():
    """API health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat()
    })

#########################################################################
# Error Handlers
#########################################################################

@app.errorhandler(429)
def rate_limit_handler(e):
    return jsonify({'error': 'Rate limit exceeded', 'retry_after': '60'}), 429

@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({'error': 'Internal server error'}), 500

#########################################################################
# Initialize and Run
#########################################################################

if __name__ == '__main__':
    # Initialize rate limiting database
    init_rate_limit_db()
    
    # Copy JWT secret to temp location
    os.system('cp auth/jwt_secret.key /tmp/')
    
    # Run the application
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF
    
    chmod +x "${SCRIPT_DIR}/api_server.py"
    log_api "SUCCESS" "API server created"
}

#########################################################################
# Create API Documentation Generator
#########################################################################
create_api_documentation() {
    log_api "INFO" "Creating API documentation generator..."
    
    cat > "${SCRIPT_DIR}/generate_docs.py" << 'EOF'
#!/usr/bin/env python3

import json
from datetime import datetime

def generate_api_docs():
    """Generate API documentation in HTML format"""
    
    html_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LOMP Stack API Documentation</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .endpoint { background: #ecf0f1; margin: 10px 0; padding: 15px; border-radius: 5px; }
        .method { display: inline-block; padding: 5px 10px; border-radius: 3px; color: white; font-weight: bold; }
        .get { background: #27ae60; }
        .post { background: #3498db; }
        .delete { background: #e74c3c; }
        .put { background: #f39c12; }
        .code { background: #2c3e50; color: white; padding: 10px; border-radius: 3px; overflow-x: auto; }
        .example { background: #f8f9fa; padding: 10px; border-left: 4px solid #3498db; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 LOMP Stack API v1.0</h1>
        <p>Enterprise-grade REST API for WordPress LOMP Stack management</p>
        <p>Generated on: """ + datetime.now().strftime("%Y-%m-%d %H:%M:%S") + """</p>
    </div>
    
    <h2>🔐 Authentication</h2>
    <p>All API requests require authentication using an API key. Include the API key in the request header:</p>
    <div class="code">X-API-Key: your-api-key-here</div>
    
    <h2>📊 Rate Limiting</h2>
    <p>API requests are rate limited based on your API key. Default limits:</p>
    <ul>
        <li><strong>Admin keys:</strong> 1000 requests/minute</li>
        <li><strong>Monitoring keys:</strong> 500 requests/minute</li>
        <li><strong>Standard keys:</strong> 100 requests/minute</li>
    </ul>
    
    <h2>🌐 Endpoints</h2>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/health</h3>
        <p><strong>Description:</strong> Health check endpoint</p>
        <p><strong>Authentication:</strong> Not required</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "status": "healthy",
    "version": "1.0.0",
    "timestamp": "2025-07-01T10:30:00Z"
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/sites</h3>
        <p><strong>Description:</strong> List all WordPress sites</p>
        <p><strong>Authentication:</strong> Required (sites:read)</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "data": {
        "sites": [
            {"domain": "example.com"},
            {"domain": "test.com"}
        ]
    },
    "count": 2
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method post">POST</span> /api/v1/sites</h3>
        <p><strong>Description:</strong> Create a new WordPress site</p>
        <p><strong>Authentication:</strong> Required (sites:create)</p>
        <div class="example">
            <h4>Example Request:</h4>
            <div class="code">
{
    "domain": "newsite.com",
    "email": "admin@newsite.com"
}
            </div>
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "message": "Site newsite.com created successfully",
    "data": {
        "domain": "newsite.com",
        "email": "admin@newsite.com"
    }
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method delete">DELETE</span> /api/v1/sites/{domain}</h3>
        <p><strong>Description:</strong> Delete a WordPress site</p>
        <p><strong>Authentication:</strong> Required (sites:delete)</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "message": "Site example.com deleted successfully"
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/backups</h3>
        <p><strong>Description:</strong> List all backups</p>
        <p><strong>Authentication:</strong> Required (backups:read)</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "data": {
        "backups": [
            {"name": "backup_example_com_20250701.tar.gz"},
            {"name": "backup_test_com_20250630.tar.gz"}
        ]
    },
    "count": 2
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method post">POST</span> /api/v1/backups</h3>
        <p><strong>Description:</strong> Create a new backup</p>
        <p><strong>Authentication:</strong> Required (backups:create)</p>
        <div class="example">
            <h4>Example Request:</h4>
            <div class="code">
{
    "domain": "example.com",
    "type": "full"
}
            </div>
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "message": "Backup for example.com created successfully",
    "data": {
        "domain": "example.com",
        "type": "full"
    }
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/system/status</h3>
        <p><strong>Description:</strong> Get basic system status</p>
        <p><strong>Authentication:</strong> Not required</p>
        <p><strong>Rate Limit:</strong> 200/minute</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "data": {
        "status": "healthy",
        "timestamp": "2025-07-01T10:30:00Z",
        "system_info": "CPU: 25%, Memory: 60%, Disk: 45%"
    }
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/system/metrics</h3>
        <p><strong>Description:</strong> Get detailed system metrics</p>
        <p><strong>Authentication:</strong> Required (monitoring:read)</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "data": {
        "metrics": "Detailed system metrics...",
        "timestamp": "2025-07-01T10:30:00Z"
    }
}
            </div>
        </div>
    </div>
    
    <h2>❌ Error Responses</h2>
    <div class="example">
        <h4>401 Unauthorized:</h4>
        <div class="code">{"error": "API key required"}</div>
        
        <h4>403 Forbidden:</h4>
        <div class="code">{"error": "Insufficient permissions"}</div>
        
        <h4>429 Too Many Requests:</h4>
        <div class="code">{"error": "Rate limit exceeded", "retry_after": "60"}</div>
        
        <h4>500 Internal Server Error:</h4>
        <div class="code">{"error": "Internal server error"}</div>
    </div>
    
    <h2>📝 API Key Permissions</h2>
    <ul>
        <li><strong>sites:read</strong> - View sites</li>
        <li><strong>sites:create</strong> - Create new sites</li>
        <li><strong>sites:delete</strong> - Delete sites</li>
        <li><strong>backups:read</strong> - View backups</li>
        <li><strong>backups:create</strong> - Create backups</li>
        <li><strong>monitoring:read</strong> - View monitoring data</li>
        <li><strong>*</strong> - All permissions (admin only)</li>
    </ul>
    
    <footer style="margin-top: 50px; padding-top: 20px; border-top: 1px solid #ccc; color: #666;">
        <p>LOMP Stack v2.0 - Enterprise API Documentation</p>
    </footer>
</body>
</html>
    """
    
    # Write documentation to file
    with open('api_documentation.html', 'w') as f:
        f.write(html_content)
    
    print("API documentation generated: api_documentation.html")

if __name__ == '__main__':
    generate_api_docs()
EOF
    
    chmod +x "${SCRIPT_DIR}/generate_docs.py"
    log_api "SUCCESS" "API documentation generator created"
}

#########################################################################
# Create Webhook System
#########################################################################
create_webhook_system() {
    log_api "INFO" "Creating webhook system..."
    
    # Initialize webhook configuration
    cat > "$WEBHOOK_CONFIG" << 'EOF'
{
    "webhooks": [
        {
            "id": "site-created",
            "name": "Site Created",
            "url": "https://example.com/webhooks/site-created",
            "events": ["site.created"],
            "active": true,
            "secret": "webhook_secret_key",
            "retry_attempts": 3,
            "created_at": "2025-07-01T10:00:00Z"
        }
    ],
    "events": [
        "site.created",
        "site.deleted", 
        "backup.created",
        "backup.completed",
        "backup.failed",
        "system.alert",
        "security.incident"
    ]
}
EOF
    
    # Create webhook sender script
    cat > "${SCRIPT_DIR}/webhooks/webhook_sender.py" << 'EOF'
#!/usr/bin/env python3

import json
import requests
import hashlib
import hmac
import time
from datetime import datetime

class WebhookSender:
    def __init__(self, config_file='webhook_config.json'):
        with open(config_file, 'r') as f:
            self.config = json.load(f)
    
    def send_webhook(self, event_type, data):
        """Send webhook to all registered endpoints for this event"""
        webhooks = self.config.get('webhooks', [])
        
        for webhook in webhooks:
            if not webhook.get('active', False):
                continue
                
            if event_type in webhook.get('events', []):
                self._send_to_endpoint(webhook, event_type, data)
    
    def _send_to_endpoint(self, webhook, event_type, data):
        """Send webhook to specific endpoint with retry logic"""
        payload = {
            'event': event_type,
            'data': data,
            'timestamp': datetime.utcnow().isoformat(),
            'webhook_id': webhook['id']
        }
        
        headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'LOMP-Stack-Webhook/1.0'
        }
        
        # Add signature if secret is provided
        if webhook.get('secret'):
            signature = self._generate_signature(json.dumps(payload), webhook['secret'])
            headers['X-Webhook-Signature'] = f'sha256={signature}'
        
        max_attempts = webhook.get('retry_attempts', 3)
        
        for attempt in range(max_attempts):
            try:
                response = requests.post(
                    webhook['url'],
                    json=payload,
                    headers=headers,
                    timeout=30
                )
                
                if response.status_code == 200:
                    print(f"Webhook sent successfully to {webhook['url']}")
                    break
                else:
                    print(f"Webhook failed with status {response.status_code}")
                    
            except Exception as e:
                print(f"Webhook attempt {attempt + 1} failed: {str(e)}")
                if attempt < max_attempts - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
    
    def _generate_signature(self, payload, secret):
        """Generate HMAC signature for webhook"""
        return hmac.new(
            secret.encode('utf-8'),
            payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: webhook_sender.py <event_type> <data_json>")
        sys.exit(1)
    
    event_type = sys.argv[1]
    data = json.loads(sys.argv[2])
    
    sender = WebhookSender()
    sender.send_webhook(event_type, data)
EOF
    
    chmod +x "${SCRIPT_DIR}/webhooks/webhook_sender.py"
    log_api "SUCCESS" "Webhook system created"
}

#########################################################################
# Start API Server
#########################################################################
start_api_server() {
    log_api "INFO" "Starting API server..."
    
    # Check if server is already running
    if pgrep -f "api_server.py" > /dev/null; then
        print_warning "API server is already running"
        return 0
    fi
    
    # Start server with PM2
    cd "$SCRIPT_DIR" || return
    pm2 start api_server.py --name "lomp-api" --interpreter python3
    
    if [ $? -eq 0 ]; then
        log_api "SUCCESS" "API server started on ${API_HOST}:${API_PORT}"
        print_info "API Documentation: http://${API_HOST}:${API_PORT}/docs"
        print_info "Health Check: http://${API_HOST}:${API_PORT}/api/v1/health"
    else
        log_api "ERROR" "Failed to start API server"
        return 1
    fi
}

#########################################################################
# Stop API Server
#########################################################################
stop_api_server() {
    log_api "INFO" "Stopping API server..."
    
    pm2 stop lomp-api
    pm2 delete lomp-api
    
    log_api "SUCCESS" "API server stopped"
}

#########################################################################
# Test API Endpoints
#########################################################################
test_api_endpoints() {
    log_api "INFO" "Testing API endpoints..."
    
    local base_url="http://${API_HOST}:${API_PORT}/api/v1"
    
    print_info "Testing health endpoint..."
    curl -s "$base_url/health" | jq '.'
    
    print_info "Testing system status endpoint..."
    curl -s "$base_url/system/status" | jq '.'
    
    log_api "SUCCESS" "API endpoint tests completed"
}

#########################################################################
# Generate API Keys
#########################################################################
generate_api_key() {
    local key_name="$1"
    local permissions="$2"
    local rate_limit="${3:-100}"
    
    if [ -z "$key_name" ]; then
        print_error "Key name is required"
        return 1
    fi
    
    local api_key
    api_key="sk_live_$(echo "$key_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')_$(openssl rand -hex 16)"
    local key_id
    key_id="$(echo "$key_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')-$(date +%s)"
    
    print_success "Generated API Key: $api_key"
    print_info "Key ID: $key_id"
    print_info "Permissions: $permissions"
    print_info "Rate Limit: $rate_limit requests/minute"
    
    log_api "SUCCESS" "API key generated for $key_name"
}

#########################################################################
# Show API Statistics
#########################################################################
show_api_stats() {
    log_api "INFO" "Showing API statistics..."
    
    print_info "=== API Management System Statistics ==="
    print_info "Server Status: $(pm2 list | grep lomp-api | awk '{print $10}')"
    print_info "API Base URL: http://${API_HOST}:${API_PORT}${API_BASE_PATH}"
    
    if [ -f "$API_LOG" ]; then
        local total_requests
        total_requests=$(grep -c "\[INFO\]" "$API_LOG" 2>/dev/null || echo "0")
        local errors
        errors=$(grep -c "\[ERROR\]" "$API_LOG" 2>/dev/null || echo "0")
        print_info "Total Requests: $total_requests"
        print_info "Errors: $errors"
    fi
    
    if [ -f "$API_KEYS_FILE" ]; then
        local total_keys
        total_keys=$(jq '.api_keys | length' "$API_KEYS_FILE" 2>/dev/null || echo "0")
        print_info "Active API Keys: $total_keys"
    fi
    
    if [ -f "$WEBHOOK_CONFIG" ]; then
        local total_webhooks
        total_webhooks=$(jq '.webhooks | length' "$WEBHOOK_CONFIG" 2>/dev/null || echo "0")
        print_info "Configured Webhooks: $total_webhooks"
    fi
}

#########################################################################
# Interactive Menu
#########################################################################
show_api_menu() {
    while true; do
        clear
        color_echo cyan "🔌 LOMP Stack v2.0 - API Management System"
        echo "=============================================="
        color_echo yellow "1.  🚀 Initialize API System"
        color_echo yellow "2.  📦 Install Dependencies" 
        color_echo yellow "3.  🔧 Configure API Settings"
        color_echo yellow "4.  🔑 Generate API Key"
        color_echo yellow "5.  ▶️  Start API Server"
        color_echo yellow "6.  ⏹️  Stop API Server"
        color_echo yellow "7.  🧪 Test API Endpoints"
        color_echo yellow "8.  📚 Generate Documentation"
        color_echo yellow "9.  🕸️  Configure Webhooks"
        color_echo yellow "10. 📊 Show API Statistics"
        color_echo yellow "11. 🔍 View API Logs"
        color_echo yellow "12. 🎯 Show Sample API Calls"
        color_echo red "0.  ↩️  Return to Main Menu"
        echo "=============================================="
        
        read -p "Select an option (0-12): " choice
        
        case $choice in
            1)
                print_info "Initializing API Management System..."
                init_api_config
                generate_jwt_secret
                init_api_keys
                create_api_server
                create_api_documentation
                create_webhook_system
                press_enter
                ;;
            2)
                install_api_dependencies
                press_enter
                ;;
            3)
                print_info "Opening API configuration..."
                if command -v nano &> /dev/null; then
                    nano "$API_CONFIG"
                else
                    cat "$API_CONFIG"
                fi
                press_enter
                ;;
            4)
                read -p "Enter API key name: " key_name
                read -p "Enter permissions (comma-separated or * for all): " permissions
                read -p "Enter rate limit (requests/minute, default 100): " rate_limit
                generate_api_key "$key_name" "$permissions" "${rate_limit:-100}"
                press_enter
                ;;
            5)
                start_api_server
                press_enter
                ;;
            6)
                stop_api_server
                press_enter
                ;;
            7)
                test_api_endpoints
                press_enter
                ;;
            8)
                cd "$SCRIPT_DIR" || return
                python3 generate_docs.py
                print_success "Documentation generated: ${SCRIPT_DIR}/api_documentation.html"
                press_enter
                ;;
            9)
                print_info "Opening webhook configuration..."
                if command -v nano &> /dev/null; then
                    nano "$WEBHOOK_CONFIG"
                else
                    cat "$WEBHOOK_CONFIG"
                fi
                press_enter
                ;;
            10)
                show_api_stats
                press_enter
                ;;
            11)
                if [ -f "$API_LOG" ]; then
                    tail -50 "$API_LOG"
                else
                    print_warning "No API logs found"
                fi
                press_enter
                ;;
            12)
                show_sample_api_calls
                press_enter
                ;;
            0)
                break
                ;;
            *)
                color_echo red "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

#########################################################################
# Show Sample API Calls
#########################################################################
show_sample_api_calls() {
    print_info "=== Sample API Calls ==="
    echo ""
    
    print_info "1. Health Check:"
    echo "curl -X GET http://localhost:8080/api/v1/health"
    echo ""
    
    print_info "2. List Sites (requires API key):"
    echo "curl -X GET http://localhost:8080/api/v1/sites \\"
    echo "  -H 'X-API-Key: your-api-key-here'"
    echo ""
    
    print_info "3. Create Site (requires API key):"
    echo "curl -X POST http://localhost:8080/api/v1/sites \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -H 'X-API-Key: your-api-key-here' \\"
    echo "  -d '{\"domain\":\"example.com\",\"email\":\"admin@example.com\"}'"
    echo ""
    
    print_info "4. Get System Status:"
    echo "curl -X GET http://localhost:8080/api/v1/system/status"
    echo ""
    
    print_info "5. Create Backup (requires API key):"
    echo "curl -X POST http://localhost:8080/api/v1/backups \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -H 'X-API-Key: your-api-key-here' \\"
    echo "  -d '{\"domain\":\"example.com\",\"type\":\"full\"}'"
    echo ""
}

#########################################################################
# Main Function
#########################################################################
main() {
    log_api "INFO" "Starting API Management System..."
    
    # Create required directories
    mkdir -p "$(dirname "$API_LOG")"
    mkdir -p "${SCRIPT_DIR}/auth"
    mkdir -p "${SCRIPT_DIR}/webhooks"
    
    case "${1:-menu}" in
        "init")
            init_api_config
            generate_jwt_secret
            init_api_keys
            create_api_server
            create_api_documentation
            create_webhook_system
            ;;
        "start")
            start_api_server
            ;;
        "stop")
            stop_api_server
            ;;
        "test")
            test_api_endpoints
            ;;
        "stats")
            show_api_stats
            ;;
        "menu"|*)
            show_api_menu
            ;;
    esac
}

# Helper function for "Press Enter to continue"
press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
