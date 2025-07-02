#!/usr/bin/env python3
"""
test_enhanced_hosting.py - Part of LOMP Stack v3.0
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


"""
LOMP Stack v3.0 - Enhanced Hosting Control Panel Startup Test
Test all components of the enhanced hosting control panel
"""

import os
import sys
import sqlite3
from datetime import datetime

def test_imports():
    """Test all module imports"""
    print("=== Testing Module Imports ===")
    
    try:
        import admin_dashboard
        print("✓ admin_dashboard imported successfully")
    except Exception as e:
        print(f"✗ admin_dashboard import failed: {e}")
        return False
    
    try:
        import hosting_management
        print("✓ hosting_management imported successfully")
    except Exception as e:
        print(f"✗ hosting_management import failed: {e}")
        return False
    
    try:
        import helpers_integration
        print("✓ helpers_integration imported successfully")
    except Exception as e:
        print(f"✗ helpers_integration import failed: {e}")
        return False
    
    try:
        import python_app_enhancements
        print("✓ python_app_enhancements imported successfully")
    except Exception as e:
        print(f"✗ python_app_enhancements import failed: {e}")
        return False
    
    return True

def test_database_connection():
    """Test database connections"""
    print("\n=== Testing Database Connections ===")
    
    db_files = ['sites.db', 'domains.db', 'services.db']
    
    for db_file in db_files:
        try:
            conn = sqlite3.connect(db_file)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = cursor.fetchall()
            conn.close()
            print(f"✓ {db_file} connected successfully ({len(tables)} tables)")
        except Exception as e:
            print(f"✗ {db_file} connection failed: {e}")
            return False
    
    return True

def test_helpers_integration():
    """Test helpers integration"""
    print("\n=== Testing Helpers Integration ===")
    
    try:
        from helpers_integration import get_helpers_integration
        
        # Get current directory (Stack root should be 2 levels up)
        current_dir = os.path.dirname(os.path.abspath(__file__))
        stack_root = os.path.dirname(os.path.dirname(current_dir))
        
        helpers = get_helpers_integration(stack_root)
        print(f"✓ Helpers integration initialized")
        print(f"  Stack root: {stack_root}")
        print(f"  Helpers dir: {helpers.helpers_dir}")
        
        # Check if helpers directories exist
        if os.path.exists(helpers.helpers_dir):
            print(f"✓ Helpers directory exists")
            
            subdirs = ['web', 'wp', 'security', 'utils', 'monitoring']
            for subdir in subdirs:
                path = os.path.join(helpers.helpers_dir, subdir)
                if os.path.exists(path):
                    print(f"  ✓ {subdir}/ directory found")
                else:
                    print(f"  ⚠ {subdir}/ directory missing")
        else:
            print(f"⚠ Helpers directory not found: {helpers.helpers_dir}")
        
        return True
        
    except Exception as e:
        print(f"✗ Helpers integration test failed: {e}")
        return False

def test_python_app_functionality():
    """Test Python application functionality"""
    print("\n=== Testing Python App Functionality ===")
    
    try:
        from hosting_management import get_python_apps, create_python_app
        
        # Test getting Python apps
        apps = get_python_apps()
        print(f"✓ Retrieved {len(apps)} Python applications")
        
        for app in apps[:3]:  # Show first 3 apps
            print(f"  - {app.get('domain', 'N/A')} ({app.get('python_framework', 'N/A')})")
        
        return True
        
    except Exception as e:
        print(f"✗ Python app functionality test failed: {e}")
        return False

def test_api_endpoints():
    """Test API endpoint availability"""
    print("\n=== Testing API Endpoint Registration ===")
    
    try:
        from admin_dashboard import app
        
        # Get all registered routes
        routes = []
        for rule in app.url_map.iter_rules():
            routes.append(f"{rule.methods} {rule.rule}")
        
        # Check for hosting-related routes
        hosting_routes = [r for r in routes if any(keyword in r.lower() for keyword in 
                         ['hosting', 'python', 'sites', 'domains', 'services'])]
        
        print(f"✓ {len(hosting_routes)} hosting-related API endpoints found:")
        for route in hosting_routes[:10]:  # Show first 10
            print(f"  {route}")
        
        if len(hosting_routes) > 10:
            print(f"  ... and {len(hosting_routes) - 10} more")
        
        return True
        
    except Exception as e:
        print(f"✗ API endpoint test failed: {e}")
        return False

def test_template_files():
    """Test template file availability"""
    print("\n=== Testing Template Files ===")
    
    template_dir = os.path.join(os.path.dirname(__file__), 'templates')
    required_templates = [
        'base.html',
        'hosting.html',
        'services.html',
        'sites.html',
        'domains.html',
        'wordpress.html',
        'python_apps.html'
    ]
    
    missing_templates = []
    for template in required_templates:
        template_path = os.path.join(template_dir, template)
        if os.path.exists(template_path):
            print(f"✓ {template} found")
        else:
            print(f"✗ {template} missing")
            missing_templates.append(template)
    
    return len(missing_templates) == 0

def create_sample_data():
    """Create sample data for testing"""
    print("\n=== Creating Sample Data ===")
    
    try:
        from hosting_management import init_hosting_databases
        
        # Initialize databases
        init_hosting_databases()
        print("✓ Databases initialized")
        
        # Add sample Python app if not exists
        conn = sqlite3.connect('sites.db')
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM sites WHERE site_type = 'python'")
        python_apps_count = cursor.fetchone()[0]
        
        if python_apps_count == 0:
            cursor.execute('''
                INSERT INTO sites 
                (domain, site_type, python_framework, python_version, python_port, status)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', ('demo.local', 'python', 'flask', '3.11', 8000, 'active'))
            
            print("✓ Sample Python app created: demo.local (Flask)")
        else:
            print(f"✓ {python_apps_count} Python applications already exist")
        
        conn.commit()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"✗ Sample data creation failed: {e}")
        return False

def main():
    """Run all tests"""
    print("LOMP Stack v3.0 - Enhanced Hosting Control Panel Test")
    print("=" * 60)
    print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Python version: {sys.version}")
    print(f"Working directory: {os.getcwd()}")
    
    tests = [
        ("Module Imports", test_imports),
        ("Database Connections", test_database_connection),
        ("Helpers Integration", test_helpers_integration),
        ("Python App Functionality", test_python_app_functionality),
        ("API Endpoints", test_api_endpoints),
        ("Template Files", test_template_files),
        ("Sample Data", create_sample_data)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            if result:
                passed += 1
        except Exception as e:
            print(f"\n✗ {test_name} test crashed: {e}")
    
    print("\n" + "=" * 60)
    print(f"TEST SUMMARY: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Enhanced Hosting Control Panel is ready!")
        print("\nNext steps:")
        print("1. Start the dashboard: python admin_dashboard.py")
        print("2. Open browser: http://localhost:5000")
        print("3. Login with your admin credentials")
        print("4. Navigate to Python Apps section")
    else:
        print("⚠️  Some tests failed. Please check the output above.")
    
    print(f"\nTest completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
