#!/usr/bin/env python3
"""
LOMP Stack v3.0 - Helper Scripts Integration Layer
Bridge between Python control panel and existing bash helper scripts

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
import subprocess
import json
import logging
from typing import Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)

class HelperScriptsIntegration:
    """Integration layer for calling LOMP Stack helper scripts from Python"""
    
    def __init__(self, stack_root: str):
        self.stack_root = stack_root
        self.helpers_dir = os.path.join(stack_root, 'helpers')
        self.web_helpers_dir = os.path.join(self.helpers_dir, 'web')
        self.wp_helpers_dir = os.path.join(self.helpers_dir, 'wp')
        self.security_helpers_dir = os.path.join(self.helpers_dir, 'security')
        self.utils_helpers_dir = os.path.join(self.helpers_dir, 'utils')
        self.monitoring_helpers_dir = os.path.join(self.helpers_dir, 'monitoring')
        
    def _run_helper_script(self, script_path: str, args: Optional[List[str]] = None, 
                          capture_output: bool = True) -> Dict:
        """Run a helper script with error handling"""
        try:
            if not os.path.exists(script_path):
                return {
                    'success': False, 
                    'error': f'Helper script not found: {script_path}'
                }
            
            cmd = ['bash', script_path]
            if args:
                cmd.extend(args)
            
            result = subprocess.run(
                cmd,
                capture_output=capture_output,
                text=True,
                cwd=self.stack_root
            )
            
            return {
                'success': result.returncode == 0,
                'stdout': result.stdout if capture_output else '',
                'stderr': result.stderr if capture_output else '',
                'returncode': result.returncode
            }
            
        except Exception as e:
            logger.error(f"Error running helper script {script_path}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # Web Server Management
    def create_nginx_vhost(self, domain: str, document_root: str, 
                          php_version: str = "8.1") -> Dict:
        """Create nginx virtual host using helper script"""
        script_path = os.path.join(self.web_helpers_dir, 'nginx_helpers.sh')
        return self._run_helper_script(script_path, [
            'add_vhost', domain, document_root, php_version
        ])
    
    def create_apache_vhost(self, domain: str, document_root: str, 
                           php_version: str = "8.1") -> Dict:
        """Create Apache virtual host using helper script"""
        script_path = os.path.join(self.web_helpers_dir, 'apache_helpers.sh')
        return self._run_helper_script(script_path, [
            'add_vhost', domain, document_root, php_version
        ])
    
    def create_ols_vhost(self, domain: str, document_root: str, 
                        php_version: str = "8.1") -> Dict:
        """Create OpenLiteSpeed virtual host using helper script"""
        script_path = os.path.join(self.web_helpers_dir, 'ols_helpers.sh')
        return self._run_helper_script(script_path, [
            'add_vhost', domain, document_root, php_version
        ])
    
    def restart_web_server(self, server_type: str) -> Dict:
        """Restart web server using helper script"""
        script_path = os.path.join(self.web_helpers_dir, 'web_actions.sh')
        return self._run_helper_script(script_path, ['restart', server_type])
    
    def reload_web_server(self, server_type: str) -> Dict:
        """Reload web server configuration using helper script"""
        script_path = os.path.join(self.web_helpers_dir, 'web_actions.sh')
        return self._run_helper_script(script_path, ['reload', server_type])
    
    # WordPress Management
    def install_wordpress(self, domain: str, db_name: str, db_user: str, 
                         db_pass: str, wp_admin_user: str, wp_admin_pass: str, 
                         wp_admin_email: str) -> Dict:
        """Install WordPress using helper script"""
        script_path = os.path.join(self.wp_helpers_dir, 'wp_helpers.sh')
        return self._run_helper_script(script_path, [
            'install_wp', domain, db_name, db_user, db_pass, 
            wp_admin_user, wp_admin_pass, wp_admin_email
        ])
    
    def update_wordpress(self, domain: str) -> Dict:
        """Update WordPress using helper script"""
        script_path = os.path.join(self.wp_helpers_dir, 'wp_helpers.sh')
        return self._run_helper_script(script_path, ['update_wp', domain])
    
    def backup_wordpress(self, domain: str, backup_path: str) -> Dict:
        """Backup WordPress using helper script"""
        script_path = os.path.join(self.wp_helpers_dir, 'wp_helpers.sh')
        return self._run_helper_script(script_path, ['backup_wp', domain, backup_path])
    
    def configure_wp_config(self, domain: str, config_options: Dict) -> Dict:
        """Configure WordPress wp-config.php using helper script"""
        script_path = os.path.join(self.wp_helpers_dir, 'wp_config_helper.sh')
        
        # Convert config options to command line arguments
        args = ['configure', domain]
        for key, value in config_options.items():
            args.extend([f'--{key}', str(value)])
        
        return self._run_helper_script(script_path, args)
    
    # Security Management
    def setup_firewall(self, ports: List[str]) -> Dict:
        """Setup firewall using security helper script"""
        script_path = os.path.join(self.security_helpers_dir, 'security_helpers.sh')
        return self._run_helper_script(script_path, ['enable_firewall'] + ports)
    
    def install_ssl_certificate(self, domain: str, email: Optional[str] = None) -> Dict:
        """Install SSL certificate using helper script"""
        script_path = os.path.join(self.security_helpers_dir, 'ssl_helpers.sh')
        args = ['install_ssl', domain]
        if email:
            args.append(email)
        return self._run_helper_script(script_path, args)
    
    def setup_redis(self) -> Dict:
        """Setup Redis using security helper script"""
        script_path = os.path.join(self.security_helpers_dir, 'install_redis.sh')
        return self._run_helper_script(script_path)
    
    def configure_cloudflare(self, domain: str, api_token: str) -> Dict:
        """Configure Cloudflare using helper script"""
        script_path = os.path.join(self.security_helpers_dir, 'cloudflare_helpers.sh')
        return self._run_helper_script(script_path, ['configure', domain, api_token])
    
    # Monitoring and System
    def install_monitoring(self) -> Dict:
        """Install monitoring stack using helper script"""
        script_path = os.path.join(self.monitoring_helpers_dir, 'install_monitoring.sh')
        return self._run_helper_script(script_path)
    
    def get_system_status(self) -> Dict:
        """Get system status using helper script"""
        script_path = os.path.join(self.monitoring_helpers_dir, 'system_helpers.sh')
        return self._run_helper_script(script_path, ['system_status'])
    
    def restart_services(self, services: List[str]) -> Dict:
        """Restart multiple services using helper script"""
        script_path = os.path.join(self.monitoring_helpers_dir, 'system_helpers.sh')
        return self._run_helper_script(script_path, ['restart_services'] + services)
    
    def show_stack_urls(self) -> Dict:
        """Show stack URLs using helper script"""
        script_path = os.path.join(self.monitoring_helpers_dir, 'system_helpers.sh')
        return self._run_helper_script(script_path, ['show_stack_urls'])
    
    # Backup Management
    def create_backup(self, backup_type: str, source_path: str, 
                     backup_name: Optional[str] = None) -> Dict:
        """Create backup using backup helper script"""
        script_path = os.path.join(self.utils_helpers_dir, 'backup_helpers.sh')
        args = ['create_backup', backup_type, source_path]
        if backup_name:
            args.append(backup_name)
        return self._run_helper_script(script_path, args)
    
    def restore_backup(self, backup_path: str, restore_path: str) -> Dict:
        """Restore backup using backup helper script"""
        script_path = os.path.join(self.utils_helpers_dir, 'backup_helpers.sh')
        return self._run_helper_script(script_path, [
            'restore_backup', backup_path, restore_path
        ])
    
    # Database Management
    def create_database(self, db_name: str, db_user: str, db_pass: str,
                       db_type: str = 'mysql') -> Dict:
        """Create database using database helper script"""
        if db_type == 'mysql':
            script_path = os.path.join(self.helpers_dir, 'db', 'db_mysql.sh')
        elif db_type == 'mariadb':
            script_path = os.path.join(self.helpers_dir, 'db', 'db_mariadb.sh')
        else:
            return {'success': False, 'error': f'Unsupported database type: {db_type}'}
        
        return self._run_helper_script(script_path, [
            'create_db', db_name, db_user, db_pass
        ])
    
    def backup_database(self, db_name: str, backup_path: str,
                       db_type: str = 'mysql') -> Dict:
        """Backup database using database helper script"""
        if db_type == 'mysql':
            script_path = os.path.join(self.helpers_dir, 'db', 'db_mysql.sh')
        elif db_type == 'mariadb':
            script_path = os.path.join(self.helpers_dir, 'db', 'db_mariadb.sh')
        else:
            return {'success': False, 'error': f'Unsupported database type: {db_type}'}
        
        return self._run_helper_script(script_path, [
            'backup_db', db_name, backup_path
        ])
    
    # Python Application Management
    def setup_python_systemd_service(self, app_name: str, app_path: str, 
                                    python_path: str, port: int, user: str = 'www-data') -> Dict:
        """Setup systemd service for Python application"""
        service_content = f"""[Unit]
