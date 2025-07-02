# LOMP Stack v3.0 - Enhanced Hosting Control Panel Guide

## Overview

The LOMP Stack v3.0 has been extended from a simple API dashboard into a comprehensive hosting control panel, similar to cPanel, with advanced support for managing web services, domains, WordPress installations, and Python web applications (Flask, Django, FastAPI).

## New Features Summary

### 🚀 Core Hosting Features
- **Multi-Site Management**: Create and manage multiple websites with different technologies
- **Domain Management**: Configure domains, subdomains, DNS settings
- **Service Management**: Control system services (Redis, OLS, Apache, Nginx, etc.)
- **WordPress Integration**: One-click WordPress installation and management
- **Python Applications**: Full lifecycle management for Python web apps

### 🐍 Advanced Python Application Support
- **Framework Support**: Flask, Django, FastAPI, and generic Python apps
- **Git Integration**: Deploy directly from Git repositories with auto-deploy
- **Environment Management**: Visual editor for environment variables
- **Dependency Management**: Install/uninstall Python packages with GUI
- **Database Integration**: Automatic PostgreSQL/MySQL database setup
- **SSL Certificates**: One-click SSL certificate installation
- **Performance Monitoring**: Real-time app performance metrics
- **Systemd Integration**: Automatic service creation and management

### 🔧 Helper Scripts Integration
- **Unified Interface**: All existing bash helpers accessible through Python API
- **Error Handling**: Comprehensive error reporting and logging
- **Cross-Platform**: Windows development with Linux deployment support

## Architecture

### Database Schema Extensions

The hosting control panel uses extended SQLite databases:

#### Sites Table
```sql
CREATE TABLE sites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain TEXT UNIQUE NOT NULL,
    subdomain TEXT,
    document_root TEXT NOT NULL,
    site_type TEXT DEFAULT 'php',
    php_version TEXT DEFAULT '8.1',
    python_version TEXT DEFAULT '3.11',
    python_framework TEXT,
    python_venv_path TEXT,
    python_wsgi_file TEXT,
    python_requirements_file TEXT,
    python_port INTEGER,
    web_server TEXT DEFAULT 'ols',
    ssl_enabled BOOLEAN DEFAULT 0,
    ssl_cert_path TEXT,
    wp_installed BOOLEAN DEFAULT 0,
    wp_version TEXT,
    wp_admin_user TEXT,
    wp_admin_email TEXT,
    disk_usage INTEGER DEFAULT 0,
    bandwidth_used INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### File Structure

```
api/web/
├── admin_dashboard.py          # Main Flask application
├── hosting_management.py       # Hosting control panel backend
├── helpers_integration.py      # Bridge to bash helper scripts
├── python_app_enhancements.py  # Advanced Python app features
├── sites.db                    # Sites database
├── domains.db                  # Domains database
├── services.db                 # Services database
└── templates/
    ├── base.html              # Base template
    ├── hosting.html           # Main hosting overview
    ├── services.html          # Services management
    ├── sites.html             # Sites management
    ├── domains.html           # Domain management
    ├── wordpress.html         # WordPress management
    └── python_apps.html       # Python applications
```

## Python Applications Management

### Creating Python Applications

#### Basic Creation
```python
# Create a new Flask application
result = create_python_app(
    domain="example.com",
    subdomain="api",
    framework="flask",
    python_version="3.11"
)
```

#### Git Repository Deployment
```python
# Deploy from Git repository
result = create_python_app(
    domain="example.com",
    subdomain="app",
    framework="django",
    python_version="3.11",
    git_repo="https://github.com/user/repo.git"
)
```

### Environment Variables Management

The control panel provides a visual editor for environment variables:

```bash
# Example .env file structure
DATABASE_URL=postgresql://user:password@localhost/dbname
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,your-domain.com
REDIS_URL=redis://localhost:6379/0
```

### Dependency Management

#### Installing Packages
```python
# Install specific packages
install_python_dependencies(site_id, [
    "django>=4.0",
    "psycopg2-binary",
    "redis",
    "celery"
])
```

#### Requirements Management
- Automatic `requirements.txt` generation
- Package version tracking
- One-click updates

### Database Integration

#### Automatic Database Creation
```python
# Setup PostgreSQL database
setup_python_database(
    site_id=1,
    db_type="postgresql",
    db_name="myapp_db"
)
```

#### Supported Database Types
- **PostgreSQL**: Recommended for Django applications
- **MySQL**: Compatible with most Python frameworks
- **SQLite**: For development and small applications

### Systemd Service Management

The control panel automatically creates systemd services:

```ini
[Unit]
Description=My Python App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/example.com
Environment=PATH=/var/www/example.com/venv/bin
ExecStart=/var/www/example.com/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Nginx Configuration

