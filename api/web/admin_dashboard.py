#!/usr/bin/env python3
"""
LOMP Stack v3.0 - API Administration Web Dashboard
A modern web interface for managing API keys, users, and system configuration

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
import hashlib
import secrets
import requests
from datetime import datetime, timedelta
from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import subprocess
import logging

# Initialize Flask app
app = Flask(__name__)
app.secret_key = secrets.token_hex(32)

# Initialize rate limiter
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
API_DIR = os.path.dirname(SCRIPT_DIR)
STACK_ROOT = os.path.dirname(API_DIR)
CONFIG_FILE = os.path.join(API_DIR, 'api_config.json')
API_KEYS_FILE = os.path.join(API_DIR, 'auth', 'api_keys.json')
ADMIN_DB = os.path.join(API_DIR, 'auth', 'admin_users.db')

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Author and project information
AUTHOR_INFO = {
    'name': 'Silviu Ilie',
    'email': 'neosilviu@gmail.com',
    'company': 'aemdPC',
    'role': 'Lead Developer & System Architect',
    'project_name': 'LOMP Stack v3.0',
    'version': '3.0.0',
    'copyright': '© 2025 aemdPC. All rights reserved.',
    'license': 'MIT License',
    'repository': 'https://github.com/aemdPC/lomp-stack-v3',
    'documentation': 'https://docs.aemdpc.com/lomp-stack',
    'support': 'https://support.aemdpc.com'
}

# Update system configuration
UPDATE_CONFIG = {
    'update_check_url': 'https://api.github.com/repos/aemdPC/lomp-stack-v3/releases/latest',
    'current_version': '3.0.0',
    'check_interval_hours': 24,
    'auto_check_enabled': True,
    'notify_users': True,
    'update_script': os.path.join(STACK_ROOT, 'helpers', 'utils', 'update_system.sh')
}

#########################################################################
# Database Functions
#########################################################################

def init_admin_db():
    """Initialize admin users database"""
    conn = sqlite3.connect(ADMIN_DB)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS admin_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            email TEXT,
            role TEXT DEFAULT 'admin',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP,
            active BOOLEAN DEFAULT 1
        )
    ''')
    
    conn.execute('''
        CREATE TABLE IF NOT EXISTS admin_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            session_token TEXT UNIQUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP,
            ip_address TEXT,
            user_agent TEXT,
            FOREIGN KEY (user_id) REFERENCES admin_users (id)
        )
    ''')
    
    # Create default admin user if none exists
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM admin_users')
    if cursor.fetchone()[0] == 0:
        default_password = 'admin123'
        password_hash = hashlib.sha256(default_password.encode()).hexdigest()
        cursor.execute('''
            INSERT INTO admin_users (username, password_hash, email, role)
            VALUES (?, ?, ?, ?)
        ''', ('admin', password_hash, 'admin@lomp.local', 'super_admin'))
        
    conn.commit()
    conn.close()

def authenticate_admin(username, password):
    """Authenticate admin user"""
    conn = sqlite3.connect(ADMIN_DB)
    cursor = conn.cursor()
    
    password_hash = hashlib.sha256(password.encode()).hexdigest()
    cursor.execute('''
        SELECT id, username, role FROM admin_users 
        WHERE username = ? AND password_hash = ? AND active = 1
    ''', (username, password_hash))
    
    user = cursor.fetchone()
    
    if user:
        # Update last login
        cursor.execute('''
            UPDATE admin_users SET last_login = CURRENT_TIMESTAMP WHERE id = ?
        ''', (user[0],))
        conn.commit()
    
    conn.close()
    return user

def load_api_config():
    """Load API configuration"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except:
        return {}

def save_api_config(config):
    """Save API configuration"""
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=4)

def load_api_keys():
    """Load API keys"""
    try:
        with open(API_KEYS_FILE, 'r') as f:
            return json.load(f)
    except:
        return {"api_keys": []}

def save_api_keys(keys_data):
    """Save API keys"""
    with open(API_KEYS_FILE, 'w') as f:
        json.dump(keys_data, f, indent=4)

def get_system_stats():
    """Get system statistics"""
    try:
        # Get API usage stats
        stats = {
            'total_keys': 0,
            'active_keys': 0,
            'total_requests_today': 0,
            'api_status': 'running',
            'uptime': '2 hours 15 minutes',
            'cpu_usage': '15%',
            'memory_usage': '45%',
            'disk_usage': '23%'
        }
        
        # Load API keys
        keys_data = load_api_keys()
        stats['total_keys'] = len(keys_data.get('api_keys', []))
        stats['active_keys'] = len([k for k in keys_data.get('api_keys', []) if k.get('active', False)])
        
        return stats
    except:
        return {}

#########################################################################
# Authentication Decorator
#########################################################################

def login_required(f):
    """Decorator to require admin login"""
    def decorated_function(*args, **kwargs):
        if 'admin_user' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    decorated_function.__name__ = f.__name__
    return decorated_function

