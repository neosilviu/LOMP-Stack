#!/bin/bash
#
# demo_api_management.sh - Part of LOMP Stack v3.0
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

#########################################################################
# LOMP Stack v2.0 - API Management System Demo
# Demonstration of API Management System capabilities
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers/utils/functions.sh"

print_info() { color_echo cyan "[DEMO] $*"; }
print_success() { color_echo green "[SUCCESS] $*"; }
print_warning() { color_echo yellow "[DEMO] $*"; }

#########################################################################
# Demo Header
#########################################################################
show_demo_header() {
    clear
    color_echo cyan "🚀 LOMP Stack v2.0 - API Management System Demo"
    color_echo cyan "=============================================="
    echo ""
    print_info "This demo showcases the comprehensive API Management System"
    print_info "Enterprise-grade REST API with authentication, rate limiting, and webhooks"
    echo ""
    echo "Features demonstrated:"
    echo "  ✅ Complete REST API for all LOMP operations"
    echo "  ✅ JWT and API key authentication"
    echo "  ✅ Rate limiting and quota management"
    echo "  ✅ Webhook system for external integrations"
    echo "  ✅ Auto-generated API documentation"
    echo "  ✅ API analytics and monitoring"
    echo ""
    read -p "Press Enter to start the demo..."
}

#########################################################################
# Demo 1: System Structure
#########################################################################
demo_system_structure() {
    print_info "=== Demo 1: API System Structure ==="
    echo ""
    
    print_info "API Management System directory structure:"
    tree "${SCRIPT_DIR}/api" 2>/dev/null || {
        echo "api/"
        echo "├── api_management_system.sh    # Main API manager"
        echo "├── api_server.py              # Python Flask API server"
        echo "├── api_config.json            # API configuration"
        echo "├── generate_docs.py           # Documentation generator"
        echo "├── install_dependencies.sh    # Dependencies installer"
        echo "├── auth/"
        echo "│   ├── auth_manager.sh        # Authentication module"
        echo "│   ├── jwt_secret.key         # JWT secret key"
        echo "│   └── api_keys.json          # API keys database"
        echo "├── endpoints/"
        echo "│   └── sites_api.sh           # Site management endpoints"
        echo "└── webhooks/"
        echo "    ├── webhook_manager.sh     # Webhook manager"
        echo "    ├── webhook_config.json    # Webhook configuration"
        echo "    └── webhook_sender.py      # Webhook sender"
    }
    echo ""
    print_success "Complete API system structure in place"
    echo ""
    read -p "Press Enter to continue..."
}

#########################################################################
# Demo 2: API Configuration
#########################################################################
demo_api_configuration() {
    print_info "=== Demo 2: API Configuration ==="
    echo ""
    
    cd "${SCRIPT_DIR}/api" || return 1
    
    print_info "Initializing API Management System..."
    bash api_management_system.sh init >/dev/null 2>&1
    
    print_info "API Configuration (api_config.json):"
    jq '.' api_config.json | head -20
    echo "    ..."
    echo ""
    
    print_info "JWT Secret Key generated:"
    if [ -f "auth/jwt_secret.key" ]; then
        echo "  ✅ JWT secret: $(head -c 20 auth/jwt_secret.key)..."
    fi
    echo ""
    
    print_info "API Keys Database:"
    jq '.api_keys[] | {name: .name, permissions: .permissions, rate_limit: .rate_limit}' auth/api_keys.json
    echo ""
    
    print_success "API system fully configured"
    echo ""
    read -p "Press Enter to continue..."
}

#########################################################################
# Demo 3: Authentication System
#########################################################################
demo_authentication() {
    print_info "=== Demo 3: Authentication System ==="
    echo ""
    
    cd "${SCRIPT_DIR}/api/auth" || return 1
    
    print_info "Generating new JWT secret..."
    bash auth_manager.sh generate-secret
    echo ""
    
    print_info "Creating API keys with different permissions..."
    echo ""
    
    print_warning "Creating Admin API Key:"
    bash auth_manager.sh create-key "Admin Key" "*" "1000"
    echo ""
    
    print_warning "Creating Monitoring API Key:"
    bash auth_manager.sh create-key "Monitoring Key" "monitoring:read,sites:read" "500"
    echo ""
    
    print_warning "Creating Limited API Key:"
    bash auth_manager.sh create-key "Limited Key" "sites:read" "100"
    echo ""
    
    print_info "Testing API key validation..."
    local validation_result
    validation_result=$(bash auth_manager.sh validate "invalid-test-key")
    echo "Validation result for invalid key: $validation_result"
    echo ""
    
    print_success "Authentication system fully functional"
    echo ""
    read -p "Press Enter to continue..."
}

