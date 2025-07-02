# LOMP Stack v3.0 - Hosting Control Panel Documentation

## Overview
Ai mărit cu succes interfața API Dashboard într-un control panel complet de hosting, similar cu cPanel, care permite gestionarea serviciilor, domeniilor și site-urilor WordPress.

## Funcționalități Implementate

### 🏠 Dashboard Principal de Hosting (`/hosting`)
- Prezentare generală a tuturor serviciilor și statistici
- Monitorizarea stării serviciilor (OpenLiteSpeed, Redis, MySQL, etc.)
- Grafice și statistici în timp real

### ⚙️ Gestionarea Serviciilor (`/services`)
- **Servicii Suportate:**
  - OpenLiteSpeed (OLS) - Web Server
  - Nginx - Web Server  
  - Apache2 - Web Server
  - MySQL/MariaDB - Database
  - Redis - Cache
  - Memcached - Cache
  - PHP-FPM (8.1, 8.2) - PHP Processing
  - Certbot - SSL Management

- **Acțiuni Disponibile:**
  - Start/Stop/Restart/Reload servicii
  - Vizualizarea configurației serviciilor
  - Monitorizarea utilizării memoriei și CPU
  - Vizualizarea log-urilor serviciilor

### 🌐 Gestionarea Domeniilor (`/domains`)
- **Adăugarea de domenii noi**
- **Tipuri de domenii:**
  - Primary Domain (domeniu principal)
  - Subdomain 
  - Addon Domain (domeniu suplimentar)

- **Funcționalități:**
  - Configurarea nameserver-elor
  - Integrare Cloudflare
  - Monitorizarea expirării domeniilor
  - Gestionarea înregistrărilor DNS
  - Managementul certificatelor SSL
  - Acțiuni în masă (bulk actions)

### 📱 Gestionarea Site-urilor (`/sites`)
- **Crearea de site-uri noi**
- **Configurări web server:**
  - OpenLiteSpeed (OLS)
  - Nginx
  - Apache2

- **Versiuni PHP suportate:**
  - PHP 8.1
  - PHP 8.2

- **Funcționalități:**
  - SSL automatic cu Let's Encrypt
  - Configurare automată vhost
  - Monitorizarea stării site-urilor

### 🔌 Gestionarea WordPress (`/wordpress`)
- **Instalare WordPress cu un click**
- **Configurări disponibile:**
  - Selectarea domeniului
  - Instalare în subdirector
  - Configurarea contului admin
  - Activarea SSL automată
  - Integrare Cloudflare

- **Management site-uri WordPress:**
  - Actualizări WordPress
  - Gestionarea plugin-urilor și temelor
  - Mod mentenantă
  - Backup-uri automate
  - Vizualizarea log-urilor

### 🐍 Gestionarea Aplicațiilor Python (`/python-apps`)
- **Deployment Python applications cu un click**
- **Framework-uri suportate:**
  - Flask - Micro web framework
  - Django - Full-featured web framework
  - FastAPI - Modern, high-performance API framework
  - Pyramid - Flexible web framework
  - Custom - Aplicații Python personalizate

- **Funcționalități Python:**
  - Virtual environments automate (venv)
  - Package management (pip, requirements.txt)
  - WSGI/ASGI server configuration (Gunicorn, Uvicorn)
  - Systemd service management
  - Environment variables și configurări
  - Git repository integration
  - Database setup (PostgreSQL)
  - Static files serving
  - Auto-deploy din Git

- **Management aplicații Python:**
  - Start/Stop/Restart aplicații
  - Dependency management
  - Log monitoring în timp real
  - Performance monitoring
  - Environment variables editor
  - Database migrations (Django)
  - Health checks
  - SSL automatic cu Let's Encrypt

## Structura Bazelor de Date

### Sites Database (`sites.db`)
```sql
CREATE TABLE sites (
    id INTEGER PRIMARY KEY,
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
    wp_installed BOOLEAN DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP
);
```

### Domains Database (`domains.db`)
```sql
CREATE TABLE domains (
    id INTEGER PRIMARY KEY,
    domain_name TEXT UNIQUE NOT NULL,
    domain_type TEXT DEFAULT 'primary',
    nameservers TEXT,
    registrar TEXT,
    expiry_date DATE,
    auto_renew BOOLEAN DEFAULT 1,
    cloudflare_enabled BOOLEAN DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP
);
```

### Services Database (`services.db`)
```sql
CREATE TABLE services (
    id INTEGER PRIMARY KEY,
    service_name TEXT UNIQUE NOT NULL,
    service_type TEXT NOT NULL,
    status TEXT DEFAULT 'stopped',
    port INTEGER,
    config_path TEXT,
    log_path TEXT,
    memory_usage INTEGER,
    cpu_usage REAL,
    uptime INTEGER,
    last_restart TIMESTAMP
);
```

## API Endpoints

### Domain Management
- `POST /api/domains` - Adăugare domeniu nou
- `GET /api/domains/{id}` - Detalii domeniu
- `PUT /api/domains/{id}` - Actualizare domeniu
- `DELETE /api/domains/{id}` - Ștergere domeniu
- `GET /api/domains/{id}/dns` - Gestionare DNS
- `GET /api/domains/{id}/ssl` - Informații SSL
- `POST /api/domains/bulk/cloudflare` - Activare Cloudflare în masă
- `POST /api/domains/bulk/renew-ssl` - Reînnoire SSL în masă

