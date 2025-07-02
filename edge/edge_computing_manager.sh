#!/bin/bash
#
# edge_computing_manager.sh - Part of LOMP Stack v3.0
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

# LOMP Stack - Edge Computing Manager
# Phase 5: Next Generation Features
# Advanced edge computing infrastructure management
# Version: 1.0.0

# Source required dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(dirname "$SCRIPT_DIR")"

source "$STACK_ROOT/helpers/utils/functions.sh"
source "$STACK_ROOT/helpers/utils/config_helpers.sh"
source "$STACK_ROOT/helpers/utils/notify_helpers.sh"
source "$STACK_ROOT/helpers/monitoring/system_helpers.sh"

# Edge Computing Configuration
EDGE_CONFIG_FILE="$SCRIPT_DIR/edge_config.json"
export EDGE_LOG_FILE="/var/log/lomp_edge_computing.log"
EDGE_DATA_DIR="/opt/lomp/edge"
EDGE_CACHE_DIR="$EDGE_DATA_DIR/cache"
EDGE_NODES_DIR="$EDGE_DATA_DIR/nodes"

# Edge Computing Functions

# Initialize edge computing environment
init_edge_computing() {
    log_message "INFO" "Initializing LOMP Edge Computing Manager..."
    
    # Create directories
    mkdir -p "$EDGE_DATA_DIR" "$EDGE_CACHE_DIR" "$EDGE_NODES_DIR"
    mkdir -p "/etc/lomp/edge" "/var/lib/lomp/edge"
    
    # Set permissions
    chmod 755 "$EDGE_DATA_DIR" "$EDGE_CACHE_DIR" "$EDGE_NODES_DIR"
    
    # Initialize configuration if not exists
    if [[ ! -f "$EDGE_CONFIG_FILE" ]]; then
        create_default_edge_config
    fi
    
    log_message "INFO" "Edge computing environment initialized successfully"
    return 0
}

# Create default edge configuration
create_default_edge_config() {
    cat > "$EDGE_CONFIG_FILE" << 'EOF'
{
  "edge_computing": {
    "version": "1.0.0",
    "cluster": {
      "name": "lomp-edge-cluster",
      "region": "default",
      "auto_scaling": true,
      "max_nodes": 10,
      "min_nodes": 2
    },
    "cdn": {
      "enabled": true,
      "provider": "nginx",
      "cache_size": "10GB",
      "ttl": 3600,
      "compression": true
    },
    "load_balancer": {
      "enabled": true,
      "algorithm": "round_robin",
      "health_check": true,
      "timeout": 30
    },
    "caching": {
      "enabled": true,
      "type": "redis",
      "memory_limit": "2GB",
      "eviction_policy": "allkeys-lru"
    },
    "security": {
      "ddos_protection": true,
      "rate_limiting": true,
      "ssl_termination": true,
      "waf_enabled": true
    },
    "monitoring": {
      "enabled": true,
      "metrics_retention": "30d",
      "alerting": true,
      "performance_tracking": true
    }
  }
}
EOF
    log_message "INFO" "Default edge configuration created"
}

# Install edge computing dependencies
install_edge_dependencies() {
    log_message "INFO" "Installing edge computing dependencies..."
    
    # Update package manager
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y nginx haproxy redis-server varnish fail2ban
    elif command -v yum &> /dev/null; then
        yum update -y
        yum install -y nginx haproxy redis varnish fail2ban
    fi
    
    # Install Node.js for edge functions
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # Install Docker for containerized edge services
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
    fi
    
    log_message "INFO" "Edge computing dependencies installed successfully"
}

# Configure CDN
configure_cdn() {
    local config_type=${1:-"nginx"}
    
    log_message "INFO" "Configuring CDN with $config_type..."
    
    case $config_type in
        "nginx")
            configure_nginx_cdn
            ;;
        "varnish")
            configure_varnish_cdn
            ;;
        *)
            log_message "ERROR" "Unsupported CDN type: $config_type"
            return 1
            ;;
    esac
    
    log_message "INFO" "CDN configuration completed"
}

# Configure Nginx CDN
configure_nginx_cdn() {
    cat > /etc/nginx/sites-available/edge-cdn << 'EOF'
server {
    listen 80;
    listen 443 ssl http2;
    
    server_name _;
    
    # SSL Configuration
    ssl_certificate /etc/ssl/certs/edge.crt;
    ssl_certificate_key /etc/ssl/private/edge.key;
    
    # Cache settings
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1M;
        add_header Cache-Control "public, immutable";
        add_header X-Cache-Status "HIT";
    }
    
    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache edge_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
    }
}