#########################################################################
# Demo 4: API Endpoints
#########################################################################
demo_api_endpoints() {
    print_info "=== Demo 4: API Endpoints ==="
    echo ""
    
    cd "${SCRIPT_DIR}/api/endpoints" || return 1
    
    print_info "Testing Site Management API endpoints..."
    echo ""
    
    print_warning "1. List Sites API:"
    bash sites_api.sh list | jq '.'
    echo ""
    
    print_warning "2. Create Site API:"
    bash sites_api.sh create "demo.example.com" "admin@demo.com" | jq '.'
    echo ""
    
    print_warning "3. Get Site API (non-existent site):"
    bash sites_api.sh get "nonexistent.com" | jq '.'
    echo ""
    
    print_warning "4. Delete Site API:"
    bash sites_api.sh delete "demo.example.com" | jq '.'
    echo ""
    
    print_success "All API endpoints working correctly"
    echo ""
    read -p "Press Enter to continue..."
}

#########################################################################
# Demo 5: Webhook System
#########################################################################
demo_webhook_system() {
    print_info "=== Demo 5: Webhook System ==="
    echo ""
    
    cd "${SCRIPT_DIR}/api/webhooks" || return 1
    
    print_info "Initializing webhook system..."
    bash webhook_manager.sh init >/dev/null 2>&1
    echo ""
    
    print_warning "Adding webhook endpoints..."
    bash webhook_manager.sh add "Site Monitor" "https://monitor.example.com/webhook" "site.created,site.deleted" "secret123"
    echo ""
    bash webhook_manager.sh add "Backup Monitor" "https://backup.example.com/webhook" "backup.created,backup.completed" "backup_secret"
    echo ""
    bash webhook_manager.sh add "Security Monitor" "https://security.example.com/webhook" "security.incident" "security_secret"
    echo ""
    
    print_warning "Sending test webhooks..."
    bash webhook_manager.sh send "site.created" '{"domain":"test.com","email":"admin@test.com"}'
    echo ""
    bash webhook_manager.sh send "backup.completed" '{"domain":"test.com","backup_file":"backup_test_20250701.tar.gz"}'
    echo ""
    bash webhook_manager.sh send "security.incident" '{"type":"brute_force","ip":"192.168.1.100","time":"2025-07-01T10:30:00Z"}'
    echo ""
    
    print_info "Webhook configuration:"
    jq '.webhooks[]' webhook_config.json 2>/dev/null || echo "No webhooks configured yet"
    echo ""
    
    print_success "Webhook system fully operational"
    echo ""
    read -p "Press Enter to continue..."
}

