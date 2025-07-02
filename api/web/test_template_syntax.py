#!/usr/bin/env python3
"""
Test script to verify Jinja2 template syntax for sites.html
"""

from jinja2 import Environment, FileSystemLoader, Template
import os

def test_sites_template():
    """Test the sites.html template for syntax errors"""
    
    template_dir = os.path.join(os.path.dirname(__file__), 'templates')
    
    try:
        # Create Jinja2 environment
        env = Environment(loader=FileSystemLoader(template_dir))
        
        # Load and compile the template
        template = env.get_template('sites.html')
        
        # Test data
        test_sites = [
            {
                'id': '1',
                'full_domain': 'example.com',
                'document_root': '/var/www/example.com',
                'web_server': 'ols',
                'php_version': '8.1',
                'wp_installed': True,
                'wp_version': '6.4',
                'ssl_enabled': True,
                'status': 'active',
                'disk_usage': 524288000,  # 500MB in bytes
                'disk_limit_mb': None,    # Will use default
                'created_at': '2025-01-01 12:00:00'
            },
            {
                'id': '2',
                'full_domain': 'test.local',
                'document_root': '/var/www/test.local',
                'web_server': 'nginx',
                'php_version': '8.2',
                'wp_installed': False,
                'wp_version': None,
                'ssl_enabled': False,
                'status': 'inactive',
                'disk_usage': 1073741824,  # 1GB in bytes
                'disk_limit_mb': 2048,     # 2GB custom limit
                'created_at': '2025-01-02 14:30:00'
            }
        ]
        
        # Render the template
        rendered = template.render(
            sites=test_sites,
            session={'admin_id': 1, 'username': 'admin'},
            request=type('obj', (object,), {'endpoint': 'sites'})(),
            get_flashed_messages=lambda with_categories=False: []
        )
        
        print("✅ Template syntax is valid!")
        print(f"✅ Rendered template length: {len(rendered)} characters")
        
        # Check for key elements in rendered output
        if 'progress-bar' in rendered:
            print("✅ Progress bar elements found in rendered output")
        
        if 'bg-success' in rendered or 'bg-warning' in rendered or 'bg-danger' in rendered:
            print("✅ Color coding classes found in rendered output")
            
        if 'MB /' in rendered:
            print("✅ Disk usage tooltip format found in rendered output")
            
        return True
        
    except Exception as e:
        print(f"❌ Template syntax error: {e}")
        return False

if __name__ == "__main__":
    success = test_sites_template()
    exit(0 if success else 1)