Automatic reverse proxy setup:

```nginx
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static {
        alias /var/www/example.com/static;
        expires 30d;
    }
}
```

## API Endpoints

### Python Applications API

#### Deploy from Git
```http
POST /api/python-apps/deploy-from-git
Content-Type: application/json

{
    "domain": "example.com",
    "subdomain": "api",
    "framework": "flask",
    "git_repo": "https://github.com/user/repo.git",
    "git_branch": "main",
    "python_version": "3.11"
}
```

#### Environment Variables
```http
GET /api/python-apps/{site_id}/environment
POST /api/python-apps/{site_id}/environment
Content-Type: application/json

{
    "environment": {
        "DEBUG": "False",
        "DATABASE_URL": "postgresql://..."
    }
}
```

#### Dependencies
```http
GET /api/python-apps/{site_id}/dependencies
POST /api/python-apps/{site_id}/dependencies
Content-Type: application/json

{
    "packages": ["django>=4.0", "psycopg2-binary"]
}
```

#### Performance Metrics
```http
GET /api/python-apps/{site_id}/performance

Response:
{
    "success": true,
    "metrics": {
        "cpu_usage": 15.2,
        "memory_usage": 8.5,
        "status": "active",
        "uptime": "2 days, 3 hours"
    }
}
```

#### Database Management
```http
POST /api/python-apps/{site_id}/database
Content-Type: application/json

{
    "db_type": "postgresql",
    "db_name": "myapp_db"
}
```

#### SSL Certificates
```http
POST /api/python-apps/{site_id}/ssl
Content-Type: application/json

{
    "email": "admin@example.com"
}
```

## Helper Scripts Integration

### Available Integrations

#### Web Server Management
```python
from helpers_integration import get_helpers_integration

helpers = get_helpers_integration()

# Create virtual hosts
helpers.create_nginx_vhost("example.com", "/var/www/example.com", "8.1")
helpers.create_apache_vhost("example.com", "/var/www/example.com", "8.1")
helpers.create_ols_vhost("example.com", "/var/www/example.com", "8.1")

# Restart services
helpers.restart_web_server("nginx")
helpers.reload_web_server("nginx")
```

#### WordPress Management
```python
# Install WordPress
helpers.install_wordpress(
    domain="blog.example.com",
    db_name="wp_blog",
    db_user="wp_user",
    db_pass="secure_password",
    wp_admin_user="admin",
    wp_admin_pass="admin_password",
    wp_admin_email="admin@example.com"
)

# Backup WordPress
helpers.backup_wordpress("blog.example.com", "/backups/wp_backup.tar.gz")
```

#### Security Management
```python
# Setup firewall
helpers.setup_firewall(["80", "443", "22", "7080"])

# Install SSL certificate
helpers.install_ssl_certificate("example.com", "admin@example.com")

# Setup Redis
helpers.setup_redis()

# Configure Cloudflare
helpers.configure_cloudflare("example.com", "api_token")
```

#### Monitoring and System
```python
# Install monitoring
helpers.install_monitoring()

# Get system status
status = helpers.get_system_status()

# Restart multiple services
helpers.restart_services(["nginx", "mariadb", "redis"])

# Show stack URLs
helpers.show_stack_urls()
```

#### Database Management
```python
# Create database
helpers.create_database("myapp_db", "myuser", "mypassword", "postgresql")

# Backup database
helpers.backup_database("myapp_db", "/backups/db_backup.sql", "postgresql")
```

## Frontend Features

### Modern UI Components

#### Dashboard Cards
- Real-time statistics
- Service status indicators
- Quick action buttons
- Responsive design

#### Data Tables
- Sortable columns
- Search functionality
- Bulk actions
- Pagination

#### Modal Dialogs
- Form validation
- AJAX submissions
- Progress indicators
- Error handling

### Interactive Features