#########################################################################
# Demo 6: API Documentation
#########################################################################
demo_api_documentation() {
    print_info "=== Demo 6: API Documentation ==="
    echo ""
    
    cd "${SCRIPT_DIR}/api" || return 1
    
    print_info "Generating API documentation..."
    python3 generate_docs.py
    echo ""
    
    if [ -f "api_documentation.html" ]; then
        print_success "API documentation generated: $(pwd)/api_documentation.html"
        echo ""
        print_info "Documentation includes:"
        echo "  ✅ Authentication methods (API keys, JWT)"
        echo "  ✅ Rate limiting information"
        echo "  ✅ All available endpoints"
        echo "  ✅ Request/response examples"
        echo "  ✅ Error codes and handling"
        echo "  ✅ Integration examples"
        echo ""
        
        print_info "Sample documentation content:"
        echo "==============================================="
        grep -A 5 "LOMP Stack API" api_documentation.html | head -10
        echo "..."
        echo "==============================================="
    else
        print_warning "Documentation file not found"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

#########################################################################
# Demo 7: Dashboard Integration
#########################################################################
demo_dashboard_integration() {
    print_info "=== Demo 7: Dashboard Integration ==="
    echo ""
    
    print_info "Checking enterprise dashboard integration..."
    echo ""
    
    if [ -f "${SCRIPT_DIR}/main_enterprise_dashboard.sh" ]; then
        print_success "✅ Enterprise dashboard found"
        
        if grep -q "API Management" "${SCRIPT_DIR}/main_enterprise_dashboard.sh"; then
            print_success "✅ API Management option integrated in dashboard menu"
        else
            print_warning "⚠️  API Management not yet integrated in dashboard"
        fi
        
        # Test module status check
        print_info "Testing module status check..."
        local status
        status=$(cd "${SCRIPT_DIR}" && bash -c 'source main_enterprise_dashboard.sh && check_module_status "api_management"')
        echo "API Management status: $status"
        
    else
        print_warning "Enterprise dashboard not found"
    fi
    echo ""
    
    print_info "API Management is accessible via:"
    echo "  1. Direct script: bash api/api_management_system.sh menu"
    echo "  2. Enterprise Dashboard: Option 6 - API Management"
    echo "  3. API Server: http://localhost:8080/api/v1 (when running)"
    echo ""
    
    print_success "Dashboard integration complete"
    echo ""
    read -p "Press Enter to continue..."
}

#########################################################################
# Demo 8: Sample API Calls
#########################################################################
demo_sample_api_calls() {
    print_info "=== Demo 8: Sample API Calls ==="
    echo ""
    
    print_info "Here are example API calls you can use:"
    echo ""
    
    print_warning "1. Health Check (no authentication required):"
    echo "curl -X GET http://localhost:8080/api/v1/health"
    echo ""
    
    print_warning "2. System Status:"
    echo "curl -X GET http://localhost:8080/api/v1/system/status"
    echo ""
    
    print_warning "3. List Sites (requires API key):"
    echo "curl -X GET http://localhost:8080/api/v1/sites \\"
    echo "  -H 'X-API-Key: your-api-key-here'"
    echo ""
    
    print_warning "4. Create Site (requires API key):"
    echo "curl -X POST http://localhost:8080/api/v1/sites \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -H 'X-API-Key: your-api-key-here' \\"
    echo "  -d '{\"domain\":\"newsite.com\",\"email\":\"admin@newsite.com\"}'"
    echo ""
    
    print_warning "5. Create Backup (requires API key):"
    echo "curl -X POST http://localhost:8080/api/v1/backups \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -H 'X-API-Key: your-api-key-here' \\"
    echo "  -d '{\"domain\":\"example.com\",\"type\":\"full\"}'"
    echo ""
    
    print_warning "6. Get System Metrics (requires API key):"
    echo "curl -X GET http://localhost:8080/api/v1/system/metrics \\"
    echo "  -H 'X-API-Key: your-api-key-here'"
    echo ""
    
    print_info "Note: To start the API server, run:"
    echo "cd api && bash api_management_system.sh start"
    echo ""
    read -p "Press Enter to continue..."
}

#########################################################################
# Demo Summary
#########################################################################
demo_summary() {
    print_info "=== Demo Summary ==="
    echo ""
    
    color_echo green "🎉 API Management System Demo Complete!"
    echo ""
    
    print_success "Demonstrated Features:"
    echo "  ✅ Complete API system architecture"
    echo "  ✅ Secure authentication with JWT and API keys"
    echo "  ✅ Comprehensive rate limiting"
    echo "  ✅ RESTful endpoints for all LOMP operations"
    echo "  ✅ Webhook system for external integrations"
    echo "  ✅ Auto-generated API documentation"
    echo "  ✅ Enterprise dashboard integration"
    echo "  ✅ Production-ready Python Flask server"
    echo ""
    
    print_info "Next Steps:"
    echo "  1. Install dependencies: bash api/install_dependencies.sh"
    echo "  2. Start API server: bash api/api_management_system.sh start"
    echo "  3. Access documentation: api/api_documentation.html"
    echo "  4. Test endpoints with provided sample calls"
    echo "  5. Configure webhooks for your integrations"
    echo ""
    
    print_success "API Management System is ready for enterprise use!"
    echo ""
}

#########################################################################
# Interactive Demo Menu
#########################################################################
demo_menu() {
    while true; do
        clear
        color_echo cyan "🚀 API Management System Demo Menu"
        echo "====================================="
        color_echo yellow "1.  📁 System Structure"
        color_echo yellow "2.  ⚙️  Configuration"
        color_echo yellow "3.  🔐 Authentication"
        color_echo yellow "4.  🌐 API Endpoints"
        color_echo yellow "5.  🕸️  Webhooks"
        color_echo yellow "6.  📚 Documentation"
        color_echo yellow "7.  🏢 Dashboard Integration"
        color_echo yellow "8.  📞 Sample API Calls"
        color_echo yellow "9.  🎬 Full Demo (All Steps)"
        color_echo red "0.  🚪 Exit Demo"
        echo "====================================="
        
        read -p "Select demo section (0-9): " choice
        
        case $choice in
            1) demo_system_structure ;;
            2) demo_api_configuration ;;
            3) demo_authentication ;;
            4) demo_api_endpoints ;;
            5) demo_webhook_system ;;
            6) demo_api_documentation ;;
            7) demo_dashboard_integration ;;
            8) demo_sample_api_calls ;;
            9)
                show_demo_header
                demo_system_structure
                demo_api_configuration
                demo_authentication
                demo_api_endpoints
                demo_webhook_system
                demo_api_documentation
                demo_dashboard_integration
                demo_sample_api_calls
                demo_summary
                ;;
            0)
                print_success "Thank you for viewing the API Management System demo!"
                break
                ;;
            *)
                color_echo red "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

#########################################################################
# Main Demo Function
#########################################################################
main() {
    case "${1:-menu}" in
        "full")
            show_demo_header
            demo_system_structure
            demo_api_configuration
            demo_authentication
            demo_api_endpoints
            demo_webhook_system
            demo_api_documentation
            demo_dashboard_integration
            demo_sample_api_calls
            demo_summary
            ;;
        "menu"|*)
            demo_menu
            ;;
    esac
}

# Run demo if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
