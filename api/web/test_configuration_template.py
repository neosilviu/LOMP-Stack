#!/usr/bin/env python3
"""
Test script to verify Jinja2 template syntax for configuration.html
"""

from jinja2 import Environment, FileSystemLoader, Template
import os

def test_configuration_template():
    """Test the configuration.html template for syntax errors"""
    
    template_dir = os.path.join(os.path.dirname(__file__), 'templates')
    
    try:
        # Create Jinja2 environment
        env = Environment(loader=FileSystemLoader(template_dir))
        
        # Load and compile the template
        template = env.get_template('configuration.html')
        
        # Test data
        test_config = {
            'api': {
                'host': 'localhost',
                'port': 8080,
                'base_path': '/api/v1',
                'version': '1.0.0',
                'ssl_enabled': True,
                'cors_enabled': True,
                'rate_limiting': {
                    'enabled': True,
                    'requests_per_minute': 100,
                    'burst_limit': 20
                },
                'authentication': {
                    'jwt_enabled': True,
                    'api_key_enabled': True,
                    'session_timeout': 3600
                },
                'logging': {
                    'level': 'info',
                    'access_log': True,
                    'error_log': True
                }
            },
            'endpoints': {
                'stats': {
                    'enabled': True,
                    'rate_limit': 60,
                    'auth_required': True
                },
                'config': {
                    'enabled': True,
                    'rate_limit': 30,
                    'auth_required': True
                }
            }
        }
        
        # Render the template
        rendered = template.render(
            config=test_config,
            session={'admin_id': 1, 'username': 'admin'},
            request=type('obj', (object,), {'endpoint': 'configuration'})(),
            get_flashed_messages=lambda with_categories=False: []
        )
        
        print("✅ Template syntax is valid!")
        print(f"✅ Rendered template length: {len(rendered)} characters")
        
        # Check for key elements in rendered output
        if 'showNotification' in rendered:
            print("✅ Notification system found in rendered output")
        
        if 'Configuration' in rendered:
            print("✅ Configuration content found in rendered output")
            
        if 'downloadConfig' in rendered:
            print("✅ Download function found in rendered output")
            
        return True
        
    except Exception as e:
        print(f"❌ Template syntax error: {e}")
        return False

if __name__ == "__main__":
    success = test_configuration_template()
    exit(0 if success else 1)
