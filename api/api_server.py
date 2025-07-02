#!/usr/bin/env python3
"""
api_server.py - Part of LOMP Stack v3.0
Part of LOMP Stack v3.0

Author: Silviu Ilie <neosilviu@gmail.com>
Company: aemdPC
Version: 3.0.0
Copyright © 2025 aemdPC. All rights reserved.
License: MIT License

Repository: https://github.com/aemdPC/lomp-stack-v3
Documentation: https://docs.aemdpc.com/lomp-stack
Support: https://support.aemdpc.com
"""


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
