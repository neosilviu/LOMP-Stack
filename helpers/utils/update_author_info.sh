#!/bin/bash
#
# update_author_info.sh - Script pentru actualizarea informațiilor despre autor în toate fișierele
# Part of LOMP Stack v3.0
#
# Author: Silviu Ilie <neosilviu@gmail.com>
# Company: aemdPC
# Version: 3.0.0
# Copyright © 2025 aemdPC. All rights reserved.
# License: MIT License
#
# Repository: https://github.com/aemdPC/lomp-stack-v3
# Documentation: https://docs.aemdpc.com/lomp-stack
# Support: https://support.aemdpc.com
#

# Încarcă informațiile despre autor
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/author_info.sh"

# Culori pentru output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funcție pentru logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Funcție pentru actualizarea fișierelor bash
update_bash_files() {
    log_info "Actualizez fișierele bash cu informațiile despre autor..."
    
    # Găsește toate fișierele .sh
    find "$STACK_ROOT" -name "*.sh" -type f | while read -r file; do
        # Verifică dacă fișierul nu conține deja informațiile despre autor
        if ! grep -q "Author: $AUTHOR_NAME" "$file"; then
            # Verifică dacă fișierul începe cu shebang
            if head -n 1 "$file" | grep -q "^#!/bin/bash"; then
                log_info "Actualizez: $file"
                
                # Creează un fișier temporar cu header-ul nou
                temp_file=$(mktemp)
                
                # Extrage numele și descrierea fișierului
                filename=$(basename "$file")
                description="Part of LOMP Stack v3.0"
                
                # Generează header-ul nou
                generate_script_header "$filename" "$description" > "$temp_file"
                
                # Adaugă conținutul original (sărind peste primul shebang)
                tail -n +2 "$file" >> "$temp_file"
                
                # Înlocuiește fișierul original
                if cp "$temp_file" "$file"; then
                    log_success "Actualizat: $file"
                else
                    log_error "Eroare la actualizarea: $file"
                fi
                
                # Curăță fișierul temporar
                rm -f "$temp_file"
            fi
        else
            log_info "Deja actualizat: $file"
        fi
    done
}

# Funcție pentru actualizarea fișierelor Python
update_python_files() {
    log_info "Actualizez fișierele Python cu informațiile despre autor..."
    
    # Găsește toate fișierele .py
    find "$STACK_ROOT" -name "*.py" -type f | while read -r file; do
        # Verifică dacă fișierul nu conține deja informațiile despre autor
        if ! grep -q "Author: $AUTHOR_NAME" "$file"; then
            # Verifică dacă fișierul începe cu shebang Python
            if head -n 1 "$file" | grep -q "^#!/.*python"; then
                log_info "Actualizez: $file"
                
                # Creează un fișier temporar cu header-ul nou
                temp_file=$(mktemp)
                
                # Extrage numele și descrierea fișierului
                filename=$(basename "$file")
                description="Part of LOMP Stack v3.0"
                
                # Generează header-ul nou
                generate_python_header "$filename" "$description" > "$temp_file"
                
                # Adaugă conținutul original (sărind peste primul shebang și docstring-ul vechi)
                skip_lines=1
                if head -n 2 "$file" | tail -n 1 | grep -q '"""'; then
                    # Caută sfârșitul docstring-ului
                    skip_lines=$(awk '/^"""/{if(++count==2) {print NR; exit}}' "$file")
                    if [ -z "$skip_lines" ]; then
                        skip_lines=1
                    fi
                fi
                
                tail -n +$((skip_lines + 1)) "$file" >> "$temp_file"
                
                # Înlocuiește fișierul original
                if cp "$temp_file" "$file"; then
                    log_success "Actualizat: $file"
                else
                    log_error "Eroare la actualizarea: $file"
                fi
                
                # Curăță fișierul temporar
                rm -f "$temp_file"
            fi
        else
            log_info "Deja actualizat: $file"
        fi
    done
}

# Funcție pentru actualizarea fișierelor HTML
update_html_files() {
    log_info "Actualizez fișierele HTML cu informațiile despre autor..."
    
    # Găsește toate fișierele .html din templates
    find "$STACK_ROOT/api/web/templates" -name "*.html" -type f 2>/dev/null | while read -r file; do
        # Verifică dacă fișierul nu conține deja informațiile despre autor
        if ! grep -q "Author: $AUTHOR_NAME" "$file"; then
            log_info "Actualizez: $file"
            
            # Creează un fișier temporar cu comentariul de autor
            temp_file=$(mktemp)
            
            # Adaugă comentariul de autor la început
            cat > "$temp_file" << EOF
<!--
LOMP Stack v3.0 Template
Author: $AUTHOR_NAME <$AUTHOR_EMAIL>
Company: $AUTHOR_COMPANY
Copyright © $COPYRIGHT_YEAR $AUTHOR_COMPANY. All rights reserved.
-->
EOF
            
            # Adaugă conținutul original
            cat "$file" >> "$temp_file"
            
            # Înlocuiește fișierul original
            if cp "$temp_file" "$file"; then
                log_success "Actualizat: $file"
            else
                log_error "Eroare la actualizarea: $file"
            fi
            
            # Curăță fișierul temporar
            rm -f "$temp_file"
        else
            log_info "Deja actualizat: $file"
        fi
    done
}