upstream backend_servers {
    least_conn;
    server 127.0.0.1:8080 weight=3;
    server 127.0.0.1:8081 weight=2;
    server 127.0.0.1:8082 weight=1;
}

proxy_cache_path /var/cache/nginx/edge levels=1:2 keys_zone=edge_cache:10m max_size=10g;
EOF

    ln -sf /etc/nginx/sites-available/edge-cdn /etc/nginx/sites-enabled/
    systemctl reload nginx
}

# Configure Varnish CDN
configure_varnish_cdn() {
    cat > /etc/varnish/default.vcl << 'EOF'
vcl 4.1;

backend default {
    .host = "127.0.0.1";
    .port = "8080";
    .probe = {
        .url = "/health";
        .timeout = 5s;
        .interval = 10s;
        .window = 5;
        .threshold = 3;
    }
}

sub vcl_recv {
    # Remove any Google Analytics cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "(__utm[a-z]+|_ga|_gat|_gid)=[^;]+(; )?", "");
    
    # Pass through POST, PUT, PATCH, DELETE
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }
    
    # Cache static content
    if (req.url ~ "\.(css|js|png|gif|jp?g|ico|svg|woff2?)$") {
        unset req.http.Cookie;
        return (hash);
    }
    
    return (hash);
}

sub vcl_backend_response {
    # Cache static content for 1 hour
    if (bereq.url ~ "\.(css|js|png|gif|jp?g|ico|svg|woff2?)$") {
        set beresp.ttl = 1h;
        set beresp.http.Cache-Control = "public, max-age=3600";
    }
    
    # Cache HTML for 5 minutes
    if (beresp.http.Content-Type ~ "text/html") {
        set beresp.ttl = 5m;
    }
    
    return (deliver);
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    
    set resp.http.X-Cache-Hits = obj.hits;
    
    return (deliver);
}
EOF

    systemctl restart varnish
}

# Setup load balancer
setup_load_balancer() {
    local algorithm=${1:-"roundrobin"}
    
    log_message "INFO" "Setting up load balancer with $algorithm algorithm..."
    
    cat > /etc/haproxy/haproxy.cfg << EOF
global
    daemon
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    
    # SSL/TLS configuration
    ssl-default-bind-ciphers ECDHE+AESGCM:ECDHE+CHACHA20:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    option dontlognull
    option http-server-close
    option forwardfor except 127.0.0.0/8
    option redispatch
    retries 3
    
    # Error pages
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend edge_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/edge.pem
    
    # Redirect HTTP to HTTPS
    redirect scheme https if !{ ssl_fc }
    
    # Rate limiting
    stick-table type ip size 100k expire 30s store http_req_rate(10s)
    http-request track-sc0 src
    http-request reject if { sc_http_req_rate(0) gt 20 }
    
    # Security headers
    http-response set-header X-Frame-Options SAMEORIGIN
    http-response set-header X-XSS-Protection "1; mode=block"
    http-response set-header X-Content-Type-Options nosniff
    
    default_backend edge_backend

backend edge_backend
    balance $algorithm
    option httpchk GET /health
    
    # Backend servers
    server edge1 127.0.0.1:8080 check weight 100
    server edge2 127.0.0.1:8081 check weight 100
    server edge3 127.0.0.1:8082 check weight 50 backup

# Statistics
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
EOF

    systemctl enable haproxy
    systemctl restart haproxy
    
    log_message "INFO" "Load balancer configured successfully"
}

# Configure edge caching
configure_edge_caching() {
    local cache_type=${1:-"redis"}
    
    log_message "INFO" "Configuring edge caching with $cache_type..."
    
    case $cache_type in
        "redis")
            configure_redis_cache
            ;;
        "memcached")
            configure_memcached_cache
            ;;
        *)
            log_message "ERROR" "Unsupported cache type: $cache_type"
            return 1
            ;;
    esac
    
    log_message "INFO" "Edge caching configured successfully"
}