### Python Application Management  
- `POST /api/python/deploy` - Deploy aplicație Python nouă
- `GET /api/python/{id}` - Detalii aplicație Python
- `POST /api/python/{id}/action` - Acțiuni aplicație (start/stop/restart)
- `GET /api/python/{id}/logs` - Log-urile aplicației
- `POST /api/python/{id}/deploy` - Deploy/update code
- `POST /api/python/{id}/migrate` - Database migrations
- `POST /api/python/health-check` - Health check pentru toate aplicațiile
- `POST /api/python/bulk/{action}` - Acțiuni în masă pentru aplicații Python

### WordPress Management  
- `POST /api/wordpress/install` - Instalare WordPress
- `GET /api/wordpress/{id}` - Detalii site WordPress
- `DELETE /api/wordpress/{id}` - Ștergere site WordPress
- `POST /api/wordpress/{id}/backup` - Backup site
- `POST /api/wordpress/{id}/update` - Actualizare WordPress
- `POST /api/wordpress/{id}/maintenance` - Mod mentenantă
- `POST /api/wordpress/bulk/update` - Actualizări în masă
- `POST /api/wordpress/bulk/backup` - Backup-uri în masă

### Service Management
- `GET /api/services` - Lista servicii
- `POST /api/services/{name}/action` - Acțiuni servicii (start/stop/restart)
- `GET /api/services/{name}/config` - Configurația serviciului
- `GET /api/services/{name}/logs` - Log-urile serviciului

## Integrări cu Helper Scripts

### Web Helpers (`/helpers/web/`)
- `ols_helpers.sh` - OpenLiteSpeed management
- `nginx_helpers.sh` - Nginx configuration
- `apache_helpers.sh` - Apache management
- `php_helpers.sh` - PHP version management
- `ssl_helpers.sh` - SSL certificate management

### WordPress Helpers (`/helpers/wp/`)
- `wp_helpers.sh` - WordPress installation
- `wpcli_helpers.sh` - WP-CLI integration

### Security Helpers (`/helpers/security/`)
- `cloudflare_helpers.sh` - Cloudflare integration
- `redis_config_helper.sh` - Redis configuration
- `ssl_helpers.sh` - Let's Encrypt automation

## Utilizare

### 1. Accesarea Control Panel-ului
```bash
cd /path/to/stack/api/web
python admin_dashboard.py
```

Apoi deschide: `http://localhost:5000`
- Username: `admin`
- Password: `admin123`

### 2. Adăugarea unui Domeniu Nou
1. Navighează la "Hosting Management" → "Domains"
2. Click "Add Domain"
3. Completează informațiile domeniului
4. Activează Cloudflare dacă e necesar

### 3. Crearea unui Site Nou
1. Mergi la "Sites"
2. Click "Create Site"
3. Selectează domeniul
4. Configurează web server-ul și versiunea PHP
5. Activează SSL

### 4. Instalarea WordPress
1. Navighează la "WordPress"
2. Completează formularul de instalare
3. Selectează domeniul și configurările
4. Click "Install WordPress"

### 5. Deployarea unei Aplicații Python
1. Navighează la "Hosting Management" → "Python Apps"
2. Completează formularul de deployment:
   - Selectează domeniul
   - Alege framework-ul (Flask, Django, FastAPI, etc.)
   - Configurează versiunea Python
   - Adaugă repository Git (opțional)
3. Activează SSL și alte opțiuni
4. Click "Deploy Python App"

### 6. Gestionarea Serviciilor
1. Mergi la "Services"
2. Vezi starea tuturor serviciilor
3. Start/Stop/Restart servicii după necesitate
4. Vizualizează log-urile și configurațiile

## Funcționalități Avansate

### Bulk Actions (Acțiuni în Masă)
- Activarea Cloudflare pentru multiple domenii
- Reînnoirea SSL pentru multiple site-uri
- Backup-uri pentru multiple site-uri WordPress
- Actualizări WordPress în masă

### Monitoring și Alerting
- Monitorizarea utilizării resurselor
- Alerte pentru domenii care expiră
- Notificări pentru actualizări WordPress disponibile
- Log monitoring în timp real

### Security Features
- Protecție CSRF pentru toate formularele
- Rate limiting pentru API-uri
- Validarea input-urilor
- Sesiuni securizate

## Demo Data
Pentru testare, au fost adăugate date exemplu:
- **Domenii**: example.com, test.com, demo.ro
- **Site-uri PHP**: example.com cu WordPress, test.com/blog
- **Aplicații Python**: 
  - flask-demo.com (Flask application pe portul 8xxx)
  - django-demo.com (Django application pe portul 8xxx)
  - fastapi-demo.com (FastAPI application pe portul 8xxx)
- **Servicii configurate**: OLS, Redis, MySQL, PHP-FPM

## Următorii Pași
1. Integrarea cu helper scripts-urile reale pentru automatizare completă
2. Implementarea DNS management cu API-uri externe
3. Backup automation cu planificare
4. User management pentru hosting multi-tenant
5. Billing integration pentru servicii comerciale

Acum ai un control panel complet de hosting care poate fi folosit pentru a gestiona servicii, domenii și site-uri WordPress într-o interfață modernă și ușor de folosit!