# Funcție pentru crearea fișierelor de licență și informații
create_license_files() {
    log_info "Creez fișierele de licență și informații..."
    
    # Creează fișierul LICENSE
    cat > "$STACK_ROOT/LICENSE" << EOF
MIT License

Copyright (c) $COPYRIGHT_YEAR $AUTHOR_COMPANY

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    
    log_success "Creat: $STACK_ROOT/LICENSE"
    
    # Creează fișierul AUTHORS
    cat > "$STACK_ROOT/AUTHORS" << EOF
# LOMP Stack v3.0 Authors

## Lead Developer & System Architect
- **$AUTHOR_NAME** <$AUTHOR_EMAIL>
  - Company: $AUTHOR_COMPANY
  - Role: Lead Developer & System Architect
  - Responsibilities: Overall project architecture, core development, hosting control panel

## Contributors
- Community contributors (see GitHub contributors page)

## Contact
For questions about authorship or contribution guidelines, contact:
- Email: $AUTHOR_EMAIL
- Support: $SUPPORT_URL

## Acknowledgments
Special thanks to the open-source community and all users who have provided feedback and contributions.
EOF
    
    log_success "Creat: $STACK_ROOT/AUTHORS"
    
    # Creează fișierul CHANGELOG
    cat > "$STACK_ROOT/CHANGELOG.md" << EOF
# Changelog - LOMP Stack v3.0

All notable changes to this project will be documented in this file.

## [3.0.0] - 2025-07-02

### Added
- Complete hosting control panel with modern web interface
- Python applications support (Flask, Django, FastAPI)
- Git-based deployment system
- Advanced database management
- Multi-site hosting capabilities
- SSL automation with Let's Encrypt
- Performance monitoring and metrics
- Backup and recovery system
- Security hardening features
- WordPress management integration
- Helper scripts integration layer
- Comprehensive documentation

### Enhanced
- Improved installation process with better error handling
- Enhanced security with firewall and fail2ban integration
- Better logging and debugging capabilities
- Modular architecture for easier maintenance
- Cross-platform compatibility (Windows development, Linux production)

### Technical Improvements
- RESTful API for all hosting operations
- SQLite databases for configuration management
- Systemd integration for service management
- Nginx reverse proxy configurations
- Redis caching and session management
- Environment variables management
- Dependency management for Python applications

---

**Developed by $AUTHOR_NAME at $AUTHOR_COMPANY**
EOF
    
    log_success "Creat: $STACK_ROOT/CHANGELOG.md"
}

# Funcție pentru afișarea statisticilor
show_statistics() {
    log_info "Statistici despre fișierele actualizate:"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Numără fișierele bash
    bash_files=$(find "$STACK_ROOT" -name "*.sh" -type f | wc -l)
    bash_updated=$(find "$STACK_ROOT" -name "*.sh" -type f -exec grep -l "Author: $AUTHOR_NAME" {} \; | wc -l)
    echo "📜 Fișiere Bash: $bash_updated/$bash_files actualizate"
    
    # Numără fișierele Python
    python_files=$(find "$STACK_ROOT" -name "*.py" -type f | wc -l)
    python_updated=$(find "$STACK_ROOT" -name "*.py" -type f -exec grep -l "Author: $AUTHOR_NAME" {} \; | wc -l)
    echo "🐍 Fișiere Python: $python_updated/$python_files actualizate"
    
    # Numără fișierele HTML
    html_files=$(find "$STACK_ROOT/api/web/templates" -name "*.html" -type f 2>/dev/null | wc -l)
    html_updated=$(find "$STACK_ROOT/api/web/templates" -name "*.html" -type f -exec grep -l "Author: $AUTHOR_NAME" {} \; 2>/dev/null | wc -l)
    echo "🌐 Fișiere HTML: $html_updated/$html_files actualizate"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Verifică dacă există fișierele de documentație
    if [ -f "$STACK_ROOT/README.md" ]; then
        echo "✅ README.md - prezent"
    else
        echo "❌ README.md - lipsește"
    fi
    
    if [ -f "$STACK_ROOT/LICENSE" ]; then
        echo "✅ LICENSE - prezent"
    else
        echo "❌ LICENSE - lipsește"
    fi
    
    if [ -f "$STACK_ROOT/AUTHORS" ]; then
        echo "✅ AUTHORS - prezent"
    else
        echo "❌ AUTHORS - lipsește"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Funcția principală
main() {
    # Detectează directorul root al stack-ului
    STACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "               ACTUALIZARE INFORMAȚII AUTOR - LOMP Stack v3.0                 "
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    show_author_info
    echo ""
    echo "Stack Root: $STACK_ROOT"
    echo ""
    
    # Confirmă actualizarea
    read -p "Dorești să actualizezi toate fișierele cu informațiile despre autor? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Începe actualizarea..."
        
        # Actualizează fișierele
        update_bash_files
        update_python_files
        update_html_files
        create_license_files
        
        echo ""
        log_success "Actualizarea completă!"
        echo ""
        
        # Afișează statisticile
        show_statistics
        
        echo ""
        show_support_info
    else
        log_info "Actualizarea a fost anulată."
    fi
}

# Rulează doar dacă scriptul este executat direct
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
