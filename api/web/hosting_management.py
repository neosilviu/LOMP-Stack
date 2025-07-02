#!/usr/bin/env python3
"""
LOMP Stack v3.0 - Extended Hosting Control Panel
Comprehensive web interface for managing hosting services, domains, and WordPress installations

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
import subprocess
import sqlite3
import hashlib
import secrets
import re
from datetime import datetime, timedelta
from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
from functools import wraps
import logging

# Import base Flask app
import sys
sys.path.append(os.path.dirname(__file__))

# Import existing dashboard components
try:
    from admin_dashboard import app, SCRIPT_DIR, API_DIR, get_system_stats
except ImportError:
    # If running standalone, create app instance
    from flask import Flask
    app = Flask(__name__)
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    API_DIR = os.path.dirname(SCRIPT_DIR)

# Import helpers integration layer
# Authentication decorator
def require_auth(f):
    """Decorator for routes requiring authentication"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'admin_token' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Extended configuration
STACK_ROOT = os.path.dirname(os.path.dirname(API_DIR))
SITES_DB_PATH = os.path.join(SCRIPT_DIR, 'sites.db')
DOMAINS_DB_PATH = os.path.join(SCRIPT_DIR, 'domains.db')
SERVICES_DB_PATH = os.path.join(SCRIPT_DIR, 'services.db')

# Import helpers integration layer after STACK_ROOT is defined
try:
    from helpers_integration import get_helpers_integration
    helpers = get_helpers_integration(STACK_ROOT)
except ImportError:
    helpers = None
    logging.warning("Helpers integration not available")

# Helpers paths
WEB_HELPERS_DIR = os.path.join(STACK_ROOT, 'helpers', 'web')
WP_HELPERS_DIR = os.path.join(STACK_ROOT, 'helpers', 'wp')
SECURITY_HELPERS_DIR = os.path.join(STACK_ROOT, 'helpers', 'security')

#########################################################################
# Database Setup for Hosting Features
#########################################################################

def init_hosting_databases():
    """Initialize hosting-related databases"""
    
    # Sites database
    conn = sqlite3.connect(SITES_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            domain TEXT UNIQUE NOT NULL,
            subdomain TEXT,
            document_root TEXT NOT NULL,
            site_type TEXT DEFAULT 'php',
            php_version TEXT DEFAULT '8.1',
            python_version TEXT DEFAULT '3.11',
            python_framework TEXT,
            python_venv_path TEXT,
            python_wsgi_file TEXT,
            python_requirements_file TEXT,
            python_port INTEGER,
            web_server TEXT DEFAULT 'ols',
            ssl_enabled BOOLEAN DEFAULT 0,
            ssl_cert_path TEXT,
            wp_installed BOOLEAN DEFAULT 0,
            wp_version TEXT,
            wp_admin_user TEXT,
            wp_admin_email TEXT,
            disk_usage INTEGER DEFAULT 0,
            bandwidth_used INTEGER DEFAULT 0,
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS site_backups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            site_id INTEGER,
            backup_path TEXT NOT NULL,
            backup_size INTEGER,
            backup_type TEXT DEFAULT 'full',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (site_id) REFERENCES sites (id)
        )
    ''')
    
    conn.commit()
    conn.close()
    
    # Domains database
    conn = sqlite3.connect(DOMAINS_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS domains (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            domain_name TEXT UNIQUE NOT NULL,
            domain_type TEXT DEFAULT 'primary',
            nameservers TEXT,
            dns_records TEXT,
            registrar TEXT,
            expiry_date DATE,
            auto_renew BOOLEAN DEFAULT 1,
            cloudflare_enabled BOOLEAN DEFAULT 0,
            cloudflare_zone_id TEXT,
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()
    
    # Services database
    conn = sqlite3.connect(SERVICES_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_name TEXT UNIQUE NOT NULL,
            service_type TEXT NOT NULL,
            status TEXT DEFAULT 'stopped',
            port INTEGER,
            config_path TEXT,
            log_path TEXT,
            auto_start BOOLEAN DEFAULT 1,
            memory_usage INTEGER DEFAULT 0,
            cpu_usage REAL DEFAULT 0.0,
            uptime INTEGER DEFAULT 0,
            last_restart TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Insert default services
    default_services = [
        ('nginx', 'web_server', 'active', 80, '/etc/nginx/nginx.conf', '/var/log/nginx/error.log'),
        ('openlitespeed', 'web_server', 'active', 8088, '/usr/local/lsws/conf/httpd_config.conf', '/usr/local/lsws/logs/error.log'),
        ('apache2', 'web_server', 'inactive', 80, '/etc/apache2/apache2.conf', '/var/log/apache2/error.log'),
        ('mysql', 'database', 'active', 3306, '/etc/mysql/my.cnf', '/var/log/mysql/error.log'),
        ('mariadb', 'database', 'inactive', 3306, '/etc/mysql/mariadb.conf.d/50-server.cnf', '/var/log/mysql/error.log'),
        ('redis', 'cache', 'active', 6379, '/etc/redis/redis.conf', '/var/log/redis/redis-server.log'),
        ('memcached', 'cache', 'inactive', 11211, '/etc/memcached.conf', '/var/log/memcached.log'),
        ('php-8.1-fpm', 'php', 'active', 0, '/etc/php/8.1/fpm/php-fpm.conf', '/var/log/php8.1-fpm.log'),
        ('php-8.2-fpm', 'php', 'inactive', 0, '/etc/php/8.2/fpm/php-fpm.conf', '/var/log/php8.2-fpm.log'),
        ('certbot', 'ssl', 'active', 0, '/etc/letsencrypt/', '/var/log/letsencrypt/letsencrypt.log'),
    ]
    
    for service in default_services:
        cursor.execute('''
            INSERT OR IGNORE INTO services 
            (service_name, service_type, status, port, config_path, log_path)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', service)
    
    conn.commit()
    conn.close()

