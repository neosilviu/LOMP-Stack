#!/bin/bash
#
# author_info.sh - Part of LOMP Stack v3.0
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
# author_info.sh - Informații despre autor și configurare pentru LOMP Stack v3.0

# Informații despre autor
readonly AUTHOR_NAME="Silviu Ilie"
readonly AUTHOR_EMAIL="neosilviu@gmail.com"
readonly AUTHOR_COMPANY="aemdPC"
readonly AUTHOR_ROLE="Lead Developer & System Architect"
readonly PROJECT_NAME="LOMP Stack v3.0"
readonly PROJECT_VERSION="3.0.0"
readonly PROJECT_DESCRIPTION="Complete Linux OpenLiteSpeed MySQL/MariaDB PHP Stack with Advanced Hosting Control Panel"
readonly COPYRIGHT_YEAR="2025"
readonly LICENSE="MIT License"
readonly REPOSITORY_URL="https://github.com/aemdPC/lomp-stack-v3"
readonly DOCUMENTATION_URL="https://docs.aemdpc.com/lomp-stack"
readonly SUPPORT_URL="https://support.aemdpc.com"

# Export variabilele pentru utilizare globală
export AUTHOR_NAME AUTHOR_EMAIL AUTHOR_COMPANY AUTHOR_ROLE
export PROJECT_NAME PROJECT_VERSION PROJECT_DESCRIPTION
export COPYRIGHT_YEAR LICENSE REPOSITORY_URL
export DOCUMENTATION_URL SUPPORT_URL

# Funcție pentru afișarea informațiilor despre autor
show_author_info() {
    cat << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                            LOMP Stack v3.0                                  ║
║                     Advanced Hosting Control Panel                          ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Author:     $AUTHOR_NAME                                                ║
║ Email:      $AUTHOR_EMAIL                                        ║
║ Company:    $AUTHOR_COMPANY                                                     ║
║ Role:       $AUTHOR_ROLE                           ║
║ Version:    $PROJECT_VERSION                                                    ║
║ Copyright:  © $COPYRIGHT_YEAR $AUTHOR_COMPANY. All rights reserved.           ║
║ License:    $LICENSE                                                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Repository: $REPOSITORY_URL                     ║
║ Docs:       $DOCUMENTATION_URL                        ║
║ Support:    $SUPPORT_URL                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Funcție pentru generarea header-ului pentru fișiere script
generate_script_header() {
    local script_name="$1"
    local script_description="$2"
    
    cat << EOF
#!/bin/bash
#
# $script_name - $script_description
# Part of $PROJECT_NAME
#
# Author: $AUTHOR_NAME <$AUTHOR_EMAIL>
# Company: $AUTHOR_COMPANY
# Version: $PROJECT_VERSION
# Copyright © $COPYRIGHT_YEAR $AUTHOR_COMPANY. All rights reserved.
# License: $LICENSE
#
# Repository: $REPOSITORY_URL
# Documentation: $DOCUMENTATION_URL
# Support: $SUPPORT_URL
#
EOF
}

# Funcție pentru generarea header-ului pentru fișiere Python
generate_python_header() {
    local script_name="$1"
    local script_description="$2"
    
    cat << EOF
#!/usr/bin/env python3
"""
$script_name - $script_description
Part of $PROJECT_NAME

Author: $AUTHOR_NAME <$AUTHOR_EMAIL>
Company: $AUTHOR_COMPANY
Version: $PROJECT_VERSION
Copyright © $COPYRIGHT_YEAR $AUTHOR_COMPANY. All rights reserved.
License: $LICENSE

Repository: $REPOSITORY_URL
Documentation: $DOCUMENTATION_URL
Support: $SUPPORT_URL
"""

EOF
}

# Funcție pentru generarea footer-ului pentru log-uri
generate_log_footer() {
    echo ""
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo "LOMP Stack v$PROJECT_VERSION by $AUTHOR_NAME ($AUTHOR_COMPANY)"
    echo "For support and documentation: $SUPPORT_URL"
    echo "────────────────────────────────────────────────────────────────────────────────"
}

# Funcție pentru afișarea informațiilor de suport
show_support_info() {
    cat << EOF

═══════════════════════════════════════════════════════════════════════════════
                            SUPPORT & CONTACT
═══════════════════════════════════════════════════════════════════════════════
 
For technical support and inquiries:
• Author:        $AUTHOR_NAME
• Email:         $AUTHOR_EMAIL
• Company:       $AUTHOR_COMPANY
• Documentation: $DOCUMENTATION_URL
• Support:       $SUPPORT_URL
• Repository:    $REPOSITORY_URL

If you encounter any issues or need assistance with LOMP Stack v3.0,
please don't hesitate to reach out through any of the channels above.

═══════════════════════════════════════════════════════════════════════════════
EOF
}

# Funcție pentru generarea unui fișier README cu informații complete
generate_project_readme() {
    local output_file="${1:-README.md}"
    
    cat > "$output_file" << EOF
# $PROJECT_NAME

$PROJECT_DESCRIPTION

## Author Information

- **Author:** $AUTHOR_NAME
- **Email:** $AUTHOR_EMAIL
- **Company:** $AUTHOR_COMPANY
- **Role:** $AUTHOR_ROLE

## Project Details

- **Version:** $PROJECT_VERSION
- **License:** $LICENSE
- **Copyright:** © $COPYRIGHT_YEAR $AUTHOR_COMPANY

## Links

- **Repository:** $REPOSITORY_URL
- **Documentation:** $DOCUMENTATION_URL
- **Support:** $SUPPORT_URL

## About LOMP Stack v3.0

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

## Features

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

## Installation

\`\`\`bash
# Clone the repository
git clone $REPOSITORY_URL
cd lomp-stack-v3

# Run the installation
sudo ./install.sh
\`\`\`

## Quick Start

1. **Access the Control Panel:** http://your-server-ip:5000
2. **Default credentials:** admin / (generated during installation)
3. **Create your first site:** Use the Sites management section
4. **Deploy Python apps:** Use the Python Applications section
5. **Install WordPress:** Use the WordPress management section

## Documentation

Complete documentation is available at: $DOCUMENTATION_URL

## Support

For technical support:
- **Email:** $AUTHOR_EMAIL
- **Support Portal:** $SUPPORT_URL
- **Issues:** $REPOSITORY_URL/issues

## License

This project is licensed under the $LICENSE.

Copyright © $COPYRIGHT_YEAR $AUTHOR_COMPANY. All rights reserved.

## Contributing

We welcome contributions! Please see our contributing guidelines and feel free to submit pull requests.

## Acknowledgments

Special thanks to the open-source community and all contributors who have made this project possible.

---

**Developed with ❤️ by $AUTHOR_NAME at $AUTHOR_COMPANY**
EOF
    
    echo "Project README generated: $output_file"
}

# Export funcțiile pentru utilizare globală
export -f show_author_info generate_script_header generate_python_header
export -f generate_log_footer show_support_info generate_project_readme
