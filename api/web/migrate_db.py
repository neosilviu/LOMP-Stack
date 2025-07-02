#!/usr/bin/env python3
"""
migrate_db.py - Part of LOMP Stack v3.0
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


import sqlite3

# Add missing columns to existing table
conn = sqlite3.connect('sites.db')
cursor = conn.cursor()

# Add new columns for Python support
columns_to_add = [
    ('site_type', 'TEXT DEFAULT "php"'),
    ('python_version', 'TEXT DEFAULT "3.11"'),
    ('python_framework', 'TEXT'),
    ('python_venv_path', 'TEXT'),
    ('python_wsgi_file', 'TEXT'),
    ('python_requirements_file', 'TEXT'),
    ('python_port', 'INTEGER')
]

for col_name, col_def in columns_to_add:
    try:
        sql = f'ALTER TABLE sites ADD COLUMN {col_name} {col_def}'
        cursor.execute(sql)
        print(f'Added {col_name} column')
    except Exception as e:
        print(f'{col_name} column error: {e}')

conn.commit()
conn.close()

print('Database migration completed!')