#### Python Apps Management
- **Deploy from Git**: Clone repositories with one click
- **Environment Editor**: Visual .env file editor
- **Dependency Manager**: Install/uninstall packages
- **Performance Monitor**: Real-time metrics
- **Database Setup**: Automatic database configuration
- **SSL Management**: One-click SSL certificate installation

#### Bulk Operations
- Start/stop/restart multiple applications
- Bulk SSL certificate installation
- Mass dependency updates
- Batch backup operations

## Security Features

### Authentication & Authorization
- Session-based authentication
- Role-based access control (planned)
- CSRF protection (planned)
- Rate limiting

### Application Security
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- Secure file uploads

### System Security
- Firewall integration
- SSL/TLS certificate management
- Fail2ban integration
- Regular security updates

## Performance Optimization

### Caching
- Redis integration
- Static file optimization
- Database query optimization
- CDN support (Cloudflare)

### Monitoring
- Real-time performance metrics
- Resource usage tracking
- Error logging and reporting
- Health checks

## Deployment Guide

### Prerequisites
```bash
# Required packages
python3-pip
python3-venv
nginx
redis-server
postgresql (optional)
mysql-server (optional)
```

### Installation Steps

1. **Clone and Setup**
```bash
cd /path/to/lomp-stack
cp api/web/admin_dashboard.py.example api/web/admin_dashboard.py
```

2. **Install Python Dependencies**
```bash
cd api/web
pip3 install flask flask-limiter
```

3. **Initialize Databases**
```bash
python3 admin_dashboard.py --init-db
```

4. **Configure Web Server**
```bash
# Copy nginx configuration
sudo cp configs/nginx/admin_dashboard.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/admin_dashboard.conf /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

5. **Start Services**
```bash
# Start the dashboard
python3 admin_dashboard.py

# Or use systemd (production)
sudo systemctl enable lomp-dashboard
sudo systemctl start lomp-dashboard
```

### Production Configuration

#### Systemd Service
```ini
[Unit]
Description=LOMP Stack Dashboard
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/lomp-stack/api/web
ExecStart=/usr/bin/python3 admin_dashboard.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### Nginx Configuration
```nginx
server {
    listen 80;
    server_name dashboard.yourdomain.com;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static {
        alias /path/to/lomp-stack/api/web/static;
        expires 30d;
    }
}
```

## Troubleshooting

### Common Issues

#### Python App Won't Start
1. Check virtual environment
2. Verify dependencies
3. Check environment variables
4. Review application logs
5. Verify port availability

#### Database Connection Issues
1. Verify database service is running
2. Check connection credentials
3. Verify database exists
4. Check firewall settings

#### SSL Certificate Problems
1. Verify domain DNS settings
2. Check Cloudflare settings
3. Verify port 80/443 accessibility
4. Check Let's Encrypt rate limits

### Log Files
```bash
# Application logs
tail -f /var/log/lomp-dashboard.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Python app logs
journalctl -u myapp.service -f

# System logs
journalctl -xe
```

## Future Enhancements

### Planned Features
- **Multi-tenant Support**: User isolation and resource limits
- **Backup Automation**: Scheduled backups with retention policies
- **CDN Integration**: Advanced Cloudflare integration
- **Container Support**: Docker and container orchestration
- **Monitoring Dashboard**: Advanced metrics and alerting
- **API Rate Limiting**: Per-app rate limiting configuration
- **Custom Domains**: Advanced domain management
- **SSL Automation**: Automatic renewal and management

### Integration Roadmap
- **CI/CD Pipelines**: GitHub Actions integration
- **Database Replication**: Master-slave database setup
- **Load Balancing**: Multi-server deployment support
- **Message Queues**: Celery and RabbitMQ integration
- **File Storage**: S3-compatible storage integration

## Contributing

### Development Setup
```bash
# Clone repository
git clone https://github.com/your-org/lomp-stack.git
cd lomp-stack

# Setup development environment
python3 -m venv venv
source venv/bin/activate
pip install -r api/web/requirements.txt

# Run in development mode
cd api/web
python admin_dashboard.py --debug
```

### Testing
```bash
# Run unit tests
python -m pytest tests/

# Run integration tests
python tests/test_hosting_integration.py

# Test helper scripts
bash tests/test_helpers.sh
```

This enhanced hosting control panel transforms the LOMP Stack v3.0 into a powerful, modern web hosting management platform comparable to industry-standard control panels like cPanel, with additional advanced features for Python application deployment and management.
