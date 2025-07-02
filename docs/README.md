# LOMP Stack v3.0 - Advanced Hosting Control Panel

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.0-blue.svg)](https://github.com/neosilviu/LOMP-Stack)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-green.svg)](https://github.com/neosilviu/LOMP-Stack)

Complete Linux OpenLiteSpeed MySQL/MariaDB PHP Stack with Advanced Hosting Control Panel

## 🎉 **LATEST ACHIEVEMENT: Complete Template Alert() Migration**

**✅ 100% Alert() Elimination Completed!**

We've successfully eliminated **ALL 72 intrusive browser alert() calls** across **7 templates** and replaced them with a modern, professional notification system!

### 📊 **Migration Results:**
- **wordpress.html**: 22 → 0 alerts, 23 modern notifications ✅
- **domains.html**: 15 → 0 alerts, 20 modern notifications ✅  
- **api_keys.html**: 4 → 0 alerts, 6 modern notifications ✅
- **python_apps.html**: 11 → 0 alerts, 28 modern notifications ✅
- **services.html**: 6 → 0 alerts, 6 modern notifications ✅
- **hosting.html**: 6 → 0 alerts, 6 modern notifications ✅
- **updates.html**: 8 → 0 alerts, 8 modern notifications ✅

### 🚀 **Total Impact:**
- **72 → 0** intrusive browser alerts eliminated
- **97** modern notification implementations added
- **Bootstrap 5** styling with auto-dismiss functionality
- **Professional, non-blocking** user experience
- **Mobile-responsive** design
- **Enterprise-grade** error handling & user feedback

**📄 Detailed Report:** [api/web/templates/FINAL_TEMPLATE_VERIFICATION_REPORT.md](api/web/templates/FINAL_TEMPLATE_VERIFICATION_REPORT.md)

---

## 🎯 **TUTORIAL SIMPLU: De la 0 la primul site WordPress**

### **📋 Cerințe Minime**
- **Server Linux:** Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **RAM:** Minim 2GB (recomandat 4GB)
- **Stocare:** Minim 20GB spațiu liber
- **Acces:** Root sau sudo
- **Internet:** Conexiune stabilă

### **🚀 Pasul 1: Pregătirea Serverului**

```bash
# Conectare la server (SSH)
ssh root@your-server-ip

# Actualizare sistem
sudo apt update && sudo apt upgrade -y

# Instalare git (dacă nu este instalat)
sudo apt install git curl wget -y
```

### **📦 Pasul 2: Descărcarea și Instalarea LOMP Stack**

```bash
# Descărcare LOMP Stack v3.0
git clone https://github.com/neosilviu/LOMP-Stack.git
cd LOMP-Stack

# Facerea script-ului executabil
chmod +x install.sh

# Instalarea completă (durează 10-15 minute)
sudo ./install.sh

# ✅ Dacă vezi mesajul "Installation completed successfully!" - totul e gata!
```

### **🌐 Pasul 3: Accesarea Interfeței Web**

```bash
# Verificare status servicii
sudo ./helpers/monitoring/system_helpers.sh system_status

# Pornirea panoului de control
cd api/web
python3 dashboard.py
```

**🔗 Accesează în browser:** `http://your-server-ip:5000`

**📝 Credențiale implicite:**
- **Username:** `admin`
- **Password:** (generat automat - verifică în terminal la instalare)

### **🎨 Pasul 4: Interfața Web - Primul Contact**

După conectare vei vedea:

1. **📊 Dashboard Principal**
   - Statistici server (CPU, RAM, Disk)
   - Status servicii (OpenLiteSpeed, MySQL, Redis)
   - Notificări moderne (fără popup-uri deranjante!)

2. **📱 Meniu Principal:**
   - **Sites** - Gestionarea site-urilor
   - **WordPress** - Instalare și management WP
   - **Domains** - Managementul domeniilor
   - **Python Apps** - Aplicații Python
   - **Services** - Controlul serviciilor

### **🏗️ Pasul 5: Crearea Primului Site WordPress**

#### **Opțiunea A: Prin secțiunea WordPress (Recomandat)**

1. **Click pe "WordPress"** în meniu
2. **Click pe "Install New WordPress"**
3. **Completează formularul:**
   ```
   Domain: exemplu.com (sau subdomain.exemplu.com)
   WordPress Version: Latest (5.9+)
   Admin Username: admin
   Admin Password: (parola sigură)
   Admin Email: email@exemplu.com
   Site Title: Numele Site-ului Meu
   
   ✅ Enable SSL
   ✅ Auto Updates
   ✅ Security Hardening
   ```
4. **Click "Install WordPress"**
5. **Așteaptă 2-3 minute** - vei vedea notificări de progres
6. **Succes!** Vei primi linkul către site

#### **Opțiunea B: Prin secțiunea Sites**

1. **Click pe "Sites"** în meniu
2. **Click pe "Add New Site"**
3. **Selectează "WordPress Site"**
4. **Configurează:**
   ```
   Domain: exemplu.com
   Technology: WordPress
   PHP Version: 8.1
   Database: Auto-create
   ```
5. **Click "Create Site"**

### **🔍 Pasul 6: Verificarea Site-ului**

```bash
# Verificare în terminal
curl -I http://your-domain.com

# Sau accesează direct în browser
http://your-domain.com
http://your-domain.com/wp-admin
```

### **⚙️ Pasul 7: Configurări Suplimentare (Opțional)**

#### **A. Configurare SSL (HTTPS)**
1. **Domains** → **Selectează domeniul** → **SSL Management**
2. **Click "Enable Let's Encrypt SSL"**
3. **Așteaptă 1-2 minute** pentru certificat

#### **B. Optimizare Performance**
1. **Services** → **Redis** → **Start** (pentru cache)
2. **WordPress** → **Site-ul tău** → **Performance** → **Enable Caching**

#### **C. Backup Automat**
1. **WordPress** → **Site-ul tău** → **Backups**
2. **Enable Automatic Backups** → **Daily**

### **🎉 FELICITĂRI! Site-ul tău WordPress este LIVE!**

**✅ Ce ai realizat:**
- ✅ Server LOMP Stack complet configurat
- ✅ Interfață web modernă cu sistem de notificări profesional
- ✅ Site WordPress funcțional cu SSL
- ✅ Backup automat configurat
- ✅ Performance optimizat

### **🔧 Comenzi Rapide pentru Administrare**

```bash
# Status general sistem
sudo ./helpers/monitoring/system_helpers.sh system_status

# Restart toate serviciile
sudo ./helpers/monitoring/system_helpers.sh restart_services

# Backup manual
sudo ./helpers/utils/backup_manager.sh backup_all

# Verificare log-uri
tail -f /var/log/lomp-stack/panel.log
```

### **🆘 Rezolvarea Problemelor Comune**

#### **Problem 1: Nu pot accesa panoul (port 5000)**
```bash
# Verifică firewall
sudo ufw allow 5000
sudo systemctl restart ufw

# Restart dashboard
cd LOMP-Stack/api/web
python3 dashboard.py
```

#### **Problem 2: Site-ul nu se încarcă**
```bash
# Verifică OpenLiteSpeed
sudo systemctl status openlitespeed
sudo systemctl restart openlitespeed

# Verifică DNS
nslookup your-domain.com
```

#### **Problem 3: Probleme cu baza de date**
```bash
# Restart MySQL/MariaDB
sudo systemctl restart mariadb
sudo systemctl status mariadb
```

### **📞 Suport și Resurse**

- **📧 Email:** neosilviu@gmail.com
- **🐛 GitHub Issues:** [LOMP-Stack Issues](https://github.com/neosilviu/LOMP-Stack/issues)
- **📚 Documentație completă:** Scroll jos în acest README
- **🎥 Video Tutorial:** (în curând)

**⏱️ Timp total estimat: 15-20 minute pentru un server complet funcțional!**

---

## 👨‍💻 Author Information

- **Author:** Silviu Ilie
- **Email:** neosilviu@gmail.com
- **Company:** aemdPC
- **Role:** Lead Developer & System Architect

## 📋 Project Details

- **Version:** 3.0.0
- **License:** MIT License
- **Copyright:** © 2025 aemdPC

## 🔗 Links

- **Repository:** https://github.com/aemdPC/lomp-stack-v3
- **Documentation:** https://docs.aemdpc.com/lomp-stack
- **Support:** https://support.aemdpc.com

## 🚀 About LOMP Stack v3.0

LOMP Stack v3.0 is a comprehensive hosting solution that combines:

- **L**inux Operating System
- **O**penLiteSpeed Web Server
- **M**ySQL/MariaDB Database
- **P**HP Programming Language

Enhanced with:
- Advanced Hosting Control Panel
- Python Applications Support (Flask, Django, FastAPI)
- WordPress Management
- Multi-site Hosting
- SSL Automation
- Performance Monitoring
- Backup Management

## ✨ Features

### Core Components
- OpenLiteSpeed Web Server with optimized configurations
- MySQL/MariaDB database management
- PHP 8.1+ support with multiple versions
- Redis caching and session storage
- SSL/TLS certificate automation

### Hosting Control Panel
- Modern web-based control panel similar to cPanel
- Multi-site management with different technologies
- Domain and subdomain management
- Database creation and management
- Service monitoring and control

### Python Applications
- Support for Flask, Django, FastAPI frameworks
- Git-based deployment with automatic setup
- Virtual environment management
- Dependency management with GUI
- Environment variables editor
- Performance monitoring

### WordPress Integration
- One-click WordPress installation
- Automatic database setup
- Plugin and theme management
- Backup and restoration tools
- Security hardening

### Security Features
- UFW firewall integration
- Fail2ban intrusion detection
- SSL certificate automation (Let's Encrypt)
- Cloudflare integration
- Security scanning and monitoring

## 🛠️ Installation

### Prerequisites
- Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / AlmaLinux 8+
- Root or sudo access
- Minimum 2GB RAM
- 20GB available disk space

### Quick Installation

```bash
# Clone the repository
git clone https://github.com/aemdPC/lomp-stack-v3.git
cd lomp-stack-v3

# Make the installer executable
chmod +x install.sh

# Run the installation
sudo ./install.sh
```

### Advanced Installation

```bash
# Custom installation with specific components
sudo ./install.sh --web-server=nginx --database=mariadb --php-version=8.2

# Install with hosting control panel
sudo ./install.sh --enable-hosting-panel

# Install with Python support
sudo ./install.sh --enable-python-apps
```

## 🚀 Quick Start

### 1. Access the Control Panel
After installation, access the web control panel:
```
http://your-server-ip:5000
```

### 2. Default Credentials
- **Username:** admin
- **Password:** (generated during installation - check logs)

### 3. Create Your First Site
1. Navigate to **Sites** → **Add New Site**
2. Enter domain name and select site type (PHP/WordPress/Python)
3. Configure settings and click **Create**

### 4. Deploy Python Applications
1. Go to **Python Apps** → **Deploy New App**
2. Choose framework (Flask/Django/FastAPI)
3. Enter Git repository URL (optional)
4. Configure environment and click **Deploy**

### 5. Install WordPress
1. Navigate to **WordPress** → **Install New**
2. Select domain and database settings
3. Configure admin credentials
4. Click **Install WordPress**

## 📖 Tutorial Simplu: De la Zero la WordPress

### Pasul 1: Pregătirea Serverului
```bash
# Conectează-te la serverul tău Ubuntu/Debian prin SSH
ssh root@your-server-ip

# Actualizează sistemul
sudo apt update && sudo apt upgrade -y
```

### Pasul 2: Descarcă LOMP Stack
```bash
# Descarcă LOMP Stack
git clone https://github.com/neosilviu/LOMP-Stack.git
cd LOMP-Stack

# Fă fișierul de instalare executabil
chmod +x install.sh
```

### Pasul 3: Instalează LOMP Stack
```bash
# Rulează instalarea (durează 10-15 minute)
sudo ./install.sh

# Notează parola pentru admin (va fi afișată la final)
```

### Pasul 4: Accesează Interfața Web
1. Deschide browser-ul și du-te la: `http://IP-ul-serverului:5000`
2. Loghează-te cu:
   - **Username:** admin
   - **Password:** (parola generată la instalare)

### Pasul 5: Creează primul site WordPress
1. **În interfață, click pe "WordPress"** din meniul lateral
2. **Click "Adaugă WordPress Nou"**
3. **Completează:**
   - Nume domeniu: `site1.yourdomain.com` (sau IP-ul serverului)
   - Nume site: `Primul meu site`
   - Username admin: `admin`
   - Parolă admin: `parola-ta-sigura`
   - Email: `email@yourdomain.com`
4. **Click "Instalează WordPress"**

### Pasul 6: Accesează site-ul WordPress
- Site-ul: `http://IP-ul-serverului` sau `http://domeniul-tau`
- Admin WordPress: `http://IP-ul-serverului/wp-admin`

### 🎉 Gata! Ai primul tău site WordPress!

**📋 Tutorial complet:** [documents/TUTORIAL_SIMPLU_LOMP_STACK.md](documents/TUTORIAL_SIMPLU_LOMP_STACK.md)

## 📚 Documentation

### Component Documentation
- [Installation Guide](docs/installation.md)
- [Control Panel Guide](api/web/ENHANCED_HOSTING_CONTROL_PANEL_GUIDE.md)
- [Python Apps Management](docs/python-apps.md)
- [WordPress Management](docs/wordpress.md)
- [Security Configuration](docs/security.md)
- [Backup & Recovery](docs/backup.md)

### API Documentation
- [REST API Reference](docs/api-reference.md)
- [Helper Scripts](docs/helper-scripts.md)
- [Database Schema](docs/database-schema.md)

### Developer Documentation
- [Contributing Guidelines](CONTRIBUTING.md)
- [Architecture Overview](docs/architecture.md)
- [Custom Development](docs/custom-development.md)

## 🏗️ Architecture

```
LOMP Stack v3.0
├── Core Stack
│   ├── OpenLiteSpeed Web Server
│   ├── MySQL/MariaDB Database
│   ├── PHP 8.1+ Runtime
│   └── Redis Cache
├── Control Panel
│   ├── Web Dashboard (Flask)
│   ├── API Layer
│   ├── Database Management
│   └── Service Control
├── Python Applications
│   ├── Framework Support
│   ├── Git Deployment
│   ├── Environment Management
│   └── Performance Monitoring
└── Helper Scripts
    ├── Installation & Setup
    ├── Service Management
    ├── Security Hardening
    └── Backup & Recovery
```

## 🔧 Configuration

### Environment Variables
```bash
# Stack configuration
STACK_ENV=production
STACK_VERSION=3.0.0
STACK_ROOT=/opt/lomp-stack

# Control panel
PANEL_PORT=5000
PANEL_SSL=true
PANEL_DEBUG=false

# Database
DB_TYPE=mariadb
DB_ROOT_PASSWORD=auto_generated

# Web server
WEB_SERVER=openlitespeed
WEB_PORT=80
WEB_SSL_PORT=443
```

### Service Ports
- **OpenLiteSpeed Admin:** 7080
- **Control Panel:** 5000
- **MySQL/MariaDB:** 3306
- **Redis:** 6379
- **Python Apps:** 8000-9000 (auto-assigned)

## 🧪 Testing

### Run Tests
```bash
# Full system test
sudo ./tests/test_stack.sh

# Control panel tests
cd api/web
python test_enhanced_hosting.py

# Component tests
sudo ./tests/test_components.sh
```

### Health Checks
```bash
# Check all services
sudo ./helpers/monitoring/system_helpers.sh system_status

# Check specific service
sudo systemctl status openlitespeed
sudo systemctl status mariadb
sudo systemctl status redis
```

## 🛡️ Security

### Default Security Measures
- UFW firewall enabled with minimal ports
- Fail2ban protection against brute force
- SSL certificates via Let's Encrypt
- Database security hardening
- PHP security configurations
- Regular security updates

### Additional Security Options
```bash
# Enable additional security
sudo ./helpers/security/install_security.sh

# Configure Cloudflare
sudo ./helpers/security/cloudflare_helpers.sh configure

# Setup monitoring
sudo ./helpers/monitoring/install_monitoring.sh
```

## 📊 Monitoring

### Built-in Monitoring
- **Netdata:** Real-time system monitoring
- **Performance Metrics:** CPU, memory, disk usage
- **Service Status:** All stack components
- **Application Monitoring:** Python apps performance
- **Log Analysis:** Centralized log management

### Access Monitoring
- **Netdata Dashboard:** http://your-server-ip:19999
- **Control Panel Metrics:** Built into the control panel
- **Log Files:** `/var/log/lomp-stack/`

## 🔄 Backup & Recovery

### Automatic Backups
```bash
# Enable automatic backups
sudo ./helpers/utils/backup_manager.sh setup_auto_backup

# Manual backup
sudo ./helpers/utils/backup_manager.sh backup_all
```

### Recovery
```bash
# Restore from backup
sudo ./helpers/utils/backup_manager.sh restore /path/to/backup

# Disaster recovery
sudo ./helpers/utils/backup_manager.sh disaster_recovery
```

## 🚨 Troubleshooting

### Common Issues

#### Installation Issues
```bash
# Check system requirements
./helpers/utils/check_core_dependencies.sh

# Fix permissions
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/
```

#### Service Issues
```bash
# Restart all services
sudo ./helpers/monitoring/system_helpers.sh restart_services

# Check service logs
sudo journalctl -u openlitespeed -f
sudo journalctl -u mariadb -f
```

#### Python App Issues
```bash
# Check Python app logs
sudo journalctl -u your-app.service -f

# Verify virtual environment
source /var/www/your-app/venv/bin/activate
pip list
```

### Log Files
- **Installation:** `/var/log/lomp-stack/install.log`
- **Control Panel:** `/var/log/lomp-stack/panel.log`
- **OpenLiteSpeed:** `/usr/local/lsws/logs/`
- **MySQL/MariaDB:** `/var/log/mysql/`
- **Python Apps:** `/var/log/lomp-stack/python-apps/`

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
```bash
# Fork and clone the repository
git clone https://github.com/yourusername/lomp-stack-v3.git
cd lomp-stack-v3

# Create development branch
git checkout -b feature/your-feature

# Make changes and test
sudo ./tests/test_stack.sh

# Submit pull request
```

### Reporting Issues
- **Bug Reports:** Use GitHub Issues
- **Feature Requests:** Use GitHub Discussions
- **Security Issues:** Email neosilviu@gmail.com

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Special thanks to:
- The OpenLiteSpeed development team
- The open-source community
- All contributors and users who have provided feedback

## 📞 Support

### Technical Support
- **Email:** neosilviu@gmail.com
- **Support Portal:** https://support.aemdpc.com
- **Documentation:** https://docs.aemdpc.com/lomp-stack
- **Issues:** https://github.com/aemdPC/lomp-stack-v3/issues

### Commercial Support
For enterprise support, custom development, and consulting services, please contact:
- **Company:** aemdPC
- **Email:** neosilviu@gmail.com
- **Website:** https://aemdpc.com

---

**Developed with ❤️ by Silviu Ilie at aemdPC**

*Transform your server into a powerful hosting platform with LOMP Stack v3.0*
