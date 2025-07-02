# WordPress LOMP Stack - Advanced Menu System

## 📋 **Overview**

The new menu system provides a complete guided installation experience with language selection and customizable installation modes.

## 🌍 **Step 1: Language Selection**

First, users select their preferred language:

```
╔════════════════════════════════════════════════════════════════╗
║                     Language Selection                        ║
║                     Selectare Limbă                           ║
╚════════════════════════════════════════════════════════════════╝

Please select your language / Vă rugăm să selectați limba:

1. 🇷🇴 Română (Romanian)
2. 🇬🇧 English
3. 🇪🇸 Español (Spanish)
4. 🇫🇷 Français (French)
5. 🇩🇪 Deutsch (German)

Select option / Selectați opțiunea (1-5):
```

## 🔧 **Step 2: Installation Mode Selection**

After language selection, users choose the installation mode:

```
╔════════════════════════════════════════════════════════════════╗
║                   Installation Mode Selection                 ║
╚════════════════════════════════════════════════════════════════╝

Please select the installation mode:

1. 🚀 Standard Minimal - OpenLiteSpeed + WordPress (Recommended)
   ├─ MariaDB + PHP 8.1
   ├─ OpenLiteSpeed with admin panel
   └─ Optimized for production

2. ⚡ Ultra Minimal - Nginx + WordPress (Lightweight)
   ├─ MariaDB + PHP 8.1
   ├─ Nginx-light (minimal resources)
   └─ Perfect for testing/development

3. ⚙️  Advanced - Custom configuration
   ├─ Choose components individually
   ├─ Custom security settings
   └─ Performance optimization options

4. 📝 Install optional packages

5. ❌ Exit
Select option (1-5):
```

## ⚙️ **Advanced Mode Configuration**

When selecting Advanced mode, users get detailed customization options:

### 🌐 **Web Server Selection**
```
1. Web Server Selection:
   Choose web server:
   a) OpenLiteSpeed (with admin panel)
   b) Nginx (lightweight)
   c) Apache (traditional)

Select web server (a-c) [a]:
```

### 💾 **Database Selection**
```
2. Database Selection:
   Choose database:
   a) MariaDB (recommended)
   b) MySQL
   c) External database

Select database (a-c) [a]:
```

### 🔒 **Security Options**
```
3. Security Options:
   Enable additional security? (firewall, fail2ban, etc.)
Enable security (y/N):
```

### ⚡ **Performance Optimization**
```
4. Performance Optimization:
   Enable performance optimizations? (caching, compression, etc.)
Enable optimizations (y/N):
```

### 📋 **Configuration Summary**
```
Configuration Summary:
─────────────────────────
Web Server: nginx
Database: mariadb
Security: true
Optimization: false

Continue with this configuration? (Y/n):
```

## 🚀 **Installation Modes Comparison**

| Feature | Standard Minimal | Ultra Minimal | Advanced |
|---------|------------------|---------------|----------|
| **Web Server** | OpenLiteSpeed | Nginx-light | Configurable |
| **Database** | MariaDB | MariaDB | Configurable |
| **Admin Panel** | ✅ OLS WebAdmin | ❌ None | Configurable |
| **Resources** | ~500MB | ~300MB | Variable |
| **Security** | Basic | Basic | Configurable |
| **Optimization** | Included | Minimal | Configurable |
| **Best For** | Production | Testing/Dev | Custom needs |

## 💻 **Command Line Usage**

### Interactive Mode (Full Menu)
```bash
sudo bash minimal_install.sh
```

### Direct Mode Selection
```bash
# Ultra-minimal (Nginx)
sudo bash minimal_install.sh --ultra

# Advanced configuration
sudo bash minimal_install.sh --advanced

# Standard minimal (default)
sudo bash minimal_install.sh
```

## 🌍 **Multi-Language Headers**

The system shows localized headers based on the selected language and mode:

### Romanian (Default)
- **Standard:** "WordPress LOMP Stack - Minimal Core"
- **Ultra:** "WordPress LOMP Stack - Minim Ultra Core"
- **Advanced:** "WordPress LOMP Stack - Configurare Avansată"

### English
- **Standard:** "WordPress LOMP Stack - Minimal Core"
- **Ultra:** "WordPress LOMP Stack - Ultra Minimal Core"
- **Advanced:** "WordPress LOMP Stack - Advanced Setup"

### Spanish
- **Standard:** "WordPress LOMP Stack - Núcleo Mínimo"
- **Ultra:** "WordPress LOMP Stack - Núcleo Ultra Mínimo"
- **Advanced:** "WordPress LOMP Stack - Configuración Avanzada"

### French
- **Standard:** "WordPress LOMP Stack - Noyau Minimal"
- **Ultra:** "WordPress LOMP Stack - Noyau Ultra Minimal"
- **Advanced:** "WordPress LOMP Stack - Configuration Avancée"

### German
- **Standard:** "WordPress LOMP Stack - Minimaler Kern"
- **Ultra:** "WordPress LOMP Stack - Ultra Minimaler Kern"
- **Advanced:** "WordPress LOMP Stack - Erweiterte Konfiguration"

## 🔄 **Backward Compatibility**

The system maintains full backward compatibility:
- Old command line parameters (`--ultra`) still work
- Existing automation scripts continue to function
- Default behavior remains unchanged when no parameters are provided

## 🎯 **Benefits**

1. **User-Friendly**: Guided installation with clear options
2. **Flexible**: Three different installation approaches
3. **Multilingual**: Support for 5 languages
4. **Customizable**: Advanced mode allows fine-tuning
5. **Compatible**: Works with existing scripts and automation
6. **Visual**: Clean, professional menu design

## 📝 **Usage Examples**

### Example 1: First-Time User
```bash
# User runs the script
sudo bash minimal_install.sh

# Step 1: Selects language (Romanian)
# Step 2: Selects Standard Minimal
# Result: OpenLiteSpeed + WordPress installation in Romanian
```

### Example 2: Developer Setup
```bash
# User runs the script
sudo bash minimal_install.sh

# Step 1: Selects language (English)  
# Step 2: Selects Ultra Minimal
# Result: Nginx + WordPress installation in English
```

### Example 3: Custom Production Setup
```bash
# User runs the script
sudo bash minimal_install.sh

# Step 1: Selects language (English)
# Step 2: Selects Advanced
# Step 3: Configures Apache + MySQL + Security + Optimization
# Result: Fully customized installation
```
