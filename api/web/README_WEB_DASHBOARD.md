# LOMP Stack v3.0 - Web Administration Dashboard

## Overvie

Interfața web de administrare pentru LOMP Stack v3.0 oferă o soluție modernă și ușor de folosit pentru gestionarea sistemului API. Dashboard-ul web înlocuiește interfața în linia de comandă cu o experiență grafică intuitivă.

## Caracteristici Principale

### 🔐 Autentificare Admin
- Sistem de login securizat pentru administratori
- Gestionarea sesiunilor cu expirare automată
- Protecție împotriva accesului neautorizat

### 🔑 Gestionarea Cheilor API
- Crearea de noi chei API cu permisiuni personalizate
- Vizualizarea și monitorizarea cheilor existente
- Revocarea cheilor API în timp real
- Setarea limitelor de trafic per cheie

### ⚙️ Configurare Sistem
- Editor pentru configurația API-ului
- Setări pentru rate limiting și securitate
- Configurarea politicilor CORS
- Gestionarea setărilor de logging

### 📊 Monitorizare în Timp Real
- Statistici sistem (CPU, RAM, disk)
- Grafice interactive cu Chart.js
- Numărul de request-uri API
- Chei API active și inactive

### 📋 Vizualizare Log-uri
- Afișarea log-urilor aplicației în timp real
- Filtrare și căutare în log-uri
- Export și download log-uri

### 🎨 Interfață Modernă
- Design responsive cu Bootstrap 5
- Sidebar navigare intuitiv
- Tema dark/light
- Iconuri Font Awesome

## Instalare și Configurare

### Prerequizite

1. **Python 3.7+** instalat pe sistem
2. **pip** pentru gestionarea pachetelor Python
3. **PowerShell** pentru Windows (sau bash pentru Linux/macOS)

### Instalare Automată

```powershell
# Navigare în directorul web
cd "c:\Users\Silviu\Desktop\Stack\api\web"

# Instalare dependențe
.\dashboard.ps1 install

# Pornire dashboard
.\dashboard.ps1 start
```

### Instalare Manuală

```bash
# Instalare dependențe Python
pip install -r requirements.txt

# Pornire aplicație
python admin_dashboard.py
```

## Utilizare

### 1. Accesarea Dashboard-ului

După pornirea aplicației, accesează:
- **URL Local**: http://localhost:5000
- **URL Rețea**: http://[IP_LOCAL]:5000

### 2. Login Administrator

**Credențiale implicite:**
- Username: `admin`
- Password: `admin123`

⚠️ **IMPORTANT**: Schimbă parola implicită după primul login!

### 3. Funcționalități Principale

#### Dashboard Principal
- Statistici sistem în timp real
- Grafice interactive
- Rezumat activitate API

#### Gestionare Chei API
1. **Creare Cheie Nouă**:
   ```
   Nume: "Frontend App"
   Permisiuni: ["read", "write"]
   Rate Limit: 1000 requests/hour
   ```

2. **Revocare Cheie**:
   - Click pe butonul "Revoke" lângă cheia dorită
   - Confirmă acțiunea

#### Configurare API
```json
{
  "rate_limiting": {
    "enabled": true,
    "default_limit": 100,
    "burst_limit": 200
  },
  "security": {
    "require_https": false,
    "cors_enabled": true,
    "allowed_origins": ["*"]
  }
}
```

#### Monitorizare Sistem
- CPU Usage: Grafic în timp real
- Memory Usage: Procentaj utilizare RAM
- API Requests: Numărul total de request-uri
- Active Keys: Chei API active

## API Endpoints

Dashboard-ul expune următoarele endpoint-uri pentru integrare:

### Autentificare
```http
POST /login
Content-Type: application/x-www-form-urlencoded

username=admin&password=admin123
```

### Gestionare Chei API
```http
# Creare cheie nouă
POST /api/keys
Content-Type: application/json

{
  "name": "New API Key",
  "permissions": ["read", "write"],
  "rate_limit": 100
}

# Ștergere cheie
DELETE /api/keys/{api_key}
```

### Configurare
```http
# Obținere configurație
GET /api/config

# Actualizare configurație
POST /api/config
Content-Type: application/json

{
  "rate_limiting": {
    "enabled": true,
    "default_limit": 100
  }
}
```

### Statistici
```http
# Statistici sistem
GET /api/stats

Response:
{
  "cpu_usage": 45.2,
  "memory_usage": 67.8,
  "disk_usage": 32.1,
  "api_requests": 1547,
  "active_keys": 5
}
```

