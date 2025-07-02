#!/usr/bin/env python3
"""
test_python_apps.py - Part of LOMP Stack v3.0
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


from hosting_management import create_python_app, get_python_apps

# Create sample Python applications  
print('Creating Python applications...')

# Flask app
flask_result = create_python_app('example.com', 'api', 'flask', '3.11')
print('Flask app:', flask_result)

# Django app  
django_result = create_python_app('example.com', 'web', 'django', '3.11')
print('Django app:', django_result)

# FastAPI app
fastapi_result = create_python_app('example.com', 'fastapi', 'fastapi', '3.11')
print('FastAPI app:', fastapi_result)

# List all Python apps
print()
print('Python applications:')
apps = get_python_apps()
for app in apps:
    print(f'  - {app["full_domain"]} ({app["python_framework"]})')

print('Sample Python applications created!')