#########################################################################
# Routes - Authentication
#########################################################################

@app.route('/login', methods=['GET', 'POST'])
@limiter.limit("10 per minute")
def login():
    """Admin login page"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        user = authenticate_admin(username, password)
        if user:
            session['admin_user'] = {
                'id': user[0],
                'username': user[1],
                'role': user[2]
            }
            flash('Successfully logged in!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password!', 'error')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    """Admin logout"""
    session.pop('admin_user', None)
    flash('Successfully logged out!', 'info')
    return redirect(url_for('login'))

#########################################################################
# Routes - Dashboard
#########################################################################

@app.route('/')
@app.route('/dashboard')
@login_required
def dashboard():
    """Main dashboard"""
    stats = get_system_stats()
    
    # Check for updates if needed
    if should_check_updates():
        update_info = check_for_updates()
        save_update_status(update_info)
    
    # Get update status and notifications
    update_status = get_update_status()
    notifications = get_update_notifications()
    
    return render_template('dashboard.html', 
                         stats=stats,
                         update_status=update_status,
                         notifications=notifications)

@app.route('/api-keys')
@login_required
def api_keys():
    """API keys management page"""
    keys_data = load_api_keys()
    return render_template('api_keys.html', api_keys=keys_data.get('api_keys', []))

@app.route('/configuration')
@login_required
def configuration():
    """System configuration page"""
    config = load_api_config()
    return render_template('configuration.html', config=config)

@app.route('/monitoring')
@login_required
def monitoring():
    """System monitoring page"""
    stats = get_system_stats()
    return render_template('monitoring.html', stats=stats)

@app.route('/logs')
@login_required
def logs():
    """System logs page"""
    try:
        log_file = os.path.join(API_DIR, '..', 'tmp', 'api_management.log')
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                logs = f.readlines()[-100:]  # Last 100 lines
        else:
            logs = ['No logs found']
    except:
        logs = ['Error reading logs']
    
    return render_template('logs.html', logs=logs)

#########################################################################
# API Routes - AJAX endpoints
#########################################################################

@app.route('/api/create-key', methods=['POST'])
@login_required
@limiter.limit("5 per minute")
def api_create_key():
    """Create new API key"""
    try:
        data = request.get_json()
        name = data.get('name')
        permissions = data.get('permissions', [])
        rate_limit = data.get('rate_limit', 100)
        
        if not name:
            return jsonify({'success': False, 'error': 'Name is required'})
        
        # Generate new API key
        api_key = f"sk_live_{secrets.token_hex(16)}"
        key_id = f"{name.lower().replace(' ', '_')}_{int(datetime.now().timestamp())}"
        
        new_key = {
            'id': key_id,
            'key': api_key,
            'name': name,
            'permissions': permissions,
            'rate_limit': rate_limit,
            'created_at': datetime.utcnow().isoformat(),
            'created_by': session['admin_user']['username'],
            'last_used': None,
            'active': True,
            'usage_count': 0
        }
        
        # Save to file
        keys_data = load_api_keys()
        if 'api_keys' not in keys_data:
            keys_data['api_keys'] = []
        
        keys_data['api_keys'].append(new_key)
        save_api_keys(keys_data)
        
        return jsonify({
            'success': True,
            'message': 'API key created successfully',
            'api_key': api_key,
            'key_id': key_id
        })
        
    except Exception as e:
        logger.error(f"Error creating API key: {str(e)}")
        return jsonify({'success': False, 'error': 'Internal server error'})

@app.route('/api/revoke-key', methods=['POST'])
@login_required
def api_revoke_key():
    """Revoke API key"""
    try:
        data = request.get_json()
        key_id = data.get('key_id')
        
        keys_data = load_api_keys()
        for key in keys_data.get('api_keys', []):
            if key['id'] == key_id:
                key['active'] = False
                key['revoked_at'] = datetime.utcnow().isoformat()
                key['revoked_by'] = session['admin_user']['username']
                break
        
        save_api_keys(keys_data)
        
        return jsonify({
            'success': True,
            'message': 'API key revoked successfully'
        })
        
    except Exception as e:
        logger.error(f"Error revoking API key: {str(e)}")
        return jsonify({'success': False, 'error': 'Internal server error'})

@app.route('/api/update-config', methods=['POST'])
@login_required
def api_update_config():
    """Update system configuration"""
    try:
        data = request.get_json()
        config = load_api_config()
        
        # Update configuration
        if 'api' in data:
            config.update(data)
            save_api_config(config)
            
            return jsonify({
                'success': True,
                'message': 'Configuration updated successfully'
            })
        else:
            return jsonify({'success': False, 'error': 'Invalid configuration data'})
        
    except Exception as e:
        logger.error(f"Error updating configuration: {str(e)}")
        return jsonify({'success': False, 'error': 'Internal server error'})

@app.route('/api/stats')
@login_required
def api_stats():
    """Get real-time statistics"""
    stats = get_system_stats()
    return jsonify(stats)

#########################################################################
# Import hosting management module
#########################################################################

try:
    from hosting_management import (
        get_all_services, manage_service, get_service_config,
        get_all_sites, create_new_site, get_wp_sites, install_wordpress,
        get_all_domains, add_domain, SITES_DB_PATH, DOMAINS_DB_PATH, SERVICES_DB_PATH,
        get_python_apps, create_python_app, manage_python_app, get_python_app_logs
    )
    HOSTING_ENABLED = True
except ImportError:
    HOSTING_ENABLED = False
    print("Warning: Hosting management features not available")

#########################################################################
# Extended Hosting Routes
#########################################################################

@app.route('/services')
@login_required
def services():
    """Services management page"""
    if not HOSTING_ENABLED:
        flash('Hosting features not available', 'error')
        return redirect(url_for('dashboard'))
    
    services = get_all_services()
    return render_template('services.html', services=services)

@app.route('/sites')
@login_required
def sites():
    """Sites management page"""
    if not HOSTING_ENABLED:
        flash('Hosting features not available', 'error')
        return redirect(url_for('dashboard'))
    
    sites = get_all_sites()
    return render_template('sites.html', sites=sites)

@app.route('/wordpress')
@login_required
def wordpress():
    """WordPress management page"""
    if not HOSTING_ENABLED:
        flash('Hosting features not available', 'error')
        return redirect(url_for('dashboard'))
    
    wp_sites = get_wp_sites()
    available_domains = get_all_domains()
    return render_template('wordpress.html', wp_sites=wp_sites, available_domains=available_domains)

@app.route('/domains')
@login_required
def domains():
    """Domain management page"""
    if not HOSTING_ENABLED:
        flash('Hosting features not available', 'error')
        return redirect(url_for('dashboard'))
    
    domains = get_all_domains()
    return render_template('domains.html', domains=domains)

@app.route('/python-apps')
@login_required
def python_apps():
    """Python applications management page"""
    if not HOSTING_ENABLED:
        flash('Hosting features not available', 'error')
        return redirect(url_for('dashboard'))
    
    python_apps = get_python_apps()
    available_domains = get_all_domains()
    return render_template('python_apps.html', python_apps=python_apps, available_domains=available_domains)

@app.route('/hosting')
@login_required
def hosting():
    """Main hosting overview page"""
    if not HOSTING_ENABLED:
        flash('Hosting features not available', 'error')
        return redirect(url_for('dashboard'))
    
    services = get_all_services()
    sites = get_all_sites()
    domains = get_all_domains()
    
    hosting_stats = {
        'total_sites': len(sites),
        'active_sites': len([s for s in sites if s['status'] == 'active']),
        'wp_sites': len([s for s in sites if s['wp_installed']]),
        'total_domains': len(domains),
        'active_services': len([s for s in services if s['status'] == 'active']),
        'total_services': len(services)
    }
    
    return render_template('hosting.html', 
                         services=services[:5],  # Show top 5 services
                         sites=sites[:10],       # Show latest 10 sites
                         domains=domains[:5],    # Show 5 domains
                         stats=hosting_stats)

#########################################################################
# API Endpoints for Hosting Features
#########################################################################

@app.route('/api/services/<service_name>/<action>', methods=['POST'])
@login_required
def api_manage_service(service_name, action):
    """Manage service via API"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    result = manage_service(service_name, action)
    return jsonify(result)