# Configure Redis cache
configure_redis_cache() {
    cat > /etc/redis/redis-edge.conf << 'EOF'
# Redis Edge Cache Configuration
port 6379
bind 127.0.0.1
protected-mode yes
timeout 300
keepalive 300

# Memory configuration
maxmemory 2gb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Persistence
save 900 1
save 300 10
save 60 10000

# Performance tuning
tcp-keepalive 300
tcp-backlog 511
databases 16

# Logging
loglevel notice
logfile /var/log/redis/redis-edge.log

# Security
requirepass $(openssl rand -base64 32)
EOF

    systemctl enable redis-server
    systemctl restart redis-server
}

# Deploy edge functions
deploy_edge_function() {
    local function_name="$1"
    local function_code="$2"
    
    if [[ -z "$function_name" || -z "$function_code" ]]; then
        log_message "ERROR" "Function name and code are required"
        return 1
    fi
    
    log_message "INFO" "Deploying edge function: $function_name"
    
    local function_dir="$EDGE_DATA_DIR/functions/$function_name"
    mkdir -p "$function_dir"
    
    # Create function package
    cat > "$function_dir/index.js" << EOF
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Function code
$function_code

app.listen(port, () => {
    console.log(\`Edge function \${process.env.FUNCTION_NAME || '$function_name'} listening on port \${port}\`);
});
EOF

    # Create package.json
    cat > "$function_dir/package.json" << EOF
{
  "name": "$function_name",
  "version": "1.0.0",
  "description": "LOMP Stack Edge Function",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

    # Create Dockerfile
    cat > "$function_dir/Dockerfile" << EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

    # Build and deploy
    cd "$function_dir" || return 1
    docker build -t "edge-function-$function_name" .
    docker run -d --name "$function_name" -p "$(get_available_port):3000" \
        -e "FUNCTION_NAME=$function_name" \
        "edge-function-$function_name"
    
    log_message "INFO" "Edge function $function_name deployed successfully"
}

# Get available port
get_available_port() {
    local port=3000
    while netstat -ln | grep ":$port " > /dev/null 2>&1; do
        ((port++))
    done
    echo $port
}

# Monitor edge performance
monitor_edge_performance() {
    log_message "INFO" "Starting edge performance monitoring..."
    
    # Create monitoring script
    cat > "$EDGE_DATA_DIR/monitor.sh" << 'EOF'
#!/bin/bash

while true; do
    # CPU and Memory usage
    echo "$(date): CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%" >> /var/log/edge_performance.log
    echo "$(date): Memory: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')" >> /var/log/edge_performance.log
    
    # Network statistics
    echo "$(date): Network: $(cat /proc/net/dev | awk 'NR>2{rx+=$2; tx+=$10} END{printf "RX: %.2fMB TX: %.2fMB", rx/1024/1024, tx/1024/1024}')" >> /var/log/edge_performance.log
    
    # Cache hit rates
    if command -v redis-cli &> /dev/null; then
        CACHE_STATS=$(redis-cli info stats | grep -E "keyspace_hits|keyspace_misses")
        echo "$(date): Redis Cache: $CACHE_STATS" >> /var/log/edge_performance.log
    fi
    
    sleep 60
done
EOF

    chmod +x "$EDGE_DATA_DIR/monitor.sh"
    nohup "$EDGE_DATA_DIR/monitor.sh" &
    
    log_message "INFO" "Edge performance monitoring started"
}

# Show edge status
show_edge_status() {
    clear
    echo "==============================================="
    echo "        LOMP Edge Computing Status"
    echo "==============================================="
    echo
    
    # Service status
    echo "🔧 Service Status:"
    services=("nginx" "haproxy" "redis-server" "varnish" "docker")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "  ✅ $service: Running"
        else
            echo "  ❌ $service: Stopped"
        fi
    done
    echo
    
    # Edge nodes
    echo "🌐 Edge Nodes:"
    if [[ -d "$EDGE_NODES_DIR" ]]; then
        node_count=$(ls -1 "$EDGE_NODES_DIR" 2>/dev/null | wc -l)
        echo "  📍 Active Nodes: $node_count"
    else
        echo "  📍 Active Nodes: 0"
    fi
    echo
    
    # Performance metrics
    echo "📊 Performance Metrics:"
    if [[ -f "/var/log/edge_performance.log" ]]; then
        echo "  $(tail -n 3 /var/log/edge_performance.log | head -n 1)"
        echo "  $(tail -n 2 /var/log/edge_performance.log | head -n 1)"
        echo "  $(tail -n 1 /var/log/edge_performance.log)"
    else
        echo "  📈 CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
        echo "  💾 Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
        echo "  🌐 Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    fi
    echo
    
    # Cache statistics
    echo "🚀 Cache Statistics:"
    if command -v redis-cli &> /dev/null && systemctl is-active --quiet redis-server; then
        hits=$(redis-cli info stats | grep keyspace_hits | cut -d: -f2 | tr -d '\r')
        misses=$(redis-cli info stats | grep keyspace_misses | cut -d: -f2 | tr -d '\r')
        if [[ -n "$hits" && -n "$misses" && "$((hits + misses))" -gt 0 ]]; then
            hit_rate=$(echo "scale=2; $hits * 100 / ($hits + $misses)" | bc -l 2>/dev/null || echo "0")
            echo "  🎯 Cache Hit Rate: ${hit_rate}%"
        else
            echo "  🎯 Cache Hit Rate: N/A"
        fi
    else
        echo "  ❌ Cache not available"
    fi
    echo
}

# Main edge computing menu
edge_computing_menu() {
    while true; do
        show_edge_status
        echo "==============================================="
        echo "        Edge Computing Manager"
        echo "==============================================="
        echo "1.  🚀 Initialize Edge Computing"
        echo "2.  📦 Install Dependencies"
        echo "3.  🌐 Configure CDN"
        echo "4.  ⚖️  Setup Load Balancer"
        echo "5.  🚀 Configure Caching"
        echo "6.  ⚡ Deploy Edge Function"
        echo "7.  📊 Start Performance Monitoring"
        echo "8.  🔧 Manage Edge Nodes"
        echo "9.  🛡️  Security Configuration"
        echo "10. 📈 View Performance Analytics"
        echo "11. 🔄 Auto-scaling Configuration"
        echo "12. 📋 Show Status"
        echo "0.  ← Return to Main Menu"
        echo "==============================================="
        
        read -p "Select option [0-12]: " choice
        
        case $choice in
            1)
                init_edge_computing
                read -p "Press Enter to continue..."
                ;;
            2)
                install_edge_dependencies
                read -p "Press Enter to continue..."
                ;;
            3)
                echo "CDN Configuration:"
                echo "1. Nginx CDN"
                echo "2. Varnish CDN"
                read -p "Select CDN type [1-2]: " cdn_choice
                case $cdn_choice in
                    1) configure_cdn "nginx" ;;
                    2) configure_cdn "varnish" ;;
                    *) echo "Invalid choice" ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            4)
                echo "Load Balancer Algorithms:"
                echo "1. Round Robin"
                echo "2. Least Connections"
                echo "3. Source IP Hash"
                read -p "Select algorithm [1-3]: " lb_choice
                case $lb_choice in
                    1) setup_load_balancer "roundrobin" ;;
                    2) setup_load_balancer "leastconn" ;;
                    3) setup_load_balancer "source" ;;
                    *) echo "Invalid choice" ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "Cache Types:"
                echo "1. Redis Cache"
                echo "2. Memcached"
                read -p "Select cache type [1-2]: " cache_choice
                case $cache_choice in
                    1) configure_edge_caching "redis" ;;
                    2) configure_edge_caching "memcached" ;;
                    *) echo "Invalid choice" ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            6)
                read -p "Enter function name: " func_name
                echo "Enter function code (end with 'END' on a new line):"
                func_code=""
                while IFS= read -r line; do
                    [[ "$line" == "END" ]] && break
                    func_code+="$line"$'\n'
                done
                deploy_edge_function "$func_name" "$func_code"
                read -p "Press Enter to continue..."
                ;;
            7)
                monitor_edge_performance
                read -p "Press Enter to continue..."
                ;;
            8)
                echo "Edge Node Management - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            9)
                echo "Security Configuration - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            10)
                echo "Performance Analytics - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "Auto-scaling Configuration - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            12)
                show_edge_status
                read -p "Press Enter to continue..."
                ;;
            0)
                return 0
                ;;
            *)
                echo "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main execution
main() {
    case "${1:-menu}" in
        "init")
            init_edge_computing
            ;;
        "install")
            install_edge_dependencies
            ;;
        "cdn")
            configure_cdn "${2:-nginx}"
            ;;
        "loadbalancer")
            setup_load_balancer "${2:-roundrobin}"
            ;;
        "cache")
            configure_edge_caching "${2:-redis}"
            ;;
        "deploy")
            shift
            deploy_edge_function "$@"
            ;;
        "monitor")
            monitor_edge_performance
            ;;
        "status")
            show_edge_status
            ;;
        "menu"|*)
            edge_computing_menu
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
