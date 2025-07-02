#!/usr/bin/env python3
"""
LOMP Stack v3.0 - Update System Test
Quick test to verify update system functionality
"""

import sys
import os

# Add the web directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from admin_dashboard import check_for_updates, get_update_status, UPDATE_CONFIG
    print("✅ Import successful")
except ImportError as e:
    print(f"❌ Import failed: {e}")
    sys.exit(1)

def test_update_config():
    """Test update configuration"""
    print("\n🔧 Testing Update Configuration:")
    print(f"  - Update check URL: {UPDATE_CONFIG['update_check_url']}")
    print(f"  - Current version: {UPDATE_CONFIG['current_version']}")
    print(f"  - Update script: {UPDATE_CONFIG['update_script']}")
    print(f"  - Script exists: {os.path.exists(UPDATE_CONFIG['update_script'])}")
    
    if not os.path.exists(UPDATE_CONFIG['update_script']):
        print(f"  ⚠️  Update script not found at: {UPDATE_CONFIG['update_script']}")
    else:
        print("  ✅ Update script found")

def test_update_check():
    """Test update checking functionality"""
    print("\n🔍 Testing Update Check:")
    try:
        status = get_update_status()
        print(f"  - Current cached status: {status}")
        
        print("  - Checking for updates...")
        update_info = check_for_updates()
        
        if update_info is None:
            print("  ❌ Update check returned None")
            return
            
        print(f"  - Update check result: {update_info}")
        
        if update_info.get('error'):
            print(f"  ⚠️  Update check error: {update_info['error']}")
        else:
            print("  ✅ Update check completed")
            
    except Exception as e:
        print(f"  ❌ Update check failed: {e}")

def test_dependencies():
    """Test required dependencies"""
    print("\n📦 Testing Dependencies:")
    
    required_modules = ['requests', 'flask', 'sqlite3', 'json', 'subprocess']
    
    for module in required_modules:
        try:
            __import__(module)
            print(f"  ✅ {module}")
        except ImportError:
            print(f"  ❌ {module} - missing")

if __name__ == "__main__":
    print("🧪 LOMP Stack v3.0 - Update System Test")
    print("=" * 50)
    
    test_dependencies()
    test_update_config()
    test_update_check()
    
    print("\n" + "=" * 50)
    print("🎉 Test completed")