Description={app_name} Python Web Application
After=network.target

[Service]
Type=simple
User={user}
WorkingDirectory={app_path}
Environment=PATH={python_path}/bin
ExecStart={python_path}/bin/python app.py
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier={app_name}
Environment=PORT={port}

[Install]
WantedBy=multi-user.target
"""
        
        try:
            service_file_path = f'/etc/systemd/system/{app_name}.service'
            with open(service_file_path, 'w') as f:
                f.write(service_content)
            
            # Reload systemd and enable service
            subprocess.run(['systemctl', 'daemon-reload'], check=True)
            subprocess.run(['systemctl', 'enable', app_name], check=True)
            subprocess.run(['systemctl', 'start', app_name], check=True)
            
            return {'success': True, 'message': f'Systemd service {app_name} created and started'}
            
        except Exception as e:
            return {'success': False, 'error': f'Failed to setup systemd service: {str(e)}'}
    
    def setup_python_nginx_config(self, domain: str, port: int, 
                                 document_root: Optional[str] = None) -> Dict:
        """Setup nginx configuration for Python application"""
        nginx_config = f"""server {{
    listen 80;
    server_name {domain};
    
    location / {{
        proxy_pass http://127.0.0.1:{port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }}
"""
        
        if document_root:
            nginx_config += f"""
    location /static {{
        alias {document_root}/static;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }}
"""
        
        nginx_config += "}\n"
        
        try:
            config_file_path = f'/etc/nginx/sites-available/{domain}'
            with open(config_file_path, 'w') as f:
                f.write(nginx_config)
            
            # Enable site
            symlink_path = f'/etc/nginx/sites-enabled/{domain}'
            if not os.path.exists(symlink_path):
                os.symlink(config_file_path, symlink_path)
            
            # Test nginx configuration
            test_result = subprocess.run(['nginx', '-t'], capture_output=True, text=True)
            if test_result.returncode == 0:
                subprocess.run(['systemctl', 'reload', 'nginx'])
                return {'success': True, 'message': f'Nginx configuration for {domain} created and loaded'}
            else:
                return {'success': False, 'error': f'Nginx configuration test failed: {test_result.stderr}'}
                
        except Exception as e:
            return {'success': False, 'error': f'Failed to setup nginx configuration: {str(e)}'}
    
    # Utility functions
    def check_dependencies(self) -> Dict:
        """Check system dependencies using helper script"""
        script_path = os.path.join(self.utils_helpers_dir, 'check_core_dependencies.sh')
        return self._run_helper_script(script_path)
    
    def update_system(self) -> Dict:
        """Update system using helper script"""
        script_path = os.path.join(self.utils_helpers_dir, 'update_system.sh')
        return self._run_helper_script(script_path)
    
    def get_platform_info(self) -> Dict:
        """Get platform information using helper script"""
        script_path = os.path.join(self.utils_helpers_dir, 'platform_steps.sh')
        return self._run_helper_script(script_path, ['get_platform_info'])

# Global instance for easy import
def get_helpers_integration(stack_root: Optional[str] = None) -> HelperScriptsIntegration:
    """Get or create helpers integration instance"""
    if stack_root is None:
        # Try to detect stack root from current location
        current_dir = os.path.dirname(os.path.abspath(__file__))
        stack_root = os.path.dirname(os.path.dirname(current_dir))
    
    return HelperScriptsIntegration(stack_root)
