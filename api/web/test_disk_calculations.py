#!/usr/bin/env python3
"""
Test script to verify disk usage progress bar calculations
"""

def test_disk_usage_calculations():
    """Test the disk usage calculations for progress bars"""
    
    test_cases = [
        {
            'name': 'Small site (100MB)',
            'disk_usage_bytes': 100 * 1024 * 1024,  # 100MB
            'disk_limit_mb': 1024,  # 1GB
            'expected_percentage': 9.8  # ~10%
        },
        {
            'name': 'Medium site (512MB)',
            'disk_usage_bytes': 512 * 1024 * 1024,  # 512MB
            'disk_limit_mb': 1024,  # 1GB
            'expected_percentage': 50.0
        },
        {
            'name': 'Large site (800MB)',
            'disk_usage_bytes': 800 * 1024 * 1024,  # 800MB
            'disk_limit_mb': 1024,  # 1GB
            'expected_percentage': 78.1  # ~78%
        },
        {
            'name': 'Over limit site (1.5GB)',
            'disk_usage_bytes': 1536 * 1024 * 1024,  # 1.5GB
            'disk_limit_mb': 1024,  # 1GB
            'expected_percentage': 100.0  # Capped at 100%
        },
        {
            'name': 'Custom limit site (1GB of 2GB)',
            'disk_usage_bytes': 1024 * 1024 * 1024,  # 1GB
            'disk_limit_mb': 2048,  # 2GB
            'expected_percentage': 50.0
        }
    ]
    
    print("🧪 Testing Disk Usage Progress Bar Calculations\n")
    
    for test_case in test_cases:
        # Calculate same way as template
        disk_usage_mb = test_case['disk_usage_bytes'] / 1024 / 1024
        max_disk_mb = test_case['disk_limit_mb']
        usage_percentage = (disk_usage_mb / max_disk_mb * 100) if disk_usage_mb else 0
        safe_percentage = min(usage_percentage, 100)
        
        # Determine color
        if safe_percentage > 90:
            color = 'bg-danger'
        elif safe_percentage > 75:
            color = 'bg-warning'
        else:
            color = 'bg-success'
        
        # Check if close to expected
        expected = test_case['expected_percentage']
        tolerance = 1.0  # 1% tolerance
        is_correct = abs(safe_percentage - expected) <= tolerance
        
        status = "✅" if is_correct else "❌"
        
        print(f"{status} {test_case['name']}")
        print(f"   Usage: {disk_usage_mb:.1f} MB / {max_disk_mb} MB")
        print(f"   Percentage: {safe_percentage:.1f}% (expected: {expected}%)")
        print(f"   Color: {color}")
        print(f"   Tooltip: {disk_usage_mb:.1f} MB / {max_disk_mb} MB ({safe_percentage:.1f}%)")
        print()
        
        if not is_correct:
            print(f"   ⚠️  Calculation mismatch! Got {safe_percentage:.1f}%, expected {expected}%")
            return False
    
    print("🎉 All disk usage calculations are correct!")
    return True

if __name__ == "__main__":
    success = test_disk_usage_calculations()
    exit(0 if success else 1)