#########################################################################
# Service Management Functions
#########################################################################

def get_all_services():
    """Get all services with their status"""
    conn = sqlite3.connect(SERVICES_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT service_name, service_type, status, port, config_path, 
               memory_usage, cpu_usage, uptime, last_restart
        FROM services ORDER BY service_type, service_name
    ''')
    
    services = []
    for row in cursor.fetchall():
        services.append({
            'name': row[0],
            'type': row[1],
            'status': row[2],
            'port': row[3],
            'config_path': row[4],
            'memory_usage': row[5],
            'cpu_usage': row[6],
            'uptime': row[7],
            'last_restart': row[8]
        })
    
    conn.close()
    return services

def manage_service(service_name, action):
    """Manage service (start/stop/restart/reload)"""
    try:
        if action in ['start', 'stop', 'restart', 'reload']:
            # Use systemctl for service management
            result = subprocess.run(
                ['systemctl', action, service_name],
                capture_output=True, text=True, timeout=30
            )
            
            if result.returncode == 0:
                # Update status in database
                conn = sqlite3.connect(SERVICES_DB_PATH)
                cursor = conn.cursor()
                
                new_status = 'active' if action == 'start' else 'inactive' if action == 'stop' else 'active'
                last_restart = datetime.now() if action in ['start', 'restart'] else None
                
                cursor.execute('''
                    UPDATE services 
                    SET status = ?, last_restart = ?
                    WHERE service_name = ?
                ''', (new_status, last_restart, service_name))
                
                conn.commit()
                conn.close()
                
                return {'success': True, 'message': f'Service {service_name} {action}ed successfully'}
            else:
                return {'success': False, 'message': f'Failed to {action} {service_name}: {result.stderr}'}
        else:
            return {'success': False, 'message': 'Invalid action'}
            
    except subprocess.TimeoutExpired:
        return {'success': False, 'message': f'Timeout while trying to {action} {service_name}'}
    except Exception as e:
        return {'success': False, 'message': f'Error managing service: {str(e)}'}

def get_service_config(service_name):
    """Get service configuration"""
    conn = sqlite3.connect(SERVICES_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('SELECT config_path FROM services WHERE service_name = ?', (service_name,))
    result = cursor.fetchone()
    conn.close()
    
    if result and os.path.exists(result[0]):
        try:
            with open(result[0], 'r') as f:
                return f.read()
        except Exception as e:
            return f"Error reading config: {str(e)}"
    
    return "Configuration file not found"

#########################################################################
# Site Management Functions
#########################################################################

def get_all_sites():
    """Get all managed sites"""
    conn = sqlite3.connect(SITES_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id, domain, subdomain, document_root, php_version, web_server,
               ssl_enabled, wp_installed, wp_version, disk_usage, bandwidth_used,
               status, created_at
        FROM sites ORDER BY created_at DESC
    ''')
    
    sites = []
    for row in cursor.fetchall():
        sites.append({
            'id': row[0],
            'domain': row[1],
            'subdomain': row[2],
            'document_root': row[3],
            'php_version': row[4],
            'web_server': row[5],
            'ssl_enabled': bool(row[6]),
            'wp_installed': bool(row[7]),
            'wp_version': row[8],
            'disk_usage': row[9],
            'bandwidth_used': row[10],
            'status': row[11],
            'created_at': row[12],
            'full_domain': f"{row[2]}.{row[1]}" if row[2] else row[1]
        })
    
    conn.close()
    return sites

