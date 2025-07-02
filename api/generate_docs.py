#!/usr/bin/env python3
"""
generate_docs.py - Part of LOMP Stack v3.0
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


import json
from datetime import datetime

def generate_api_docs():
    """Generate API documentation in HTML format"""
    
    html_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LOMP Stack API Documentation</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .endpoint { background: #ecf0f1; margin: 10px 0; padding: 15px; border-radius: 5px; }
        .method { display: inline-block; padding: 5px 10px; border-radius: 3px; color: white; font-weight: bold; }
        .get { background: #27ae60; }
        .post { background: #3498db; }
        .delete { background: #e74c3c; }
        .put { background: #f39c12; }
        .code { background: #2c3e50; color: white; padding: 10px; border-radius: 3px; overflow-x: auto; }
        .example { background: #f8f9fa; padding: 10px; border-left: 4px solid #3498db; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 LOMP Stack API v1.0</h1>
        <p>Enterprise-grade REST API for WordPress LOMP Stack management</p>
        <p>Generated on: """ + datetime.now().strftime("%Y-%m-%d %H:%M:%S") + """</p>
    </div>
    
    <h2>🔐 Authentication</h2>
    <p>All API requests require authentication using an API key. Include the API key in the request header:</p>
    <div class="code">X-API-Key: your-api-key-here</div>
    
    <h2>📊 Rate Limiting</h2>
    <p>API requests are rate limited based on your API key. Default limits:</p>
    <ul>
        <li><strong>Admin keys:</strong> 1000 requests/minute</li>
        <li><strong>Monitoring keys:</strong> 500 requests/minute</li>
        <li><strong>Standard keys:</strong> 100 requests/minute</li>
    </ul>
    
    <h2>🌐 Endpoints</h2>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/health</h3>
        <p><strong>Description:</strong> Health check endpoint</p>
        <p><strong>Authentication:</strong> Not required</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "status": "healthy",
    "version": "1.0.0",
    "timestamp": "2025-07-01T10:30:00Z"
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/sites</h3>
        <p><strong>Description:</strong> List all WordPress sites</p>
        <p><strong>Authentication:</strong> Required (sites:read)</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "data": {
        "sites": [
            {"domain": "example.com"},
            {"domain": "test.com"}
        ]
    },
    "count": 2
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method post">POST</span> /api/v1/sites</h3>
        <p><strong>Description:</strong> Create a new WordPress site</p>
        <p><strong>Authentication:</strong> Required (sites:create)</p>
        <div class="example">
            <h4>Example Request:</h4>
            <div class="code">
{
    "domain": "newsite.com",
    "email": "admin@newsite.com"
}
            </div>
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "message": "Site newsite.com created successfully",
    "data": {
        "domain": "newsite.com",
        "email": "admin@newsite.com"
    }
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method delete">DELETE</span> /api/v1/sites/{domain}</h3>
        <p><strong>Description:</strong> Delete a WordPress site</p>
        <p><strong>Authentication:</strong> Required (sites:delete)</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "message": "Site example.com deleted successfully"
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/backups</h3>
        <p><strong>Description:</strong> List all backups</p>
        <p><strong>Authentication:</strong> Required (backups:read)</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "data": {
        "backups": [
            {"name": "backup_example_com_20250701.tar.gz"},
            {"name": "backup_test_com_20250630.tar.gz"}
        ]
    },
    "count": 2
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method post">POST</span> /api/v1/backups</h3>
        <p><strong>Description:</strong> Create a new backup</p>
        <p><strong>Authentication:</strong> Required (backups:create)</p>
        <div class="example">
            <h4>Example Request:</h4>
            <div class="code">
{
    "domain": "example.com",
    "type": "full"
}
            </div>
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "message": "Backup for example.com created successfully",
    "data": {
        "domain": "example.com",
        "type": "full"
    }
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/system/status</h3>
        <p><strong>Description:</strong> Get basic system status</p>
        <p><strong>Authentication:</strong> Not required</p>
        <p><strong>Rate Limit:</strong> 200/minute</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "data": {
        "status": "healthy",
        "timestamp": "2025-07-01T10:30:00Z",
        "system_info": "CPU: 25%, Memory: 60%, Disk: 45%"
    }
}
            </div>
        </div>
    </div>
    
    <div class="endpoint">
        <h3><span class="method get">GET</span> /api/v1/system/metrics</h3>
        <p><strong>Description:</strong> Get detailed system metrics</p>
        <p><strong>Authentication:</strong> Required (monitoring:read)</p>
        <div class="example">
            <h4>Example Response:</h4>
            <div class="code">
{
    "success": true,
    "data": {
        "metrics": "Detailed system metrics...",
        "timestamp": "2025-07-01T10:30:00Z"
    }
}
            </div>
        </div>
    </div>
    
    <h2>❌ Error Responses</h2>
    <div class="example">
        <h4>401 Unauthorized:</h4>
        <div class="code">{"error": "API key required"}</div>
        
        <h4>403 Forbidden:</h4>
        <div class="code">{"error": "Insufficient permissions"}</div>
        
        <h4>429 Too Many Requests:</h4>
        <div class="code">{"error": "Rate limit exceeded", "retry_after": "60"}</div>
        
        <h4>500 Internal Server Error:</h4>
        <div class="code">{"error": "Internal server error"}</div>
    </div>
    
    <h2>📝 API Key Permissions</h2>
    <ul>
        <li><strong>sites:read</strong> - View sites</li>
        <li><strong>sites:create</strong> - Create new sites</li>
        <li><strong>sites:delete</strong> - Delete sites</li>
        <li><strong>backups:read</strong> - View backups</li>
        <li><strong>backups:create</strong> - Create backups</li>
        <li><strong>monitoring:read</strong> - View monitoring data</li>
        <li><strong>*</strong> - All permissions (admin only)</li>
    </ul>
    
    <footer style="margin-top: 50px; padding-top: 20px; border-top: 1px solid #ccc; color: #666;">
        <p>LOMP Stack v2.0 - Enterprise API Documentation</p>
    </footer>
</body>
</html>
    """
    
    # Write documentation to file
    with open('api_documentation.html', 'w') as f:
        f.write(html_content)
    
    print("API documentation generated: api_documentation.html")

if __name__ == '__main__':
    generate_api_docs()
