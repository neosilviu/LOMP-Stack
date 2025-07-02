#!/usr/bin/env python3
"""
LOMP Stack v3.0 - Enhanced Python Applications Management
Advanced management features for Python web applications

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
import secrets
import logging
from datetime import datetime
from flask import request, jsonify, flash
from functools import wraps

# Import from hosting management
from hosting_management import (
    app, require_auth, SITES_DB_PATH, helpers,
    get_python_apps, create_python_app, setup_python_environment
)

logger = logging.getLogger(__name__)

#########################################################################
# Enhanced Python Application Management
#########################################################################

@app.route('/api/python-apps/deploy-from-git', methods=['POST'])
@require_auth
def api_deploy_python_from_git():
    """Deploy Python application from Git repository"""
    try:
        data = request.get_json()
        domain = data.get('domain')
        subdomain = data.get('subdomain', '')
        framework = data.get('framework')
        git_repo = data.get('git_repo')
        git_branch = data.get('git_branch', 'main')
        python_version = data.get('python_version', '3.11')
        
        if not all([domain, framework, git_repo]):
            return jsonify({'success': False, 'message': 'Missing required fields'}), 400
        
        # Create the Python app first
        result = create_python_app(domain, subdomain, framework, python_version, git_repo)
        
        if not result['success']:
            return jsonify(result), 400
        
        site_id = result['site_id']
        
        # Clone repository and setup deployment
        deploy_result = deploy_from_git_repository(site_id, git_repo, git_branch)
        
        if deploy_result['success']:
            return jsonify({
                'success': True, 
                'message': 'Python app deployed successfully from Git',
                'site_id': site_id,
                'deployment_info': deploy_result
            })
        else:
            return jsonify(deploy_result), 500
            
    except Exception as e:
        logger.error(f"Error deploying Python app from Git: {str(e)}")
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@app.route('/api/python-apps/<int:site_id>/environment', methods=['GET'])
@require_auth
def api_get_python_environment(site_id):
    """Get Python application environment variables"""
    try:
        env_vars = get_python_environment_variables(site_id)
        return jsonify({'success': True, 'environment': env_vars})
        
    except Exception as e:
        logger.error(f"Error getting Python environment: {str(e)}")
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@app.route('/api/python-apps/<int:site_id>/environment', methods=['POST'])
@require_auth
def api_update_python_environment(site_id):
    """Update Python application environment variables"""
    try:
        data = request.get_json()
        env_vars = data.get('environment', {})
        
        result = update_python_environment_variables(site_id, env_vars)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error updating Python environment: {str(e)}")
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@app.route('/api/python-apps/<int:site_id>/dependencies', methods=['GET'])
@require_auth
def api_get_python_dependencies(site_id):
    """Get Python application dependencies"""
    try:
        deps = get_python_dependencies(site_id)
        return jsonify({'success': True, 'dependencies': deps})
        
    except Exception as e:
        logger.error(f"Error getting Python dependencies: {str(e)}")
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@app.route('/api/python-apps/<int:site_id>/dependencies', methods=['POST'])
@require_auth
def api_install_python_dependencies(site_id):
    """Install Python dependencies"""
    try:
        data = request.get_json()
        packages = data.get('packages', [])
        
        result = install_python_dependencies(site_id, packages)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error installing Python dependencies: {str(e)}")
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@app.route('/api/python-apps/<int:site_id>/performance', methods=['GET'])
@require_auth
def api_get_python_performance(site_id):
    """Get Python application performance metrics"""
    try:
        metrics = get_python_performance_metrics(site_id)
        return jsonify({'success': True, 'metrics': metrics})
        
    except Exception as e:
        logger.error(f"Error getting Python performance metrics: {str(e)}")
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@app.route('/api/python-apps/<int:site_id>/database', methods=['POST'])
@require_auth
def api_setup_python_database(site_id):
    """Setup database for Python application"""
    try:
        data = request.get_json()
        db_type = data.get('db_type', 'postgresql')  # postgresql, mysql, sqlite
        db_name = data.get('db_name')
        
        result = setup_python_database(site_id, db_type, db_name)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error setting up Python database: {str(e)}")
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@app.route('/api/python-apps/<int:site_id>/ssl', methods=['POST'])
@require_auth
def api_setup_python_ssl(site_id):
    """Setup SSL for Python application"""
    try:
        data = request.get_json()
        email = data.get('email')
        
        result = setup_python_ssl_certificate(site_id, email)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error setting up Python SSL: {str(e)}")
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

#########################################################################
# Helper Functions for Enhanced Python Management
#########################################################################

def deploy_from_git_repository(site_id, git_repo, git_branch='main'):
    """Deploy Python application from Git repository"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT document_root, python_venv_path, domain, subdomain, python_framework
            FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return {'success': False, 'message': 'Site not found'}
        
        document_root, venv_path, domain, subdomain, framework = row
        
        # Clone repository
        clone_result = subprocess.run([
            'git', 'clone', '-b', git_branch, git_repo, f"{document_root}/src"
        ], capture_output=True, text=True)
        
        if clone_result.returncode != 0:
            return {'success': False, 'message': f'Git clone failed: {clone_result.stderr}'}
        
        # Copy application files
        src_dir = f"{document_root}/src"
        
        # Install dependencies if requirements.txt exists
        requirements_file = os.path.join(src_dir, 'requirements.txt')
        if os.path.exists(requirements_file):
            # Copy requirements.txt to root
            subprocess.run(['cp', requirements_file, document_root])
            
            # Install dependencies
            pip_path = f"{venv_path}/bin/pip" if os.name != 'nt' else f"{venv_path}\\Scripts\\pip"
            pip_result = subprocess.run([
                pip_path, 'install', '-r', requirements_file
            ], capture_output=True, text=True)
            
            if pip_result.returncode != 0:
                return {'success': False, 'message': f'Dependency installation failed: {pip_result.stderr}'}
        
        # Copy application files
        for item in os.listdir(src_dir):
            if item not in ['.git', '.gitignore', 'README.md']:
                src_path = os.path.join(src_dir, item)
                dest_path = os.path.join(document_root, item)
                if os.path.isdir(src_path):
                    subprocess.run(['cp', '-r', src_path, dest_path])
                else:
                    subprocess.run(['cp', src_path, dest_path])
        
        # Update database with Git info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            UPDATE sites 
            SET python_requirements_file = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ''', (f"{document_root}/requirements.txt", site_id))
        
        conn.commit()
        conn.close()
        
        return {
            'success': True, 
            'message': 'Application deployed successfully from Git',
            'git_repo': git_repo,
            'git_branch': git_branch
        }
        
    except Exception as e:
        return {'success': False, 'message': f'Deployment failed: {str(e)}'}

def get_python_environment_variables(site_id):
    """Get environment variables for Python application"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT document_root FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return {}
        
        document_root = row[0]
        env_file = os.path.join(document_root, '.env')
        
        env_vars = {}
        if os.path.exists(env_file):
            with open(env_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        env_vars[key.strip()] = value.strip()
        
        return env_vars
        
    except Exception as e:
        logger.error(f"Error getting environment variables: {str(e)}")
        return {}

def update_python_environment_variables(site_id, env_vars):
    """Update environment variables for Python application"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT document_root, domain, subdomain FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return {'success': False, 'message': 'Site not found'}
        
        document_root, domain, subdomain = row
        env_file = os.path.join(document_root, '.env')
        
        # Write environment variables to .env file
        with open(env_file, 'w') as f:
            f.write(f"# Environment variables for {domain}\n")
            f.write(f"# Generated on {datetime.now().isoformat()}\n\n")
            
            for key, value in env_vars.items():
                f.write(f"{key}={value}\n")
        
        # Restart the application service if using systemd
        app_name = f"{domain}_{subdomain}" if subdomain else domain
        app_name = app_name.replace('.', '_').replace('-', '_')
        
        if helpers and os.name != 'nt':
            restart_result = subprocess.run([
                'systemctl', 'restart', f"{app_name}.service"
            ], capture_output=True, text=True)
            
            if restart_result.returncode != 0:
                logger.warning(f"Failed to restart service {app_name}: {restart_result.stderr}")
        
        return {'success': True, 'message': 'Environment variables updated successfully'}
        
    except Exception as e:
        return {'success': False, 'message': f'Error updating environment: {str(e)}'}

def get_python_dependencies(site_id):
    """Get installed Python dependencies"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT python_venv_path FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return []
        
        venv_path = row[0]
        pip_path = f"{venv_path}/bin/pip" if os.name != 'nt' else f"{venv_path}\\Scripts\\pip"
        
        # Get installed packages
        result = subprocess.run([
            pip_path, 'list', '--format=json'
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            return []
            
    except Exception as e:
        logger.error(f"Error getting dependencies: {str(e)}")
        return []

def install_python_dependencies(site_id, packages):
    """Install Python dependencies"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT python_venv_path, document_root FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return {'success': False, 'message': 'Site not found'}
        
        venv_path, document_root = row
        pip_path = f"{venv_path}/bin/pip" if os.name != 'nt' else f"{venv_path}\\Scripts\\pip"
        
        # Install packages
        for package in packages:
            install_result = subprocess.run([
                pip_path, 'install', package
            ], capture_output=True, text=True)
            
            if install_result.returncode != 0:
                return {'success': False, 'message': f'Failed to install {package}: {install_result.stderr}'}
        
        # Update requirements.txt
        freeze_result = subprocess.run([
            pip_path, 'freeze'
        ], capture_output=True, text=True)
        
        if freeze_result.returncode == 0:
            with open(f"{document_root}/requirements.txt", 'w') as f:
                f.write(freeze_result.stdout)
        
        return {'success': True, 'message': f'Successfully installed {len(packages)} packages'}
        
    except Exception as e:
        return {'success': False, 'message': f'Error installing dependencies: {str(e)}'}

def get_python_performance_metrics(site_id):
    """Get performance metrics for Python application"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT domain, subdomain, python_port FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return {}
        
        domain, subdomain, python_port = row
        app_name = f"{domain}_{subdomain}" if subdomain else domain
        app_name = app_name.replace('.', '_').replace('-', '_')
        
        metrics = {
            'cpu_usage': 0,
            'memory_usage': 0,
            'disk_usage': 0,
            'response_time': 0,
            'uptime': '0 seconds',
            'status': 'unknown'
        }
        
        if os.name != 'nt':  # Linux only
            # Get service status
            status_result = subprocess.run([
                'systemctl', 'is-active', f"{app_name}.service"
            ], capture_output=True, text=True)
            
            metrics['status'] = status_result.stdout.strip() if status_result.returncode == 0 else 'inactive'
            
            # Get basic process info if service is active
            if metrics['status'] == 'active':
                # This is a simplified version - in production you'd use proper monitoring tools
                ps_result = subprocess.run([
                    'ps', 'aux'
                ], capture_output=True, text=True)
                
                if ps_result.returncode == 0:
                    for line in ps_result.stdout.split('\n'):
                        if app_name in line and 'python' in line:
                            parts = line.split()
                            if len(parts) >= 11:
                                metrics['cpu_usage'] = float(parts[2])
                                metrics['memory_usage'] = float(parts[3])
                            break
        
        return metrics
        
    except Exception as e:
        logger.error(f"Error getting performance metrics: {str(e)}")
        return {}

def setup_python_database(site_id, db_type, db_name=None):
    """Setup database for Python application"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT domain, subdomain FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return {'success': False, 'message': 'Site not found'}
        
        domain, subdomain = row
        
        if not db_name:
            db_name = f"{domain}_{subdomain}" if subdomain else domain
            db_name = db_name.replace('.', '_').replace('-', '_')
        
        # Generate database credentials
        db_user = f"user_{secrets.token_hex(4)}"
        db_pass = secrets.token_urlsafe(16)
        
        if helpers:
            # Use helpers integration to create database
            db_result = helpers.create_database(db_name, db_user, db_pass, db_type)
            
            if db_result['success']:
                # Add database connection info to environment
                env_vars = {
                    'DB_TYPE': db_type,
                    'DB_NAME': db_name,
                    'DB_USER': db_user,
                    'DB_PASSWORD': db_pass,
                    'DB_HOST': 'localhost',
                    'DB_PORT': '5432' if db_type == 'postgresql' else '3306'
                }
                
                update_python_environment_variables(site_id, env_vars)
                
                return {
                    'success': True,
                    'message': f'{db_type.title()} database created successfully',
                    'database': {
                        'name': db_name,
                        'user': db_user,
                        'password': db_pass,
                        'type': db_type
                    }
                }
            else:
                return db_result
        else:
            return {'success': False, 'message': 'Database helpers not available'}
            
    except Exception as e:
        return {'success': False, 'message': f'Error setting up database: {str(e)}'}

def setup_python_ssl_certificate(site_id, email=None):
    """Setup SSL certificate for Python application"""
    try:
        # Get site info
        conn = sqlite3.connect(SITES_DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT domain, subdomain FROM sites WHERE id = ?
        ''', (site_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return {'success': False, 'message': 'Site not found'}
        
        domain, subdomain = row
        full_domain = f"{subdomain}.{domain}" if subdomain else domain
        
        if helpers:
            # Use helpers integration to setup SSL
            ssl_result = helpers.install_ssl_certificate(full_domain, email)
            
            if ssl_result['success']:
                # Update database to mark SSL as enabled
                conn = sqlite3.connect(SITES_DB_PATH)
                cursor = conn.cursor()
                
                cursor.execute('''
                    UPDATE sites 
                    SET ssl_enabled = 1, updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                ''', (site_id,))
                
                conn.commit()
                conn.close()
                
                return {
                    'success': True,
                    'message': f'SSL certificate installed for {full_domain}'
                }
            else:
                return ssl_result
        else:
            return {'success': False, 'message': 'SSL helpers not available'}
            
    except Exception as e:
        return {'success': False, 'message': f'Error setting up SSL: {str(e)}'}
