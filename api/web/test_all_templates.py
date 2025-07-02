#!/usr/bin/env python3
"""
Comprehensive test script to verify all template files in api/web/templates
"""

from jinja2 import Environment, FileSystemLoader, Template
import os
import glob

def test_all_templates():
    """Test all HTML templates for syntax errors and consistency"""
    
    template_dir = os.path.join(os.path.dirname(__file__), 'templates')
    
    # Get all HTML template files
    template_files = glob.glob(os.path.join(template_dir, '*.html'))
    
    print("🧪 Testing All Templates in api/web/templates\n")
    print(f"Found {len(template_files)} template files\n")
    
    errors = []
    successes = []
    
    # Test data for different templates
    test_data = {
        'sites': [
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
                'disk_limit_mb': None,
                'created_at': '2025-01-01 12:00:00'
            }
        ],
        'config': {
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
                'stats': {'enabled': True, 'rate_limit': 60, 'auth_required': True}
            }
        },
        'logs': ['[2025-01-01 12:00:00] [INFO] System started', '[2025-01-01 12:01:00] [ERROR] Test error'],
        'api_keys': [
            {
                'id': '1',
                'key': 'test_key_123',
                'name': 'Test Key',
                'created_by': 'admin',
                'permissions': ['read', 'write'],
                'active': True,
                'last_used': '2025-01-01'
            }
        ],
        'stats': {
            'cpu_usage': '45%',
            'memory_usage': '60%',
            'disk_usage': '30%'
        },
        'notifications': [],
        'update_status': {
            'update_available': False,
            'last_checked': '2025-01-01 12:00:00'
        },
        'update_config': {
            'auto_check_enabled': True,
            'notify_users': True,
            'check_interval_hours': 24
        },
        'domains': [],
        'services': [],
        'python_apps': [],
        'wp_sites': [],
        'available_domains': ['example.com', 'test.local'],
        'session': {'admin_id': 1, 'username': 'admin'},
        'request': type('obj', (object,), {'endpoint': 'test'})(),
        'get_flashed_messages': lambda with_categories=False: []
    }
    
    try:
        # Create Jinja2 environment
        env = Environment(loader=FileSystemLoader(template_dir))
        
        for template_file in template_files:
            template_name = os.path.basename(template_file)
            
            # Skip login.html as it doesn't extend base.html
            if template_name == 'login.html':
                print(f"⏭️  Skipping {template_name} (standalone template)")
                continue
                
            try:
                # Load and compile the template
                template = env.get_template(template_name)
                
                # Render the template
                rendered = template.render(**test_data)
                
                # Check for key features
                checks = []
                
                # Check for page_title block (should be in most templates)
                if template_name != 'base.html':
                    if 'page_title' in template.source:
                        checks.append("✅ page_title block")
                    else:
                        checks.append("⚠️  missing page_title block")
                
                # Check for notification system in JavaScript
                if 'showNotification' in rendered:
                    checks.append("✅ notification system")
                elif 'alert(' in rendered:
                    checks.append("⚠️  uses alert() instead of notifications")
                else:
                    checks.append("➖ no notifications needed")
                
                # Check for proper template structure
                if template_name != 'base.html':
                    if '{% extends "base.html" %}' in template.source:
                        checks.append("✅ extends base.html")
                    else:
                        checks.append("❌ doesn't extend base.html")
                
                print(f"✅ {template_name}")
                print(f"   📊 Rendered: {len(rendered):,} characters")
                print(f"   🔍 Checks: {', '.join(checks)}")
                print()
                
                successes.append(template_name)
                
            except Exception as e:
                error_msg = f"❌ {template_name}: {str(e)}"
                print(error_msg)
                print()
                errors.append(error_msg)
        
        # Summary
        print("="*60)
        print("📊 TEMPLATE VERIFICATION SUMMARY")
        print("="*60)
        print(f"✅ Successful: {len(successes)} templates")
        print(f"❌ Errors: {len(errors)} templates")
        print()
        
        if errors:
            print("❌ Templates with errors:")
            for error in errors:
                print(f"   {error}")
            print()
        
        if successes:
            print("✅ Successfully verified templates:")
            for template in successes:
                print(f"   {template}")
        
        return len(errors) == 0
        
    except Exception as e:
        print(f"❌ Environment setup error: {e}")
        return False

def check_template_consistency():
    """Check for consistency issues across templates"""
    
    template_dir = os.path.join(os.path.dirname(__file__), 'templates')
    template_files = glob.glob(os.path.join(template_dir, '*.html'))
    
    print("\n🔍 CHECKING TEMPLATE CONSISTENCY")
    print("="*40)
    
    issues = []
    
    for template_file in template_files:
        template_name = os.path.basename(template_file)
        
        if template_name in ['login.html', 'base.html']:
            continue
            
        with open(template_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Check for missing page_title block
        if '{% extends "base.html" %}' in content and '{% block page_title %}' not in content:
            issues.append(f"⚠️  {template_name}: Missing page_title block")
            
        # Check for alert() usage
        if 'alert(' in content:
            alert_count = content.count('alert(')
            issues.append(f"⚠️  {template_name}: Uses {alert_count} alert() calls")
            
        # Check for notification system
        if 'alert(' in content and 'showNotification' not in content:
            issues.append(f"⚠️  {template_name}: Has alert() but no notification system")
    
    if issues:
        print("Issues found:")
        for issue in issues:
            print(f"   {issue}")
    else:
        print("✅ All templates are consistent!")
    
    return len(issues) == 0

if __name__ == "__main__":
    print("🌐 LOMP Stack v3.0 - Template Verification Tool")
    print("=" * 50)
    
    # Test all templates
    templates_ok = test_all_templates()
    
    # Check consistency
    consistency_ok = check_template_consistency()
    
    # Final result
    print("\n" + "="*50)
    if templates_ok and consistency_ok:
        print("🎉 ALL TEMPLATES VERIFIED SUCCESSFULLY!")
        exit(0)
    else:
        print("❌ SOME ISSUES FOUND - Review output above")
        exit(1)