def create_new_site(domain, subdomain=None, php_version='8.1', web_server='ols', install_wp=False):
    """Create a new site"""
    try:
        full_domain = f"{subdomain}.{domain}" if subdomain else domain
        document_root = f"/var/www/{full_domain}"
        
        # Create document root directory
        os.makedirs(document_root, exist_ok=True)
        
        # Create basic index.html
        index_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>Welcome to {full_domain}</title>
    <style>
        body {{ font-family: Arial, sans-serif; text-align: center; margin-top: 100px; }}
        .container {{ max-width: 600px; margin: 0 auto; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to {full_domain}!</h1>
        <p>Your website is successfully configured and running on LOMP Stack v3.0</p>
        <p>Web Server: {web_server.upper()} | PHP Version: {php_version}</p>
    </div>
</body>
</html>"""
        
        with open(os.path.join(document_root, 'index.html'), 'w') as f:
            f.write(index_content)
        
        # Configure web server virtual host
        if web_server == 'ols':
            configure_ols_vhost(full_domain, document_root, php_version)
        elif web_server == 'nginx':
            configure_nginx_vhost(full_domain, document_root, php_version)
        elif web_server == 'apache':
            configure_apache_vhost(full_domain, document_root, php_version)
        
        # Insert into database
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO sites (domain, subdomain, document_root, php_version, web_server, status)
            VALUES (?, ?, ?, ?, ?, 'active')
        ''', (domain, subdomain, document_root, php_version, web_server))
        
        site_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        # Install WordPress if requested
        if install_wp:
            wp_result = install_wordpress(site_id, full_domain, document_root)
            if not wp_result['success']:
                return {'success': False, 'message': f'Site created but WordPress installation failed: {wp_result["message"]}'}
        
        return {'success': True, 'message': f'Site {full_domain} created successfully', 'site_id': site_id}
        
    except Exception as e:
        return {'success': False, 'message': f'Error creating site: {str(e)}'}

def configure_ols_vhost(domain, document_root, php_version):
    """Configure OpenLiteSpeed virtual host"""
    if helpers:
        return helpers.create_ols_vhost(domain, document_root, php_version)
    else:
        # Fallback to direct script execution
        ols_helper = os.path.join(WEB_HELPERS_DIR, 'ols_helpers.sh')
        if os.path.exists(ols_helper):
            result = subprocess.run(['bash', ols_helper, 'add_vhost', domain, document_root, php_version], 
                                  capture_output=True, text=True)
            return {'success': result.returncode == 0, 'stdout': result.stdout, 'stderr': result.stderr}
        return {'success': False, 'message': 'OLS helper not found'}

def configure_nginx_vhost(domain, document_root, php_version):
    """Configure Nginx virtual host"""
    if helpers:
        return helpers.create_nginx_vhost(domain, document_root, php_version)
    else:
        # Fallback to direct script execution
        nginx_helper = os.path.join(WEB_HELPERS_DIR, 'nginx_helpers.sh')
        if os.path.exists(nginx_helper):
            result = subprocess.run(['bash', nginx_helper, 'add_vhost', domain, document_root, php_version], 
                                  capture_output=True, text=True)
            return {'success': result.returncode == 0, 'stdout': result.stdout, 'stderr': result.stderr}
        return {'success': False, 'message': 'Nginx helper not found'}

def configure_apache_vhost(domain, document_root, php_version):
    """Configure Apache virtual host"""
    if helpers:
        return helpers.create_apache_vhost(domain, document_root, php_version)
    else:
        # Fallback to direct script execution
        apache_helper = os.path.join(WEB_HELPERS_DIR, 'apache_helpers.sh')
        if os.path.exists(apache_helper):
            result = subprocess.run(['bash', apache_helper, 'add_vhost', domain, document_root, php_version], 
                                  capture_output=True, text=True)
            return {'success': result.returncode == 0, 'stdout': result.stdout, 'stderr': result.stderr}
        return {'success': False, 'message': 'Apache helper not found'}

#########################################################################
# WordPress Management Functions
#########################################################################

def install_wordpress(site_id, domain, document_root):
    """Install WordPress on a site"""
    try:
        # Generate random admin credentials
        wp_admin_user = 'admin'
        wp_admin_pass = secrets.token_urlsafe(12)
        wp_admin_email = f'admin@{domain}'
        
        # Create database credentials for WordPress
        db_name = f"wp_{domain.replace('.', '_').replace('-', '_')}"
        db_user = f"wp_{secrets.token_hex(4)}"
        db_pass = secrets.token_urlsafe(16)
        
        if helpers:
            # Use helpers integration
            wp_result = helpers.install_wordpress(
                domain, db_name, db_user, db_pass, 
                wp_admin_user, wp_admin_pass, wp_admin_email
            )
        else:
            # Fallback to direct script execution
            wp_helper = os.path.join(WP_HELPERS_DIR, 'wp_helpers.sh')
            if not os.path.exists(wp_helper):
                return {'success': False, 'message': 'WordPress helper not found'}
            
            # Run WordPress installation
            result = subprocess.run([
                'bash', wp_helper, 'install', 
                domain, document_root, wp_admin_user, wp_admin_pass, wp_admin_email
            ], capture_output=True, text=True, timeout=300)
            
            wp_result = {'success': result.returncode == 0, 'stderr': result.stderr}
        
        if wp_result['success']:
            # Update database
            conn = sqlite3.connect(SITES_DB_PATH)
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE sites 
                SET wp_installed = 1, wp_admin_user = ?, wp_admin_email = ?
                WHERE id = ?
            ''', (wp_admin_user, wp_admin_email, site_id))
            
            conn.commit()
            conn.close()
            
            return {
                'success': True, 
                'message': 'WordPress installed successfully',
                'admin_user': wp_admin_user,
                'admin_password': wp_admin_pass,
                'admin_email': wp_admin_email
            }
        else:
            error_msg = wp_result.get('stderr', 'WordPress installation failed')
            return {'success': False, 'message': f'WordPress installation failed: {error_msg}'}
            
    except Exception as e:
        return {'success': False, 'message': f'Error installing WordPress: {str(e)}'}

def get_wp_sites():
    """Get all WordPress sites"""
    conn = sqlite3.connect(SITES_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id, domain, subdomain, wp_version, wp_admin_user, wp_admin_email, status
        FROM sites WHERE wp_installed = 1
    ''')
    
    wp_sites = []
    for row in cursor.fetchall():
        wp_sites.append({
            'id': row[0],
            'domain': row[1],
            'subdomain': row[2],
            'wp_version': row[3],
            'admin_user': row[4],
            'admin_email': row[5],
            'status': row[6],
            'full_domain': f"{row[2]}.{row[1]}" if row[2] else row[1]
        })
    
    conn.close()
    return wp_sites

#########################################################################
# Domain Management Functions
#########################################################################

def get_all_domains():
    """Get all managed domains"""
    conn = sqlite3.connect(DOMAINS_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT domain_name, domain_type, nameservers, registrar, expiry_date,
               cloudflare_enabled, status, created_at
        FROM domains ORDER BY domain_name
    ''')
    
    domains = []
    for row in cursor.fetchall():
        domains.append({
            'name': row[0],
            'type': row[1],
            'nameservers': row[2],
            'registrar': row[3],
            'expiry_date': row[4],
            'cloudflare_enabled': bool(row[5]),
            'status': row[6],
            'created_at': row[7]
        })
    
    conn.close()
    return domains

def add_domain(domain_name, domain_type='primary', nameservers=None, registrar=None):
    """Add a new domain"""
    try:
        conn = sqlite3.connect(DOMAINS_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO domains (domain_name, domain_type, nameservers, registrar)
            VALUES (?, ?, ?, ?)
        ''', (domain_name, domain_type, nameservers, registrar))
        
        conn.commit()
        conn.close()
        
        return {'success': True, 'message': f'Domain {domain_name} added successfully'}
        
    except sqlite3.IntegrityError:
        return {'success': False, 'message': 'Domain already exists'}
    except Exception as e:
        return {'success': False, 'message': f'Error adding domain: {str(e)}'}

#########################################################################
# Python Application Management Functions
#########################################################################

def get_python_apps():
    """Get all Python applications"""
    conn = sqlite3.connect(SITES_DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT domain, subdomain, site_type, python_version, python_framework, 
               python_venv_path, python_port, status, ssl_enabled, created_at
        FROM sites 
        WHERE site_type = 'python'
        ORDER BY created_at DESC
    ''')
    
    apps = []
    for row in cursor.fetchall():
        full_domain = row[0]
        if row[1]:  # subdomain
            full_domain = f"{row[0]}/{row[1]}"
            
        apps.append({
            'domain': row[0],
            'subdomain': row[1],
            'full_domain': full_domain,
            'site_type': row[2],
            'python_version': row[3],
            'python_framework': row[4],
            'python_venv_path': row[5],
            'python_port': row[6],
            'status': row[7],
            'ssl_enabled': bool(row[8]),
            'created_at': row[9]
        })
    
    conn.close()
    return apps

def create_python_app(domain, subdomain, framework, python_version='3.11', git_repo=None):
    """Create a new Python application"""
    try:
        full_domain = domain
        if subdomain:
            full_domain = f"{domain}/{subdomain}"
        
        document_root = f"/var/www/{domain}"
        if subdomain:
            document_root = f"/var/www/{domain}/{subdomain}"
        
        venv_path = f"{document_root}/venv"
        
        # Find available port for the Python app
        import random
        python_port = random.randint(8000, 9000)
        
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO sites 
            (domain, subdomain, document_root, site_type, python_version, 
             python_framework, python_venv_path, python_port, web_server)
            VALUES (?, ?, ?, 'python', ?, ?, ?, ?, 'nginx')
        ''', (domain, subdomain, document_root, python_version, framework, venv_path, python_port))
        
        site_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        # Create directory structure
        result = setup_python_environment(site_id, framework, git_repo)
        
        if result['success']:
            return {
                'success': True, 
                'message': f'Python {framework} app created successfully',
                'site_id': site_id,
                'port': python_port,
                'domain': full_domain
            }
        else:
            return result
            
    except Exception as e:
        return {'success': False, 'message': f'Error creating Python app: {str(e)}'}

def setup_python_environment(site_id, framework, git_repo=None):
    """Setup Python environment for the application"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT document_root, python_version, python_venv_path, python_port, domain, subdomain
            FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return {'success': False, 'message': 'Site not found'}
        
        document_root, python_version, venv_path, python_port, domain, subdomain = row
        
        # Create directory structure
        os.makedirs(document_root, exist_ok=True)
        os.makedirs(f"{document_root}/static", exist_ok=True)
        os.makedirs(f"{document_root}/templates", exist_ok=True)
        
        # Create virtual environment
        if os.name == 'nt':  # Windows
            venv_cmd = ['python', '-m', 'venv', venv_path]
            pip_path = f"{venv_path}\\Scripts\\pip"
            python_path = f"{venv_path}\\Scripts\\python"
        else:  # Linux/Unix
            venv_cmd = ['python3', '-m', 'venv', venv_path]
            pip_path = f"{venv_path}/bin/pip"
            python_path = f"{venv_path}/bin/python"
        
        venv_result = subprocess.run(venv_cmd, capture_output=True, text=True)
        
        if venv_result.returncode != 0:
            return {'success': False, 'message': f'Failed to create virtual environment: {venv_result.stderr}'}
        
        # Create requirements.txt based on framework
        requirements_content = get_framework_requirements(framework)
        with open(f"{document_root}/requirements.txt", 'w') as f:
            f.write(requirements_content)
        
        # Install requirements
        pip_install = subprocess.run([
            pip_path, "install", "-r", f"{document_root}/requirements.txt"
        ], capture_output=True, text=True)
        
        if pip_install.returncode != 0:
            return {'success': False, 'message': f'Failed to install requirements: {pip_install.stderr}'}
        
        # Create application template
        create_app_template(document_root, framework, python_port)
        
        # Setup systemd service and nginx configuration using helpers
        full_domain = f"{subdomain}.{domain}" if subdomain else domain
        app_name = f"{domain}_{subdomain}" if subdomain else domain
        app_name = app_name.replace('.', '_').replace('-', '_')
        
        if helpers and os.name != 'nt':  # Only on Linux
            # Setup systemd service
            service_result = helpers.setup_python_systemd_service(
                app_name, document_root, venv_path, python_port
            )
            
            # Setup nginx configuration
            nginx_result = helpers.setup_python_nginx_config(
                full_domain, python_port, document_root
            )
            
            if not service_result['success']:
                return {'success': False, 'message': f'Failed to setup systemd service: {service_result.get("error", "Unknown error")}'}
            
            if not nginx_result['success']:
                return {'success': False, 'message': f'Failed to setup nginx config: {nginx_result.get("error", "Unknown error")}'}
        else:
            # Fallback or Windows - create configs manually
            create_python_service(site_id, domain, subdomain, document_root, venv_path, python_port, framework)
        configure_webserver_for_python(domain, subdomain, python_port)
        
        return {'success': True, 'message': 'Python environment setup completed'}
        
    except Exception as e:
        return {'success': False, 'message': f'Error setting up environment: {str(e)}'}

def get_framework_requirements(framework):
    """Get requirements.txt content based on framework"""
    requirements = {
        'flask': """Flask==2.3.3
gunicorn==21.2.0
python-dotenv==1.0.0""",
        'django': """Django==4.2.7
gunicorn==21.2.0
python-dotenv==1.0.0
psycopg2-binary==2.9.7""",
        'fastapi': """fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
python-multipart==0.0.6""",
        'pyramid': """pyramid==2.0.2
waitress==2.1.2
python-dotenv==1.0.0""",
        'custom': """# Add your custom requirements here
python-dotenv==1.0.0"""
    }
    return requirements.get(framework, requirements['custom'])

def create_app_template(document_root, framework, port):
    """Create basic application template"""
    templates = {
        'flask': f"""from flask import Flask, render_template
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html', title='Welcome to Flask')

@app.route('/api/health')
def health():
    return {{'status': 'healthy', 'framework': 'flask'}}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port={port}, debug=False)
""",
        'django': f"""# Django project created
# Run: python manage.py startproject myproject .
# Configure settings.py for production
""",
        'fastapi': f"""from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(title="FastAPI Application")

app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/", response_class=HTMLResponse)
async def read_root():
    return '''
    <html>
        <head><title>FastAPI App</title></head>
        <body>
            <h1>Welcome to FastAPI!</h1>
            <p>Your application is running successfully.</p>
        </body>
    </html>
    '''

@app.get("/api/health")
async def health():
    return {{"status": "healthy", "framework": "fastapi"}}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port={port})
"""
    }
    
    # Create main application file
    app_content = templates.get(framework, f"# {framework} application\nprint('Hello from {framework}!')")
    
    if framework == 'django':
        # For Django, create manage.py and basic structure
        with open(f"{document_root}/manage.py", 'w') as f:
            f.write("""#!/usr/bin/env python
import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)
""")
    else:
        with open(f"{document_root}/app.py", 'w') as f:
            f.write(app_content)
    
    # Create basic HTML template
    with open(f"{document_root}/templates/index.html", 'w') as f:
        f.write(f"""<!DOCTYPE html>
<html>
<head>
    <title>{{{{ title or 'Python Application' }}</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-body text-center">
                        <h1 class="card-title">Welcome to {framework.title()}!</h1>
                        <p class="card-text">Your Python application is running successfully.</p>
                        <p class="text-muted">Framework: {framework}</p>
                        <a href="/api/health" class="btn btn-primary">Health Check</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>""")
    
    # Create .env file
    with open(f"{document_root}/.env", 'w') as f:
        f.write(f"""# Environment Configuration
DEBUG=False
SECRET_KEY=your-secret-key-here
PORT={port}
ENVIRONMENT=production
""")

def create_python_service(site_id, domain, subdomain, document_root, venv_path, port, framework):
    """Create systemd service for Python application"""
    service_name = f"python-{domain}"
    if subdomain:
        service_name = f"python-{domain}-{subdomain}"
    
    # Determine the command based on framework
    if framework == 'django':
        exec_start = f"{venv_path}/bin/gunicorn myproject.wsgi:application --bind 127.0.0.1:{port}"
    elif framework == 'fastapi':
        exec_start = f"{venv_path}/bin/uvicorn app:app --host 127.0.0.1 --port {port}"
    else:  # flask, pyramid, custom
        exec_start = f"{venv_path}/bin/gunicorn app:app --bind 127.0.0.1:{port}"
    
    service_content = f"""[Unit]
Description={framework.title()} application for {domain}
After=network.target

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory={document_root}
Environment=PATH={venv_path}/bin
ExecStart={exec_start}
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
"""
    
    service_path = f"/etc/systemd/system/{service_name}.service"
    
    try:
        with open(service_path, 'w') as f:
            f.write(service_content)
        
        # Reload systemd and enable service
        subprocess.run(['systemctl', 'daemon-reload'], check=True)
        subprocess.run(['systemctl', 'enable', service_name], check=True)
        subprocess.run(['systemctl', 'start', service_name], check=True)
        
        # Update database with service name
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE sites SET python_wsgi_file = ? WHERE id = ?
        ''', (service_name, site_id))
        conn.commit()
        conn.close()
        
        return True
    except Exception as e:
        print(f"Error creating service: {e}")
        return False

def configure_webserver_for_python(domain, subdomain, port):
    """Configure nginx to proxy to Python application"""
    server_name = domain
    if subdomain:
        server_name = f"{subdomain}.{domain}"
    
    nginx_config = f"""server {{
    listen 80;
    server_name {server_name};
    
    location / {{
        proxy_pass http://127.0.0.1:{port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }}
    
    location /static/ {{
        alias /var/www/{domain}{('/' + subdomain) if subdomain else ''}/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }}
    
    location /media/ {{
        alias /var/www/{domain}{('/' + subdomain) if subdomain else ''}/media/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }}
}}
"""
    
    config_path = f"/etc/nginx/sites-available/{server_name}"
    
    try:
        with open(config_path, 'w') as f:
            f.write(nginx_config)
        
        # Enable site
        symlink_path = f"/etc/nginx/sites-enabled/{server_name}"
        if not os.path.exists(symlink_path):
            os.symlink(config_path, symlink_path)
        
        # Test and reload nginx
        test_result = subprocess.run(['nginx', '-t'], capture_output=True, text=True)
        if test_result.returncode == 0:
            subprocess.run(['systemctl', 'reload', 'nginx'])
            return True
        else:
            print(f"Nginx config test failed: {test_result.stderr}")
            return False
            
    except Exception as e:
        print(f"Error configuring nginx: {e}")
        return False

def manage_python_app(site_id, action):
    """Manage Python application (start/stop/restart)"""
    try:
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('SELECT python_wsgi_file FROM sites WHERE id = ?', (site_id,))
        result = cursor.fetchone()
        conn.close()
        
        if not result or not result[0]:
            return {'success': False, 'message': 'Service not found'}
        
        service_name = result[0]
        
        if action in ['start', 'stop', 'restart', 'reload']:
            cmd_result = subprocess.run(
                ['systemctl', action, service_name],
                capture_output=True, text=True
            )
            
            if cmd_result.returncode == 0:
                # Update status in database
                new_status = 'active' if action in ['start', 'restart'] else 'inactive'
                conn = sqlite3.connect(SITES_DB_PATH)
                cursor = conn.cursor()
                cursor.execute('UPDATE sites SET status = ? WHERE id = ?', (new_status, site_id))
                conn.commit()
                conn.close()
                
                return {'success': True, 'message': f'Application {action}ed successfully'}
            else:
                return {'success': False, 'message': f'Failed to {action} application: {cmd_result.stderr}'}
        else:
            return {'success': False, 'message': 'Invalid action'}
            
    except Exception as e:
        return {'success': False, 'message': f'Error managing application: {str(e)}'}

def get_python_app_logs(site_id):
    """Get logs for Python application"""
    try:
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('SELECT python_wsgi_file FROM sites WHERE id = ?', (site_id,))
        result = cursor.fetchone()
        conn.close()
        
        if not result or not result[0]:
            return {'success': False, 'message': 'Service not found'}
        
        service_name = result[0]
        
        # Get systemd logs
        log_result = subprocess.run(
            ['journalctl', '-u', service_name, '--no-pager', '-n', '50'],
            capture_output=True, text=True
        )
        
        if log_result.returncode == 0:
            return {'success': True, 'logs': log_result.stdout}
        else:
            return {'success': False, 'message': 'Failed to retrieve logs'}
            
    except Exception as e:
        return {'success': False, 'message': f'Error retrieving logs: {str(e)}'}

#########################################################################
# Initialize hosting databases on import
#########################################################################

# Initialize databases when module is imported
init_hosting_databases()

if __name__ == '__main__':
    print("LOMP Hosting Control Panel - Extended Dashboard Module")
    print("This module extends the admin dashboard with hosting features.")