### Log-uri
```http
# Obținere log-uri
GET /api/logs

Response:
{
  "logs": [
    "2025-01-01 10:00:00 INFO: API Server started",
    "2025-01-01 10:01:00 INFO: New API key created"
  ]
}
```

## Securitate

### Măsuri de Securitate Implementate

1. **Autentificare Sesiuni**
   - Hash-uri SHA-256 pentru parole
   - Token-uri de sesiune securizate
   - Expirare automată după 24 ore

2. **Rate Limiting**
   - Protecție împotriva spam-ului
   - Limite configurabile per endpoint

3. **Validare Input**
   - Sanitizarea datelor de intrare
   - Protecție împotriva SQL injection

### Recomandări Securitate

1. **Schimbă parola implicită** imediat după instalare
2. **Folosește HTTPS** în producție
3. **Configurează firewall** pentru portul 5000
4. **Monitorizează log-urile** regulat
5. **Actualizează dependențele** periodic

## Personalizare

### Modificare Port și Host

```powershell
# Pornire pe port personalizat
.\dashboard.ps1 -Action start -Port 8080

# Pornire pe host specific
.\dashboard.ps1 -Action start -HostAddress "192.168.1.100"
```

### Personalizare Template-uri

Template-urile HTML se află în:
```
api/web/templates/
├── base.html          # Layout principal
├── login.html         # Pagina de login
├── dashboard.html     # Dashboard principal
├── api_keys.html      # Gestionare chei API
├── configuration.html # Configurare sistem
├── monitoring.html    # Monitorizare
└── logs.html         # Vizualizare log-uri
```

### Modificare Stiluri CSS

Stilurile pot fi personalizate prin editarea fișierelor template sau prin adăugarea de fișiere CSS personalizate în directorul `static/`.

## Troubleshooting

### Probleme Comune

1. **Dashboard nu pornește**
   ```bash
   # Verifică dacă Python este instalat
   python --version
   
   # Verifică dependențele
   pip list | grep Flask
   ```

2. **Eroare la accesarea paginii**
   ```bash
   # Verifică dacă portul este ocupat
   netstat -an | findstr :5000
   ```

3. **Probleme cu autentificarea**
   ```bash
   # Resetează baza de date admin
   rm api/web/admin.db
   python admin_dashboard.py
   ```

### Log-uri Debug

Pentru depanare, activează modul debug:
```python
app.run(debug=True, host='0.0.0.0', port=5000)
```

## Dezvoltare și Contribuții

### Structura Proiectului

```
api/web/
├── admin_dashboard.py     # Aplicația Flask principală
├── dashboard.ps1          # Script de lansare PowerShell
├── dashboard.sh           # Script de lansare Bash
├── requirements.txt       # Dependențe Python
├── templates/             # Template-uri HTML
│   ├── base.html
│   ├── login.html
│   ├── dashboard.html
│   └── ...
└── static/               # Fișiere statice (CSS, JS, imagini)
```

### Adăugare Funcționalități Noi

1. **Adaugă rută nouă**:
```python
@app.route('/new-feature')
@require_auth
def new_feature():
    return render_template('new_feature.html')
```

2. **Creează template**:
```html
{% extends "base.html" %}
{% block content %}
<h1>Funcționalitate Nouă</h1>
{% endblock %}
```

3. **Adaugă în navigare**:
Editează `base.html` și adaugă link-ul în sidebar.

## Performance și Scalabilitate

### Optimizări

1. **Cache pentru configurații**
2. **Conexiuni database persistente**
3. **Compresie pentru asset-uri statice**
4. **Load balancing pentru multiple instanțe**

### Recomandări Producție

1. **Folosește un server WSGI** (Gunicorn, uWSGI)
2. **Configurează reverse proxy** (Nginx, Apache)
3. **Implementează SSL/TLS**
4. **Monitorizează performanța**

## Support și Documentație

### Resurse Utile

- **Documentație Flask**: https://flask.palletsprojects.com/
- **Bootstrap Components**: https://getbootstrap.com/docs/5.1/
- **Chart.js Documentation**: https://www.chartjs.org/docs/
- **Font Awesome Icons**: https://fontawesome.com/icons

### Contact și Suport

Pentru întrebări sau probleme:
1. Verifică secțiunea Troubleshooting
2. Consultă log-urile aplicației
3. Creează un issue în repository-ul proiectului

---

**LOMP Stack v3.0** - Sistem modern de gestionare API cu interfață web
*Dezvoltat pentru ușurință în utilizare și performanță maximă*