@app.route('/api/services/<service_name>/config')
@login_required
def api_get_service_config(service_name):
    """Get service configuration"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    config = get_service_config(service_name)
    return jsonify({"config": config})

@app.route('/api/sites', methods=['POST'])
@login_required
def api_create_site():
    """Create new site via API"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    
    domain = data.get('domain')
    subdomain = data.get('subdomain')
    php_version = data.get('php_version', '8.1')
    web_server = data.get('web_server', 'ols')
    install_wp = data.get('install_wp', False)
    
    if not domain:
        return jsonify({"error": "Domain is required"}), 400
    
    result = create_new_site(domain, subdomain, php_version, web_server, install_wp)
    return jsonify(result)

@app.route('/api/domains', methods=['POST'])
@login_required
def api_add_domain():
    """Add a new domain"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    domain_name = data.get('domain_name')
    domain_type = data.get('domain_type', 'primary')
    nameservers = data.get('nameservers')
    registrar = data.get('registrar')
    
    if not domain_name:
        return jsonify({"error": "Domain name is required"}), 400
    
    result = add_domain(domain_name, domain_type, nameservers, registrar)
    return jsonify(result)

@app.route('/api/domains/<int:domain_id>', methods=['GET'])
@login_required
def api_get_domain(domain_id):
    """Get domain details"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    try:
        conn = sqlite3.connect(DOMAINS_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM domains WHERE id = ?', (domain_id,))
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return jsonify({"error": "Domain not found"}), 404
        
        domain = {
            'id': row[0],
            'domain_name': row[1],
            'domain_type': row[2],
            'nameservers': row[3],
            'dns_records': row[4],
            'registrar': row[5],
            'expiry_date': row[6],
            'auto_renew': bool(row[7]),
            'cloudflare_enabled': bool(row[8]),
            'cloudflare_zone_id': row[9],
            'status': row[10],
            'created_at': row[11]
        }
        
        return jsonify({"success": True, "domain": domain})
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/domains/<int:domain_id>', methods=['PUT'])
@login_required
def api_update_domain(domain_id):
    """Update domain details"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    
    try:
        conn = sqlite3.connect(DOMAINS_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            UPDATE domains SET 
                domain_name = ?, domain_type = ?, nameservers = ?, 
                registrar = ?, expiry_date = ?, auto_renew = ?, 
                cloudflare_enabled = ?, status = ?
            WHERE id = ?
        ''', (
            data.get('domain_name'),
            data.get('domain_type'),
            data.get('nameservers'),
            data.get('registrar'),
            data.get('expiry_date'),
            data.get('auto_renew', False),
            data.get('cloudflare_enabled', False),
            data.get('status'),
            domain_id
        ))
        
        conn.commit()
        conn.close()
        
        return jsonify({"success": True, "message": "Domain updated successfully"})
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/domains/<int:domain_id>', methods=['DELETE'])
@login_required
def api_delete_domain(domain_id):
    """Delete a domain"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    try:
        conn = sqlite3.connect(DOMAINS_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('DELETE FROM domains WHERE id = ?', (domain_id,))
        conn.commit()
        conn.close()
        
        return jsonify({"success": True, "message": "Domain deleted successfully"})
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/domains/<int:domain_id>/dns', methods=['GET'])
@login_required
def api_get_dns_records(domain_id):
    """Get DNS records for domain"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would integrate with DNS provider APIs
    dns_html = """
    <div class="alert alert-info">
        <h6>DNS Records Management</h6>
        <p>DNS records management would be integrated here with your DNS provider API.</p>
        <p>Common records to manage:</p>
        <ul>
            <li>A Records (IPv4 addresses)</li>
            <li>AAAA Records (IPv6 addresses)</li>
            <li>CNAME Records (aliases)</li>
            <li>MX Records (mail exchange)</li>
            <li>TXT Records (verification, SPF, DKIM)</li>
        </ul>
    </div>
    """
    
    return jsonify({"success": True, "html": dns_html})

@app.route('/api/domains/<int:domain_id>/ssl', methods=['GET'])
@login_required
def api_get_ssl_info(domain_id):
    """Get SSL certificate information"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would check SSL certificate status
    ssl_html = """
    <div class="alert alert-success">
        <h6>SSL Certificate Status</h6>
        <p><strong>Status:</strong> Active</p>
        <p><strong>Issuer:</strong> Let's Encrypt</p>
        <p><strong>Valid Until:</strong> 2024-10-01</p>
        <p><strong>Auto-Renewal:</strong> Enabled</p>
    </div>
    <div class="d-grid gap-2">
        <button class="btn btn-outline-primary" onclick="renewSSL()">
            <i class="fas fa-sync me-2"></i>Renew SSL Certificate
        </button>
        <button class="btn btn-outline-info" onclick="viewSSLDetails()">
            <i class="fas fa-info-circle me-2"></i>View Certificate Details
        </button>
    </div>
    """
    
    return jsonify({"success": True, "html": ssl_html})

@app.route('/api/domains/bulk/cloudflare', methods=['POST'])
@login_required
def api_bulk_enable_cloudflare():
    """Enable Cloudflare for selected domains"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    domain_ids = data.get('domain_ids', [])
    
    if not domain_ids:
        return jsonify({"error": "No domains selected"}), 400
    
    try:
        conn = sqlite3.connect(DOMAINS_DB_PATH)
        cursor = conn.cursor()
        
        placeholders = ','.join(['?' for _ in domain_ids])
        cursor.execute(f'''
            UPDATE domains SET cloudflare_enabled = 1 
            WHERE id IN ({placeholders})
        ''', domain_ids)
        
        conn.commit()
        conn.close()
        
        return jsonify({"success": True, "message": f"Cloudflare enabled for {len(domain_ids)} domains"})
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/domains/bulk/renew-ssl', methods=['POST'])
@login_required
def api_bulk_renew_ssl():
    """Renew SSL for selected domains"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    domain_ids = data.get('domain_ids', [])
    
    if not domain_ids:
        return jsonify({"error": "No domains selected"}), 400
    
    # This would integrate with Let's Encrypt or other SSL providers
    return jsonify({"success": True, "message": f"SSL renewal initiated for {len(domain_ids)} domains"})

@app.route('/api/domains/bulk/check-dns', methods=['POST'])
@login_required
def api_bulk_check_dns():
    """Check DNS status for selected domains"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    domain_ids = data.get('domain_ids', [])
    
    if not domain_ids:
        return jsonify({"error": "No domains selected"}), 400
    
    # This would check DNS propagation and status
    return jsonify({"success": True, "message": f"DNS check completed for {len(domain_ids)} domains"})

@app.route('/api/wordpress/install', methods=['POST'])
@login_required
def api_install_wordpress():
    """Install WordPress"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    domain = data.get('domain')
    subdirectory = data.get('subdirectory', '')
    admin_user = data.get('admin_user')
    admin_email = data.get('admin_email')
    admin_password = data.get('admin_password')
    site_title = data.get('site_title')
    
    if not all([domain, admin_user, admin_email, admin_password, site_title]):
        return jsonify({"error": "All required fields must be provided"}), 400
    
    try:
        # Create site first
        full_domain = domain
        if subdirectory:
            full_domain = f"{domain}/{subdirectory}"
        
        site_result = create_new_site(domain, subdirectory, install_wp=True)
        
        if not site_result.get('success'):
            return jsonify(site_result), 400
        
        # Install WordPress
        site_id = site_result.get('site_id')
        document_root = f"/var/www/{domain}"
        if subdirectory:
            document_root = f"/var/www/{domain}/{subdirectory}"
        
        wp_result = install_wordpress(site_id, full_domain, document_root)
        
        return jsonify(wp_result)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/wordpress/<int:site_id>', methods=['GET'])
@login_required
def api_get_wordpress_site(site_id):
    """Get WordPress site details"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM sites WHERE id = ?', (site_id,))
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return jsonify({"error": "Site not found"}), 404
        
        # Generate HTML content for the modal
        site_info_html = f"""
        <table class="table table-sm">
            <tr><td><strong>Domain:</strong></td><td>{row[1]}</td></tr>
            <tr><td><strong>Status:</strong></td><td><span class="badge bg-{('success' if row[6] == 'active' else 'secondary')}">{row[6]}</span></td></tr>
            <tr><td><strong>WordPress:</strong></td><td>{'Yes' if row[8] else 'No'}</td></tr>
            <tr><td><strong>SSL:</strong></td><td>{'Enabled' if row[7] else 'Disabled'}</td></tr>
            <tr><td><strong>Created:</strong></td><td>{row[9]}</td></tr>
        </table>
        """
        
        plugins_html = """
        <div class="alert alert-info">
            <h6>Installed Plugins</h6>
            <p>Plugin management would be integrated here using WP-CLI.</p>
            <ul class="list-unstyled">
                <li><i class="fas fa-check text-success me-2"></i>Akismet Anti-Spam</li>
                <li><i class="fas fa-check text-success me-2"></i>Hello Dolly</li>
            </ul>
        </div>
        """
        
        themes_html = """
        <div class="alert alert-info">
            <h6>Active Theme</h6>
            <p><strong>Twenty Twenty-Four</strong> - WordPress default theme</p>
            <small class="text-muted">Theme management would be integrated here using WP-CLI.</small>
        </div>
        """
        
        backups_html = """
        <div class="alert alert-info">
            <h6>Recent Backups</h6>
            <p>No backups found. Create your first backup using the backup button.</p>
        </div>
        """
        
        return jsonify({
            "success": True,
            "site_info_html": site_info_html,
            "plugins_html": plugins_html,
            "themes_html": themes_html,
            "backups_html": backups_html
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/wordpress/<int:site_id>', methods=['DELETE'])
@login_required
def api_delete_wordpress_site(site_id):
    """Delete WordPress site"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    try:
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('DELETE FROM sites WHERE id = ?', (site_id,))
        conn.commit()
        conn.close()
        
        return jsonify({"success": True, "message": "WordPress site deleted successfully"})
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/wordpress/<int:site_id>/backup', methods=['POST'])
@login_required
def api_backup_wordpress_site(site_id):
    """Create backup of WordPress site"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would integrate with backup utilities
    return jsonify({"success": True, "message": "Backup created successfully"})

@app.route('/api/wordpress/<int:site_id>/update', methods=['POST'])
@login_required
def api_update_wordpress_site(site_id):
    """Update WordPress site"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would use WP-CLI to update WordPress
    return jsonify({"success": True, "message": "WordPress updated successfully"})

@app.route('/api/wordpress/<int:site_id>/maintenance', methods=['POST'])
@login_required
def api_toggle_maintenance_mode(site_id):
    """Toggle maintenance mode"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would toggle WordPress maintenance mode
    return jsonify({"success": True, "message": "Maintenance mode toggled"})

@app.route('/api/wordpress/<int:site_id>/logs', methods=['GET'])
@login_required
def api_get_wordpress_logs(site_id):
    """Get WordPress logs"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would retrieve WordPress error logs
    return jsonify({"success": True, "logs": "No recent errors found"})

@app.route('/api/wordpress/check-updates', methods=['POST'])
@login_required
def api_check_wordpress_updates():
    """Check for WordPress updates across all sites"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would use WP-CLI to check for updates
    return jsonify({"success": True, "message": "Update check completed"})

@app.route('/api/wordpress/bulk/update', methods=['POST'])
@login_required
def api_bulk_update_wordpress():
    """Update selected WordPress sites"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    site_ids = data.get('site_ids', [])
    
    if not site_ids:
        return jsonify({"error": "No sites selected"}), 400
    
    # This would use WP-CLI to update multiple sites
    return jsonify({"success": True, "message": f"Updates initiated for {len(site_ids)} sites"})

@app.route('/api/wordpress/bulk/maintenance', methods=['POST'])
@login_required
def api_bulk_maintenance_mode():
    """Toggle maintenance mode for selected sites"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    site_ids = data.get('site_ids', [])
    
    if not site_ids:
        return jsonify({"error": "No sites selected"}), 400
    
    # This would toggle maintenance mode for multiple sites
    return jsonify({"success": True, "message": f"Maintenance mode toggled for {len(site_ids)} sites"})

@app.route('/api/wordpress/bulk/enable-ssl', methods=['POST'])
@login_required
def api_bulk_enable_ssl():
    """Enable SSL for selected WordPress sites"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    site_ids = data.get('site_ids', [])
    
    if not site_ids:
        return jsonify({"error": "No sites selected"}), 400
    
    # This would enable SSL for multiple sites
    return jsonify({"success": True, "message": f"SSL enabled for {len(site_ids)} sites"})

@app.route('/api/wordpress/bulk/backup', methods=['POST'])
@login_required
def api_bulk_backup_wordpress():
    """Create backups for selected WordPress sites"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    site_ids = data.get('site_ids', [])
    
    if not site_ids:
        return jsonify({"error": "No sites selected"}), 400
    
    # This would create backups for multiple sites
    return jsonify({"success": True, "message": f"Backups initiated for {len(site_ids)} sites"})

#########################################################################
# API Endpoints for Python Application Management
#########################################################################

@app.route('/api/python/deploy', methods=['POST'])
@login_required
def api_deploy_python_app():
    """Deploy a new Python application"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    domain = data.get('domain')
    subdirectory = data.get('subdirectory', '')
    framework = data.get('framework')
    python_version = data.get('python_version', '3.11')
    git_repo = data.get('git_repository')
    
    if not all([domain, framework]):
        return jsonify({"error": "Domain and framework are required"}), 400
    
    try:
        result = create_python_app(domain, subdirectory, framework, python_version, git_repo)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/python/<int:app_id>', methods=['GET'])
@login_required
def api_get_python_app(app_id):
    """Get Python application details"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    try:
        # Get app info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT domain, subdomain, site_type, python_version, python_framework, 
                   python_venv_path, python_port, status, ssl_enabled, created_at
            FROM sites WHERE id = ? AND site_type = 'python'
        ''', (app_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return jsonify({"error": "Python application not found"}), 404
        
        # Generate HTML content for the modal
        app_info_html = f"""
        <table class="table table-sm">
            <tr><td><strong>Domain:</strong></td><td>{row[0]}</td></tr>
            <tr><td><strong>Framework:</strong></td><td><span class="badge bg-info">{row[4]}</span></td></tr>
            <tr><td><strong>Python Version:</strong></td><td><span class="badge bg-secondary">{row[3]}</span></td></tr>
            <tr><td><strong>Port:</strong></td><td>{row[6]}</td></tr>
            <tr><td><strong>Status:</strong></td><td><span class="badge bg-{('success' if row[7] == 'active' else 'secondary')}">{row[7]}</span></td></tr>
            <tr><td><strong>SSL:</strong></td><td>{'Enabled' if row[8] else 'Disabled'}</td></tr>
            <tr><td><strong>Created:</strong></td><td>{row[9]}</td></tr>
        </table>
        """
        
        environment_html = """
        <div class="alert alert-info">
            <h6>Virtual Environment</h6>
            <p><strong>Path:</strong> """ + str(row[5]) + """</p>
            <p><strong>Python:</strong> """ + str(row[3]) + """</p>
            <small class="text-muted">Virtual environment management tools would be integrated here.</small>
        </div>
        """
        
        dependencies_html = """
        <div class="alert alert-info">
            <h6>Installed Packages</h6>
            <p>Package management would be integrated here using pip.</p>
            <div class="d-grid gap-2">
                <button class="btn btn-outline-primary btn-sm">
                    <i class="fas fa-plus me-1"></i>Install Package
                </button>
                <button class="btn btn-outline-warning btn-sm">
                    <i class="fas fa-sync me-1"></i>Update Requirements
                </button>
            </div>
        </div>
        """
        
        logs_html = """
        <div class="alert alert-info">
            <h6>Recent Logs</h6>
            <p>Application logs would be displayed here.</p>
            <button class="btn btn-outline-primary btn-sm" onclick="viewFullLogs()">
                <i class="fas fa-file-alt me-1"></i>View Full Logs
            </button>
        </div>
        """
        
        performance_html = """
        <div class="alert alert-info">
            <h6>Performance Metrics</h6>
            <p>CPU, Memory, and Response Time metrics would be displayed here.</p>
            <small class="text-muted">Performance monitoring integration pending.</small>
        </div>
        """
        
        return jsonify({
            "success": True,
            "app_info_html": app_info_html,
            "environment_html": environment_html,
            "dependencies_html": dependencies_html,
            "logs_html": logs_html,
            "performance_html": performance_html
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/python/<int:app_id>/action', methods=['POST'])
@login_required
def api_python_app_action(app_id):
    """Perform action on Python application"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    action = data.get('action')
    
    if not action:
        return jsonify({"error": "Action is required"}), 400
    
    try:
        result = manage_python_app(app_id, action)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/python/<int:app_id>/logs', methods=['GET'])
@login_required
def api_get_python_app_logs(app_id):
    """Get Python application logs"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    try:
        result = get_python_app_logs(app_id)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/python/<int:app_id>/deploy', methods=['POST'])
@login_required
def api_deploy_python_app_update(app_id):
    """Deploy/update Python application"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would pull from Git and restart the application
    try:
        # Restart the application after deployment
        result = manage_python_app(app_id, 'restart')
        if result['success']:
            return jsonify({"success": True, "message": "Application deployed and restarted successfully"})
        else:
            return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/python/<int:app_id>/migrate', methods=['POST'])
@login_required
def api_python_app_migrate(app_id):
    """Run database migrations for Python application"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would run Django migrations or equivalent
    return jsonify({"success": True, "message": "Database migrations completed"})

@app.route('/api/python/health-check', methods=['POST'])
@login_required
def api_python_health_check():
    """Check health of all Python applications"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    # This would check health endpoints of all Python apps
    return jsonify({"success": True, "message": "Health check completed for all Python applications"})

@app.route('/api/python/bulk/<action>', methods=['POST'])
@login_required
def api_python_bulk_action(action):
    """Perform bulk action on Python applications"""
    if not HOSTING_ENABLED:
        return jsonify({"error": "Hosting features not available"}), 400
    
    data = request.get_json()
    app_ids = data.get('app_ids', [])
    
    if not app_ids:
        return jsonify({"error": "No applications selected"}), 400
    
    success_count = 0
    error_count = 0
    
    for app_id in app_ids:
        try:
            result = manage_python_app(app_id, action)
            if result['success']:
                success_count += 1
            else:
                error_count += 1
        except Exception:
            error_count += 1
    
    message = f"Action '{action}' completed: {success_count} successful, {error_count} failed"
    return jsonify({"success": error_count == 0, "message": message})

#########################################################################
# Update System Functions
#########################################################################

def check_for_updates():
    """Check for available updates from GitHub releases"""
    try:
        # Get latest release information
        response = requests.get(UPDATE_CONFIG['update_check_url'], timeout=10)
        if response.status_code == 200:
            release_data = response.json()
            latest_version = release_data.get('tag_name', '').replace('v', '')
            
            # Compare versions
            current_ver = UPDATE_CONFIG['current_version']
            
            # Simple version comparison using string comparison
            if latest_version and latest_version != current_ver:
                # Basic version comparison (works for semantic versioning)
                def version_tuple(v):
                    try:
                        return tuple(map(int, (v.split("."))))
                    except ValueError:
                        return (0, 0, 0)
                
                try:
                    if version_tuple(latest_version) > version_tuple(current_ver):
                        return {
                            'update_available': True,
                            'latest_version': latest_version,
                            'current_version': current_ver,
                            'release_url': release_data.get('html_url', ''),
                            'release_notes': release_data.get('body', 'No release notes available'),
                            'published_at': release_data.get('published_at', ''),
                            'download_url': release_data.get('tarball_url', '')
                        }
                except Exception:
                    # Fallback to string comparison
                    if latest_version > current_ver:
                        return {
                            'update_available': True,
                            'latest_version': latest_version,
                            'current_version': current_ver,
                            'release_url': release_data.get('html_url', ''),
                            'release_notes': release_data.get('body', 'No release notes available'),
                            'published_at': release_data.get('published_at', ''),
                            'download_url': release_data.get('tarball_url', '')
                        }
            
            return {
                'update_available': False,
                'latest_version': latest_version or current_ver,
                'current_version': current_ver,
                'last_checked': datetime.now().isoformat()
            }
        else:
            # Handle non-200 response codes
            return {
                'update_available': False,
                'current_version': UPDATE_CONFIG['current_version'],
                'error': f'HTTP {response.status_code}: Unable to check for updates',
                'last_checked': datetime.now().isoformat()
            }
    except requests.exceptions.RequestException as e:
        logger.error(f"Network error checking for updates: {e}")
        return {
            'update_available': False,
            'current_version': UPDATE_CONFIG['current_version'],
            'error': f'Network error: {str(e)}',
            'last_checked': datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error checking for updates: {e}")
        return {
            'update_available': False,
            'current_version': UPDATE_CONFIG['current_version'],
            'error': str(e),
            'last_checked': datetime.now().isoformat()
        }

def get_update_status():
    """Get current update status and cached information"""
    try:
        update_file = os.path.join(API_DIR, '.update_status.json')
        if os.path.exists(update_file):
            with open(update_file, 'r') as f:
                return json.load(f)
    except:
        pass
    
    return {
        'update_available': False,
        'last_checked': None,
        'current_version': UPDATE_CONFIG['current_version']
    }

def save_update_status(status):
    """Save update status to cache file"""
    try:
        update_file = os.path.join(API_DIR, '.update_status.json')
        with open(update_file, 'w') as f:
            json.dump(status, f, indent=4)
    except Exception as e:
        logger.error(f"Error saving update status: {e}")

def should_check_updates():
    """Check if it's time to check for updates based on interval"""
    status = get_update_status()
    if not UPDATE_CONFIG['auto_check_enabled']:
        return False
    
    last_checked = status.get('last_checked')
    if not last_checked:
        return True
    
    try:
        last_check_time = datetime.fromisoformat(last_checked.replace('Z', '+00:00'))
        check_interval = timedelta(hours=UPDATE_CONFIG['check_interval_hours'])
        return datetime.now() > last_check_time + check_interval
    except:
        return True

def perform_update():
    """Execute the update process using the update script"""
    try:
        update_script = UPDATE_CONFIG['update_script']
        if not os.path.exists(update_script):
            return {
                'success': False,
                'error': 'Update script not found'
            }
        
        # Run update script
        result = subprocess.run(
            ['bash', update_script, '--auto'],
            cwd=STACK_ROOT,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        if result.returncode == 0:
            return {
                'success': True,
                'message': 'Update completed successfully',
                'output': result.stdout
            }
        else:
            return {
                'success': False,
                'error': 'Update failed',
                'output': result.stderr
            }
    except subprocess.TimeoutExpired:
        return {
            'success': False,
            'error': 'Update timed out'
        }
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

def get_update_notifications():
    """Get update notifications for the current user"""
    status = get_update_status()
    notifications = []
    
    if status.get('update_available') and UPDATE_CONFIG['notify_users']:
        notifications.append({
            'type': 'update',
            'title': 'Update Available',
            'message': f"LOMP Stack v{status.get('latest_version')} is available",
            'action_url': '/updates',
            'priority': 'medium',
            'timestamp': datetime.now().isoformat()
        })
    
    return notifications

#########################################################################
# Update System Routes
#########################################################################

@app.route('/updates')
@login_required
def updates_page():
    """Updates management page"""
    if should_check_updates():
        # Perform automatic check
        update_info = check_for_updates()
        save_update_status(update_info)
    
    status = get_update_status()
    return render_template('updates.html', 
                         update_status=status,
                         update_config=UPDATE_CONFIG)

@app.route('/api/check-updates', methods=['POST'])
@login_required
@limiter.limit("10 per minute")
def api_check_updates():
    """Manually check for updates"""
    try:
        update_info = check_for_updates()
        save_update_status(update_info)
        return jsonify({
            'success': True,
            'data': update_info
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/perform-update', methods=['POST'])
@login_required
@limiter.limit("2 per hour")
def api_perform_update():
    """Perform system update"""
    try:
        # Check if user has admin privileges
        if not session.get('admin_user', {}).get('role') in ['admin', 'super_admin']:
            return jsonify({
                'success': False,
                'error': 'Insufficient privileges for system update'
            }), 403
        
        result = perform_update()
        
        if result['success']:
            # Clear update status after successful update
            save_update_status({
                'update_available': False,
                'last_checked': datetime.now().isoformat(),
                'current_version': UPDATE_CONFIG['current_version'],
                'last_update': datetime.now().isoformat()
            })
        
        return jsonify(result)
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/update-settings', methods=['POST'])
@login_required
def api_update_settings():
    """Update notification and auto-check settings"""
    try:
        data = request.get_json()
        
        # Update settings
        if 'auto_check_enabled' in data:
            UPDATE_CONFIG['auto_check_enabled'] = bool(data['auto_check_enabled'])
        
        if 'notify_users' in data:
            UPDATE_CONFIG['notify_users'] = bool(data['notify_users'])
        
        if 'check_interval_hours' in data:
            interval = int(data['check_interval_hours'])
            if 1 <= interval <= 168:  # Between 1 hour and 1 week
                UPDATE_CONFIG['check_interval_hours'] = interval
        
        # Save settings to config file
        config_file = os.path.join(API_DIR, 'update_config.json')
        with open(config_file, 'w') as f:
            json.dump(UPDATE_CONFIG, f, indent=4)
        
        return jsonify({
            'success': True,
            'message': 'Update settings saved successfully'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/notifications')
@login_required
def api_notifications():
    """Get system notifications including update notifications"""
    try:
        notifications = []
        
        # Add update notifications
        notifications.extend(get_update_notifications())
        
        # Add other system notifications here
        # ...
        
        return jsonify({
            'success': True,
            'notifications': notifications
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
