# 📖 Tutorial Simplu LOMP Stack v3.0
**De la Zero la primul site WordPress în 15 minute**

---

## 🎯 Rezultatul final
După acest tutorial vei avea:
✅ Server web complet funcțional  
✅ Interfață de management modernă  
✅ Primul tău site WordPress  
✅ Backup automat și monitoring  

---

## 📋 Cerințe

### Server necesar:
- **OS:** Ubuntu 20.04+ sau Debian 11+
- **RAM:** 2GB minim (4GB recomandat)
- **Disk:** 20GB spațiu liber
- **CPU:** 1 vCPU minim

### Pe computerul tău:
- Browser web modern
- Client SSH (PuTTY, Terminal, etc.)

---

## 🚀 **Pasul 1: Conectare la server**

### Windows (PuTTY):
1. Descarcă [PuTTY](https://www.putty.org/)
2. Host Name: `IP-ul-serverului`
3. Port: `22` → Click **Open**
4. Login: `root` + parola

### Mac/Linux (Terminal):
```bash
ssh root@IP-ul-serverului
```

---

## 🛠️ **Pasul 2: Pregătire server**

Copiază și lipește aceste comenzi:

```bash
# Actualizare sistem
sudo apt update && sudo apt upgrade -y

# Instalare tools de bază  
sudo apt install -y git curl wget nano
```

---

## 📥 **Pasul 3: Descărcare LOMP Stack**

```bash
# Descarcă proiectul
git clone https://github.com/neosilviu/LOMP-Stack.git

# Intră în folder
cd LOMP-Stack

# Verifică fișierele
ls -la
```

**Trebuie să vezi:** `install.sh`, `helpers/`, `api/`, `README.md`

---

## ⚙️ **Pasul 4: Instalare LOMP Stack**

```bash
# Fă scriptul executabil
chmod +x install.sh

# Începe instalarea (10-15 minute)
sudo ./install.sh
```

### Ce se instalează:
⏳ Nginx (server web)  
⏳ PHP 8.2 + extensii  
⏳ MariaDB (baza de date)  
⏳ Interfața web Flask  
⏳ Redis (cache)  
⏳ Configurări de securitate  

### 🔐 **FOARTE IMPORTANT!**
La final vei vedea:
```
========================================
LOMP Stack Installation Complete!
========================================
Web Interface: http://YOUR-IP:5000
Username: admin
Password: ABC123XYZ789
========================================
```

**📝 NOTEAZĂ ACEASTĂ PAROLĂ!**

---

## 🌐 **Pasul 5: Accesare interfață**

1. Deschide browser-ul
2. Du-te la: `http://IP-ul-serverului:5000`
3. Loghează-te:
   - **Username:** `admin`
   - **Password:** `parola-de-la-instalare`

### Problemă de conectare?
```bash
# Verifică serviciile
sudo systemctl status lomp-api nginx

# Deschide portul în firewall
sudo ufw allow 5000
sudo ufw allow 80
sudo ufw allow 443
```

---

## 🏠 **Pasul 6: Primul site WordPress**

### În interfața web:

1. **Click "WordPress"** (meniul stânga)
2. **Click "Adaugă WordPress Nou"**
3. **Completează:**

```
Domain: primul-site.local
Site Title: Primul Meu Site
Admin User: admin  
Admin Password: parola-foarte-sigura
Admin Email: email@domain.com
Language: ro_RO
```

4. **Click "Instalează WordPress"**
5. **Așteaptă 2-3 minute** ⏳

---

## 🎉 **Pasul 7: Accesare WordPress**

### Site-ul public:
```
http://IP-ul-serverului
```

### Admin WordPress:  
```
http://IP-ul-serverului/wp-admin
```
- User: `admin`
- Pass: `parola-foarte-sigura`

---

## 🔧 **Configurări opționale**

### A. Domeniu propriu

**În panoul domeniului (Cloudflare, etc.):**
- Adaugă record A: `@` → `IP-serverului`

**În LOMP Stack:**
- Domains → Add Domain → introdu domeniul

### B. Certificate SSL (HTTPS)

În interfață:
1. Security → Generate SSL
2. Introdu domeniul
3. Click Generate

### C. Backup automat

1. Backup → Enable Auto Backup
2. Frequency: `Daily`
3. Keep: `7 backups`

---

## 🆘 **Probleme comune**

### ❌ "Cannot connect to database"
```bash
sudo systemctl restart mariadb
sudo mysql_secure_installation
```

### ❌ "Permission denied"  
```bash
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/
```

### ❌ "Port not accessible"
```bash
sudo ufw allow 5000
sudo ufw allow 80  
sudo ufw allow 443
```

---

## 📊 **Monitorizare**

### Verificări zilnice:
✅ Dashboard → System Status  
✅ Logs → Check for errors  
✅ Backup → Verify completion  

### Comenzi utile:
```bash
# Status servicii
sudo systemctl status lomp-api nginx mariadb

# Spațiu disk
df -h

# Memorie
free -h
```

---

## 🚀 **Pași următori**

### 1. **Mai multe site-uri:**
- Repetă procesul pentru fiecare site
- Folosește subdomenii: `blog.domain.com`

### 2. **Python Apps:**  
- Flask pentru web apps simple
- Django pentru apps complexe
- FastAPI pentru API-uri

### 3. **Securitate avansată:**
- Firewall rules
- SSL certificates  
- User permissions

---

## ✨ **Felicitări!**

Ai instalat cu succes **LOMP Stack v3.0** și primul site WordPress!

### 📞 **Suport:**
- **Issues:** [GitHub Issues](https://github.com/neosilviu/LOMP-Stack/issues)
- **Docs:** [README.md](../README.md)

### 🎯 **Te-a ajutat?**
⭐ Marchează proiectul pe GitHub!

---

**💡 Salvează acest tutorial pentru referințe viitoare!**

**În panoul domeniului (Cloudflare, etc.):**
- Adaugă record A: `@` → `IP-serverului`

**În LOMP Stack:**
- Domains → Add Domain → introdu domeniul

### B. Certificate SSL (HTTPS)

În interfață:
1. Security → Generate SSL
2. Introdu domeniul
3. Click Generate

### C. Backup automat

1. Backup → Enable Auto Backup
2. Frequency: `Daily`
3. Keep: `7 backups`

---

## 🆘 **Probleme comune**

### ❌ "Cannot connect to database"
```bash
sudo systemctl restart mariadb
sudo mysql_secure_installation
```

### ❌ "Permission denied"  
```bash
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/
```

### ❌ "Port not accessible"
```bash
sudo ufw allow 5000
sudo ufw allow 80  
sudo ufw allow 443
```

---

## � **Monitorizare**

### Verificări zilnice:
✅ Dashboard → System Status  
✅ Logs → Check for errors  
✅ Backup → Verify completion  

### Comenzi utile:
```bash
# Status servicii
sudo systemctl status lomp-api nginx mariadb

# Spațiu disk
df -h

# Memorie
free -h
```

---

## 🚀 **Pași următori**

### 1. **Mai multe site-uri:**
- Repetă procesul pentru fiecare site
- Folosește subdomenii: `blog.domain.com`

### 2. **Python Apps:**  
- Flask pentru web apps simple
- Django pentru apps complexe
- FastAPI pentru API-uri

### 3. **Securitate avansată:**
- Firewall rules
- SSL certificates  
- User permissions

---

## ✨ **Felicitări!**

Ai instalat cu succes **LOMP Stack v3.0** și primul site WordPress!

### � **Suport:**
- **Issues:** [GitHub Issues](https://github.com/neosilviu/LOMP-Stack/issues)
- **Docs:** [README.md](../README.md)

### 🎯 **Te-a ajutat?**
⭐ Marchează proiectul pe GitHub!

---

**� Salvează acest tutorial pentru referințe viitoare!**
🔑 Password: GENERATED_PASSWORD_HERE
```

---

## 🌐 **PARTEA 2: Accesarea Interfeței Web**

### **Pasul 2.1: Pornirea Panoului de Control**

```bash
# Navigarea în directorul web
cd api/web

# Pornirea dashboard-ului
python3 dashboard.py
```

**Vei vedea:**
```
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://YOUR_IP:5000
```

### **Pasul 2.2: Accesarea în Browser**

1. **Deschide browserul** (Chrome, Firefox, Safari, Edge)
2. **Navighează la:** `http://IP_SERVERULUI_TAU:5000`
3. **Exemplu:** `http://123.456.789.10:5000`

### **Pasul 2.3: Login Prima Dată**

**Ecranul de login:**
- **Username:** `admin`
- **Password:** (parola generată la instalare)
- **Click "Login"**

**🎉 Felicitări! Ești în panoul de control LOMP Stack v3.0!**

---

## 🎨 **PARTEA 3: Explorarea Interfeței**

### **Dashboard Principal - Ce vei vedea:**

#### **📊 Secțiunea de Statistici:**
- **CPU Usage:** Utilizarea procesorului în timp real
- **Memory Usage:** Utilizarea memoriei RAM
- **Disk Usage:** Spațiul utilizat pe disk
- **Active Sites:** Numărul de site-uri active

#### **🎛️ Meniul Principal:**
- **🏠 Dashboard** - Pagina principală cu statistici
- **🌐 Sites** - Gestionarea tuturor site-urilor
- **📝 WordPress** - Management dedicat WordPress
- **🌍 Domains** - Managementul domeniilor și DNS
- **🐍 Python Apps** - Aplicații Python (Flask, Django)
- **⚙️ Services** - Control servicii sistem
- **🔑 API Keys** - Managementul cheilor API
- **📊 Monitoring** - Monitorizare avansată
- **🔄 Updates** - Actualizări sistem

#### **🔔 Sistemul de Notificări:**
- **Notificări moderne** în colțul din dreapta sus
- **Fără popup-uri deranjante** (am eliminat toate alert()-urile!)
- **Auto-dismiss** după 5 secunde
- **Culori intuitive:** Verde (succes), Roșu (eroare), Galben (atenție)

---

## 🏗️ **PARTEA 4: Crearea Primului Site WordPress**

### **Metoda 1: WordPress Manager (Recomandată)**

#### **Pasul 4.1: Accesarea WordPress Manager**
1. **Click pe "WordPress"** în meniul din stânga
2. Vei vedea secțiuni:
   - **📊 Overview** - Statistici WordPress
   - **➕ Install New** - Instalare WordPress nouă
   - **📋 Manage Sites** - Gestionare site-uri existente

#### **Pasul 4.2: Instalarea WordPress**
1. **Click pe "Install New WordPress"**
2. **Completează formularul:**

```
🌐 Domain Settings:
   Domain: exemplu.com (sau subdomain.exemplu.com)
   Subdirectory: / (pentru root domain)

📝 WordPress Settings:
   Version: Latest (recomandat)
   Admin Username: admin (sau alt username)
   Admin Password: (parola puternică!)
   Admin Email: email@exemplu.com
   Site Title: "Numele Site-ului Meu"

🔧 Advanced Settings:
   ✅ Enable SSL (recomandat)
   ✅ Auto Updates (recomandat)  
   ✅ Security Hardening (recomandat)
   ✅ Enable Cloudflare (dacă ai cont)
```

3. **Click "Install WordPress"**

#### **Pasul 4.3: Monitorizarea Instalării**
- Vei vedea **notificări de progres** în timp real
- **Nu închide pagina** în timpul instalării
- Procesul durează **2-5 minute**

**Progresul afișat:**
```
🔄 Creating database...
✅ Database created successfully!
🔄 Downloading WordPress...
✅ WordPress downloaded!
🔄 Configuring WordPress...
✅ WordPress configured!
🔄 Setting up SSL certificate...
✅ SSL certificate installed!
🎉 WordPress installation completed!
```

### **Metoda 2: Sites Manager**

#### **Alternativă prin Sites Manager:**
1. **Click pe "Sites"** → **"Add New Site"**
2. **Selectează "WordPress"** ca tip de site
3. **Configurează setările** similar cu metoda 1
4. **Click "Create Site"**

---

## 🔍 **PARTEA 5: Verificarea și Testarea Site-ului**

### **Pasul 5.1: Accesarea Site-ului**

**În browser, navighează la:**
- **Site-ul principal:** `http://domeniul-tau.com`
- **Admin WordPress:** `http://domeniul-tau.com/wp-admin`

### **Pasul 5.2: Primul Login în WordPress**

1. **Acces la:** `http://domeniul-tau.com/wp-admin`
2. **Username:** cel setat la instalare
3. **Password:** parola setată la instalare
4. **Click "Log In"**

### **Pasul 5.3: Personalizarea Site-ului**

**Prima configurare WordPress:**
1. **Appearance** → **Themes** - Alege o temă
2. **Posts** → **Add New** - Creează primul articol
3. **Pages** → **Add New** - Creează pagini
4. **Settings** → **General** - Configurări generale

---

## ⚙️ **PARTEA 6: Configurări Avansate**

### **6.1: Configurarea SSL (HTTPS)**

**În panoul LOMP:**
1. **Domains** → **Selectează domeniul**
2. **SSL Management** → **"Enable Let's Encrypt SSL"**
3. **Așteaptă 1-2 minute** pentru certificat
4. **Testează:** `https://domeniul-tau.com`

### **6.2: Optimizarea Performance**

**Activarea Cache:**
1. **Services** → **Redis** → **Start**
2. **WordPress** → **Domeniul tău** → **Performance**
3. **Enable Object Caching**
4. **Enable Page Caching**

**Optimizarea PHP:**
1. **Services** → **PHP** → **Configuration**
2. **Ajustează:**
   - `memory_limit = 256M`
   - `max_execution_time = 300`
   - `upload_max_filesize = 64M`

### **6.3: Backup Automat**

1. **WordPress** → **Site-ul tău** → **Backups**
2. **Enable Automatic Backups**
3. **Frequency:** Daily
4. **Retention:** 30 days
5. **Save Settings**

### **6.4: Monitorizarea Site-ului**

**Verificări regulate:**
1. **Monitoring** → **Site Performance**
2. **Services** → **System Status**
3. **Logs** → **Error Logs**

---

## 🛡️ **PARTEA 7: Securitate și Mentennanță**

### **7.1: Configurări de Securitate**

**Firewall:**
```bash
# Verificarea status firewall
sudo ufw status

# Deschiderea porturilor necesare
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 5000  # Panel LOMP
sudo ufw allow 22    # SSH
```

**Fail2Ban (protecție brute force):**
```bash
# Verificarea status
sudo systemctl status fail2ban

# Verificarea jail-uri active
sudo fail2ban-client status
```

### **7.2: Actualizări Regulate**

**WordPress:**
- **Auto-updates** activat la instalare
- **Manual:** WordPress Admin → **Updates**

**Sistem:**
```bash
# Actualizări sistem
sudo apt update && sudo apt upgrade

# Actualizări LOMP Stack
cd LOMP-Stack
git pull origin main
```

### **7.3: Backup și Recovery**

**Backup manual:**
```bash
cd LOMP-Stack
sudo ./helpers/utils/backup_manager.sh backup_all
```

**Restore backup:**
```bash
sudo ./helpers/utils/backup_manager.sh restore /path/to/backup
```

---

## 🆘 **PARTEA 8: Rezolvarea Problemelor**

### **Probleme Comune și Soluții**

#### **8.1: Nu pot accesa panoul (port 5000)**

**Cauze posibile:**
- Firewall blochează portul
- Dashboard-ul nu rulează
- IP-ul serverului e greșit

**Soluții:**
```bash
# Verifică firewall
sudo ufw allow 5000
sudo systemctl restart ufw

# Restart dashboard
cd LOMP-Stack/api/web
python3 dashboard.py

# Verifică IP server
curl ifconfig.me
```

#### **8.2: Site-ul nu se încarcă**

**Verificări:**
```bash
# Status OpenLiteSpeed
sudo systemctl status openlitespeed
sudo systemctl restart openlitespeed

# Verifică DNS
nslookup domeniul-tau.com

# Verifică configurația site
ls -la /usr/local/lsws/Example/html/
```

#### **8.3: Erori bază de date**

```bash
# Status MySQL/MariaDB
sudo systemctl status mariadb
sudo systemctl restart mariadb

# Login MySQL pentru verificări
sudo mysql -u root -p

# Verifică bazele de date
SHOW DATABASES;
```

#### **8.4: Probleme SSL**

```bash
# Verifică certificatul
openssl s_client -connect domeniul-tau.com:443

# Regenerează certificatul
cd LOMP-Stack
sudo ./helpers/utils/ssl_helpers.sh renew_ssl domeniul-tau.com
```

### **8.5: Log Files pentru Debugging**

**Locația log-urilor:**
```bash
# LOMP Stack logs
tail -f /var/log/lomp-stack/install.log
tail -f /var/log/lomp-stack/panel.log

# OpenLiteSpeed logs
tail -f /usr/local/lsws/logs/error.log
tail -f /usr/local/lsws/logs/access.log

# MySQL logs
tail -f /var/log/mysql/error.log

# System logs
tail -f /var/log/syslog
```

---

## ✅ **PARTEA 9: Verificarea Finală**

### **Checklist de Succes:**

**✅ Server și Servicii:**
- [ ] LOMP Stack instalat cu succes
- [ ] Toate serviciile rulează (OpenLiteSpeed, MySQL, Redis)
- [ ] Panoul web accesibil pe portul 5000
- [ ] Firewall configurat corect

**✅ Site WordPress:**
- [ ] Site-ul se încarcă la `http://domeniul-tau.com`
- [ ] Admin panel accesibil la `/wp-admin`
- [ ] SSL activat și funcțional (HTTPS)
- [ ] Prima postare creată cu succes

**✅ Securitate și Performance:**
- [ ] Backup automat configurat
- [ ] Cache activat (Redis)
- [ ] Fail2Ban protecție activă
- [ ] SSL certificate valid

**✅ Monitoring:**
- [ ] Statistici dashboard funcționale
- [ ] Notificări moderne activate
- [ ] Log-urile accesibile și monitorizate

---

## 🎉 **FELICITĂRI! AI REUȘIT!**

### **Ce ai realizat:**

🏆 **Ai construit cu succes:**
- ✅ **Server LOMP Stack** complet funcțional
- ✅ **Panou de control web** modern și profesional
- ✅ **Site WordPress** optimizat și securizat
- ✅ **Sistem de backup** automat
- ✅ **Monitorizare** în timp real
- ✅ **Securitate** enterprise-grade

### **Ce urmează:**

🚀 **Următorii pași recomandați:**
1. **Creează conținut** pentru site-ul tău WordPress
2. **Instalează plugin-uri** necesare (SEO, securitate, cache)
3. **Configurează CDN** prin Cloudflare (opțional)
4. **Adaugă mai multe site-uri** prin panoul LOMP
5. **Explorează funcțiile Python Apps** pentru aplicații custom

### **Resurse Suplimentare:**

📚 **Documentație:**
- [WordPress Official Documentation](https://wordpress.org/support/)
- [OpenLiteSpeed Wiki](https://openlitespeed.org/mediawiki/)
- [LOMP Stack Advanced Guide](../README.md)

🎥 **Tutoriale Video:**
- Tutorial video complet (în curând)
- Configurări avansate (în curând)

💬 **Suport:**
- **Email:** neosilviu@gmail.com
- **GitHub Issues:** [github.com/neosilviu/LOMP-Stack/issues](https://github.com/neosilviu/LOMP-Stack/issues)
- **Discord Community:** (în curând)

---

## 📊 **Performanță și Statistici**

### **Timp Total Instalare:** ~20-30 minute
### **Resurse Utilizate:**
- **CPU:** ~50% în timpul instalării
- **RAM:** ~1.5GB după instalare
- **Disk:** ~8GB pentru stack complet

### **Capabilități Site:**
- **Concurrent Users:** 1000+ (pe server 4GB RAM)
- **Page Load Speed:** <2 secunde (cu cache)
- **SSL Grade:** A+ (cu configurație optimă)
- **Security Score:** 95%+ (cu toate măsurile activate)

---

**🌟 Dezvoltat cu ❤️ de Silviu Ilie pentru comunitatea LOMP Stack**

*"Din experiență în dezvoltare enterprise, pentru toată lumea."*
