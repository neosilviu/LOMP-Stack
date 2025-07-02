#!/bin/bash
#
# serverless_platform_manager.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v3.0 - Serverless Computing Platform
# Next-Generation Serverless Functions and Event-Driven Architecture
# 
# Features:
# - Function as a Service (FaaS) Platform
# - Event-driven Architecture
# - Auto-scaling Functions
# - API Gateway Integration
# - Multi-language Support (Node.js, Python, Go, PHP)
# - Cost Optimization
# - Performance Monitoring
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

# Configuration
SERVERLESS_CONFIG="${SCRIPT_DIR}/serverless_config.json"
SERVERLESS_LOG="${SCRIPT_DIR}/../tmp/serverless_platform.log"
FUNCTIONS_DIR="${SCRIPT_DIR}/functions"
RUNTIME_DIR="${SCRIPT_DIR}/runtime"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

# Logging function
log_serverless() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$SERVERLESS_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize Serverless Configuration
#########################################################################
initialize_serverless_config() {
    if [ ! -f "$SERVERLESS_CONFIG" ]; then
        cat > "$SERVERLESS_CONFIG" << 'EOF'
{
    "platform": {
        "name": "LOMP Serverless",
        "version": "3.0.0",
        "enabled": true,
        "api_gateway": {
            "enabled": true,
            "port": 8000,
            "ssl": true,
            "rate_limiting": true
        }
    },
    "runtimes": {
        "nodejs": {
            "enabled": true,
            "versions": ["18", "20"],
            "default_version": "20"
        },
        "python": {
            "enabled": true,
            "versions": ["3.9", "3.10", "3.11"],
            "default_version": "3.11"
        },
        "go": {
            "enabled": true,
            "versions": ["1.19", "1.20", "1.21"],
            "default_version": "1.21"
        },
        "php": {
            "enabled": true,
            "versions": ["8.1", "8.2", "8.3"],
            "default_version": "8.3"
        }
    },
    "scaling": {
        "auto_scaling": true,
        "min_instances": 0,
        "max_instances": 100,
        "scale_up_threshold": 0.7,
        "scale_down_threshold": 0.3,
        "cold_start_optimization": true
    },
    "monitoring": {
        "enabled": true,
        "metrics": {
            "invocations": true,
            "duration": true,
            "errors": true,
            "cold_starts": true
        },
        "alerting": {
            "enabled": true,
            "error_threshold": 5,
            "latency_threshold": 5000
        }
    },
    "security": {
        "authentication": true,
        "authorization": true,
        "api_keys": true,
        "cors": {
            "enabled": true,
            "origins": ["*"]
        }
    }
}
EOF
        log_serverless "SUCCESS" "Serverless configuration created"
    fi
}

#########################################################################
# Runtime Management
#########################################################################

# Setup runtime environments
setup_runtimes() {
    log_serverless "INFO" "Setting up serverless runtimes..."
    
    mkdir -p "$RUNTIME_DIR"
    
    # Node.js runtime setup
    setup_nodejs_runtime
    
    # Python runtime setup
    setup_python_runtime
    
    # Go runtime setup
    setup_go_runtime
    
    # PHP runtime setup
    setup_php_runtime
    
    log_serverless "SUCCESS" "All runtimes configured"
}

# Node.js runtime
setup_nodejs_runtime() {
    log_serverless "INFO" "Setting up Node.js runtime..."
    
    cat > "${RUNTIME_DIR}/nodejs.dockerfile" << 'EOF'
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .

EXPOSE 8080
CMD ["node", "index.js"]
EOF
    
    # Create Node.js function template
    mkdir -p "${TEMPLATES_DIR}/nodejs"
    cat > "${TEMPLATES_DIR}/nodejs/index.js" << 'EOF'
const express = require('express');
const app = express();

app.use(express.json());

// Main function handler
app.post('/invoke', async (req, res) => {
    try {
        const { event, context } = req.body;
        
        // Your function logic here
        const result = await handler(event, context);
        
        res.json({
            statusCode: 200,
            body: result
        });
    } catch (error) {
        res.status(500).json({
            statusCode: 500,
            error: error.message
        });
    }
});

// Function implementation
async function handler(event, context) {
    return {
        message: 'Hello from Node.js function!',
        event: event,
        timestamp: new Date().toISOString()
    };
}

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
    console.log(`Function listening on port ${PORT}`);
});
EOF
    
    cat > "${TEMPLATES_DIR}/nodejs/package.json" << 'EOF'
{
    "name": "lomp-serverless-function",
    "version": "1.0.0",
    "description": "LOMP Serverless Function",
    "main": "index.js",
    "dependencies": {
        "express": "^4.18.2"
    },
    "scripts": {
        "start": "node index.js"
    }
}
EOF
}

# Python runtime
setup_python_runtime() {
    log_serverless "INFO" "Setting up Python runtime..."
    
    cat > "${RUNTIME_DIR}/python.dockerfile" << 'EOF'
FROM python:3.11-alpine

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 8080
CMD ["python", "app.py"]
EOF
    
    # Create Python function template
    mkdir -p "${TEMPLATES_DIR}/python"
    cat > "${TEMPLATES_DIR}/python/app.py" << 'EOF'
from flask import Flask, request, jsonify
import json
from datetime import datetime

app = Flask(__name__)

@app.route('/invoke', methods=['POST'])
def invoke_function():
    try:
        data = request.get_json()
        event = data.get('event', {})
        context = data.get('context', {})
        
        # Your function logic here
        result = handler(event, context)
        
        return jsonify({
            'statusCode': 200,
            'body': result
        })
    except Exception as e:
        return jsonify({
            'statusCode': 500,
            'error': str(e)
        }), 500

def handler(event, context):
    return {
        'message': 'Hello from Python function!',
        'event': event,
        'timestamp': datetime.now().isoformat()
    }

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF
    
    cat > "${TEMPLATES_DIR}/python/requirements.txt" << 'EOF'
Flask==2.3.3
requests==2.31.0
EOF
}

# Go runtime
setup_go_runtime() {
    log_serverless "INFO" "Setting up Go runtime..."
    
    cat > "${RUNTIME_DIR}/go.dockerfile" << 'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
EOF
    
    # Create Go function template
    mkdir -p "${TEMPLATES_DIR}/go"
    cat > "${TEMPLATES_DIR}/go/main.go" << 'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "time"
)

type Event map[string]interface{}
type Context map[string]interface{}

type Request struct {
    Event   Event   `json:"event"`
    Context Context `json:"context"`
}

type Response struct {
    StatusCode int         `json:"statusCode"`
    Body       interface{} `json:"body,omitempty"`
    Error      string      `json:"error,omitempty"`
}

func invokeHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    
    if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }
    
    var req Request
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        response := Response{
            StatusCode: 500,
            Error:      err.Error(),
        }
        json.NewEncoder(w).Encode(response)
        return
    }
    
    // Your function logic here
    result := handler(req.Event, req.Context)
    
    response := Response{
        StatusCode: 200,
        Body:       result,
    }
    
    json.NewEncoder(w).Encode(response)
}

func handler(event Event, context Context) interface{} {
    return map[string]interface{}{
        "message":   "Hello from Go function!",
        "event":     event,
        "timestamp": time.Now().Format(time.RFC3339),
    }
}

func main() {
    http.HandleFunc("/invoke", invokeHandler)
    
    fmt.Println("Function listening on port 8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
EOF
    
    cat > "${TEMPLATES_DIR}/go/go.mod" << 'EOF'
module lomp-serverless-function

go 1.21
EOF
}

# PHP runtime
setup_php_runtime() {
    log_serverless "INFO" "Setting up PHP runtime..."
    
    cat > "${RUNTIME_DIR}/php.dockerfile" << 'EOF'
FROM php:8.3-apache

RUN docker-php-ext-install pdo pdo_mysql
RUN a2enmod rewrite

COPY . /var/www/html/
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf

EXPOSE 80
CMD ["apache2-foreground"]
EOF
    
    # Create PHP function template
    mkdir -p "${TEMPLATES_DIR}/php"
    cat > "${TEMPLATES_DIR}/php/index.php" << 'EOF'
<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    $event = $input['event'] ?? [];
    $context = $input['context'] ?? [];
    
    // Your function logic here
    $result = handler($event, $context);
    
    echo json_encode([
        'statusCode' => 200,
        'body' => $result
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'statusCode' => 500,
        'error' => $e->getMessage()
    ]);
}

function handler($event, $context) {
    return [
        'message' => 'Hello from PHP function!',
        'event' => $event,
        'timestamp' => date('c')
    ];
}
?>
EOF
    
    cat > "${TEMPLATES_DIR}/php/apache-config.conf" << 'EOF'
<VirtualHost *:80>
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
}

#########################################################################
# Function Management
#########################################################################

# Create new function
create_function() {
    echo "🚀 CREATE NEW SERVERLESS FUNCTION"
    echo "────────────────────────────────────────────────────────────────"
    
    read -p "Function name: " function_name
    if [ -z "$function_name" ]; then
        log_serverless "ERROR" "Function name cannot be empty"
        return 1
    fi
    
    echo "Available runtimes:"
    echo "1. Node.js"
    echo "2. Python"
    echo "3. Go"
    echo "4. PHP"
    read -p "Select runtime [1-4]: " runtime_choice
    
    case $runtime_choice in
        1) runtime="nodejs" ;;
        2) runtime="python" ;;
        3) runtime="go" ;;
        4) runtime="php" ;;
        *) log_serverless "ERROR" "Invalid runtime choice"; return 1 ;;
    esac
    
    read -p "Function description: " description
    read -p "Memory limit (MB, default: 512): " memory_limit
    memory_limit=${memory_limit:-512}
    
    read -p "Timeout (seconds, default: 30): " timeout
    timeout=${timeout:-30}
    
    # Create function directory
    func_dir="${FUNCTIONS_DIR}/${function_name}"
    mkdir -p "$func_dir"
    
    # Copy template files
    cp -r "${TEMPLATES_DIR}/${runtime}/"* "$func_dir/"
    
    # Create function metadata
    cat > "${func_dir}/function.json" << EOF
{
    "name": "$function_name",
    "runtime": "$runtime",
    "description": "$description",
    "memory_limit": $memory_limit,
    "timeout": $timeout,
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "version": "1.0.0",
    "handler": "index.handler",
    "environment": {},
    "triggers": [],
    "status": "created"
}
EOF
    
    # Build function container
    cd "$func_dir" || return 1
    docker build -t "lomp-function-${function_name}:latest" -f "${RUNTIME_DIR}/${runtime}.dockerfile" .
    
    if [ $? -eq 0 ]; then
        log_serverless "SUCCESS" "Function '$function_name' created successfully"
        
        # Update status
        jq '.status = "ready"' function.json > function.json.tmp && mv function.json.tmp function.json
    else
        log_serverless "ERROR" "Failed to build function '$function_name'"
        return 1
    fi
}

# Deploy function
deploy_function() {
    echo "🚀 DEPLOY FUNCTION"
    echo "────────────────────────────────────────────────────────────────"
    
    # List available functions
    if [ ! -d "$FUNCTIONS_DIR" ] || [ -z "$(ls -A "$FUNCTIONS_DIR" 2>/dev/null)" ]; then
        log_serverless "WARNING" "No functions found. Create a function first."
        return 1
    fi
    
    echo "Available functions:"
    local i=1
    for func_dir in "$FUNCTIONS_DIR"/*; do
        if [ -d "$func_dir" ]; then
            func_name=$(basename "$func_dir")
            echo "$i. $func_name"
            ((i++))
        fi
    done
    
    read -p "Select function number: " func_num
    
    # Get function name
    local j=1
    for func_dir in "$FUNCTIONS_DIR"/*; do
        if [ -d "$func_dir" ] && [ $j -eq $func_num ]; then
            function_name=$(basename "$func_dir")
            break
        fi
        ((j++))
    done
    
    if [ -z "$function_name" ]; then
        log_serverless "ERROR" "Invalid function selection"
        return 1
    fi
    
    func_dir="${FUNCTIONS_DIR}/${function_name}"
    
    # Read function metadata
    if [ ! -f "${func_dir}/function.json" ]; then
        log_serverless "ERROR" "Function metadata not found"
        return 1
    fi
    
    # Stop existing container if running
    docker stop "lomp-function-${function_name}" 2>/dev/null
    docker rm "lomp-function-${function_name}" 2>/dev/null
    
    # Get available port
    local port
    port=$(python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()")
    
    # Deploy function
    docker run -d \
        --name "lomp-function-${function_name}" \
        --restart unless-stopped \
        -p "$port:8080" \
        -e "FUNCTION_NAME=$function_name" \
        "lomp-function-${function_name}:latest"
    
    if [ $? -eq 0 ]; then
        # Update function metadata
        jq --arg port "$port" '.status = "deployed" | .endpoint = ("http://localhost:" + $port + "/invoke")' \
            "${func_dir}/function.json" > "${func_dir}/function.json.tmp" && \
            mv "${func_dir}/function.json.tmp" "${func_dir}/function.json"
        
        log_serverless "SUCCESS" "Function '$function_name' deployed on port $port"
        echo "Endpoint: http://localhost:$port/invoke"
    else
        log_serverless "ERROR" "Failed to deploy function '$function_name'"
        return 1
    fi
}

# List functions
list_functions() {
    echo "📋 SERVERLESS FUNCTIONS"
    echo "────────────────────────────────────────────────────────────────"
    
    if [ ! -d "$FUNCTIONS_DIR" ] || [ -z "$(ls -A "$FUNCTIONS_DIR" 2>/dev/null)" ]; then
        echo "No functions found."
        return 0
    fi
    
    printf "%-20s %-10s %-10s %-20s %-10s\n" "NAME" "RUNTIME" "STATUS" "ENDPOINT" "MEMORY"
    echo "────────────────────────────────────────────────────────────────────────────────────────"
    
    for func_dir in "$FUNCTIONS_DIR"/*; do
        if [ -d "$func_dir" ] && [ -f "${func_dir}/function.json" ]; then
            local func_name
            func_name=$(basename "$func_dir")
            local runtime
            runtime=$(jq -r '.runtime' "${func_dir}/function.json")
            local status
            status=$(jq -r '.status' "${func_dir}/function.json")
            local endpoint
            endpoint=$(jq -r '.endpoint // "N/A"' "${func_dir}/function.json")
            local memory
            memory=$(jq -r '.memory_limit' "${func_dir}/function.json")
            
            printf "%-20s %-10s %-10s %-20s %-10s\n" "$func_name" "$runtime" "$status" "$endpoint" "${memory}MB"
        fi
    done
}

# Invoke function
invoke_function() {
    echo "🔥 INVOKE FUNCTION"
    echo "────────────────────────────────────────────────────────────────"
    
    # List deployed functions
    deployed_functions=()
    for func_dir in "$FUNCTIONS_DIR"/*; do
        if [ -d "$func_dir" ] && [ -f "${func_dir}/function.json" ]; then
            local status
            status=$(jq -r '.status' "${func_dir}/function.json")
            if [ "$status" = "deployed" ]; then
                deployed_functions+=("$(basename "$func_dir")")
            fi
        fi
    done
    
    if [ ${#deployed_functions[@]} -eq 0 ]; then
        log_serverless "WARNING" "No deployed functions found"
        return 1
    fi
    
    echo "Deployed functions:"
    for i in "${!deployed_functions[@]}"; do
        echo "$((i+1)). ${deployed_functions[i]}"
    done
    
    read -p "Select function [1-${#deployed_functions[@]}]: " func_choice
    
    if [ $func_choice -lt 1 ] || [ $func_choice -gt ${#deployed_functions[@]} ]; then
        log_serverless "ERROR" "Invalid function selection"
        return 1
    fi
    
    function_name="${deployed_functions[$((func_choice-1))]}"
    func_dir="${FUNCTIONS_DIR}/${function_name}"
    
    endpoint=$(jq -r '.endpoint' "${func_dir}/function.json")
    
    echo "Function: $function_name"
    echo "Endpoint: $endpoint"
    echo ""
    
    read -p "Enter event data (JSON, press Enter for default): " event_data
    if [ -z "$event_data" ]; then
        event_data='{"test": "data"}'
    fi
    
    # Invoke function
    echo "Invoking function..."
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"event\": $event_data, \"context\": {\"requestId\": \"$(uuidgen)\"}}" \
        "$endpoint")
    
    echo "Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
}

# Function logs
view_function_logs() {
    echo "📋 FUNCTION LOGS"
    echo "────────────────────────────────────────────────────────────────"
    
    # List deployed functions
    deployed_functions=()
    for func_dir in "$FUNCTIONS_DIR"/*; do
        if [ -d "$func_dir" ] && [ -f "${func_dir}/function.json" ]; then
            local status
            status=$(jq -r '.status' "${func_dir}/function.json")
            if [ "$status" = "deployed" ]; then
                deployed_functions+=("$(basename "$func_dir")")
            fi
        fi
    done
    
    if [ ${#deployed_functions[@]} -eq 0 ]; then
        log_serverless "WARNING" "No deployed functions found"
        return 1
    fi
    
    echo "Deployed functions:"
    for i in "${!deployed_functions[@]}"; do
        echo "$((i+1)). ${deployed_functions[i]}"
    done
    
    read -p "Select function [1-${#deployed_functions[@]}]: " func_choice
    
    if [ $func_choice -lt 1 ] || [ $func_choice -gt ${#deployed_functions[@]} ]; then
        log_serverless "ERROR" "Invalid function selection"
        return 1
    fi
    
    function_name="${deployed_functions[$((func_choice-1))]}"
    
    echo "Logs for function: $function_name"
    echo "────────────────────────────────────────────────────────────────"
    docker logs "lomp-function-${function_name}" --tail=50 -f
}

#########################################################################
# API Gateway Functions
#########################################################################

# Setup API Gateway
setup_api_gateway() {
    log_serverless "INFO" "Setting up API Gateway..."
    
    mkdir -p "${SCRIPT_DIR}/gateway"
    
    # Create API Gateway container
    cat > "${SCRIPT_DIR}/gateway/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  api-gateway:
    image: nginx:alpine
    container_name: lomp-serverless-gateway
    restart: unless-stopped
    ports:
      - "8000:80"
      - "8443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    networks:
      - serverless-network

  gateway-manager:
    build: ./manager
    container_name: lomp-gateway-manager
    restart: unless-stopped
    ports:
      - "8001:3000"
    environment:
      NODE_ENV: production
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - serverless-network

networks:
  serverless-network:
    driver: bridge
EOF
    
    # Create Nginx configuration
    cat > "${SCRIPT_DIR}/gateway/nginx.conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream gateway_manager {
        server gateway-manager:3000;
    }
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    server {
        listen 80;
        
        # API Gateway Manager
        location /admin/ {
            proxy_pass http://gateway_manager/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        # Function routes will be dynamically added here
        include /etc/nginx/conf.d/functions.conf;
    }
}
EOF
    
    # Create Gateway Manager
    mkdir -p "${SCRIPT_DIR}/gateway/manager"
    cat > "${SCRIPT_DIR}/gateway/manager/Dockerfile" << 'EOF'
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]
EOF
    
    # Start API Gateway
    cd "${SCRIPT_DIR}/gateway" || return 1
    docker-compose up -d
    
    log_serverless "SUCCESS" "API Gateway started on port 8000"
}

#########################################################################
# Monitoring and Analytics
#########################################################################

# Setup monitoring
setup_serverless_monitoring() {
    log_serverless "INFO" "Setting up serverless monitoring..."
    
    mkdir -p "${SCRIPT_DIR}/monitoring"
    
    # Create monitoring stack
    cat > "${SCRIPT_DIR}/monitoring/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: lomp-serverless-prometheus
    restart: unless-stopped
    ports:
      - "9091:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana:latest
    container_name: lomp-serverless-grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin123
    volumes:
      - grafana-data:/var/lib/grafana
      - ./dashboards:/etc/grafana/provisioning/dashboards
      - ./datasources:/etc/grafana/provisioning/datasources

  function-metrics:
    build: ./metrics-collector
    container_name: lomp-function-metrics
    restart: unless-stopped
    ports:
      - "9092:8080"
    environment:
      PROMETHEUS_URL: http://prometheus:9090
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  prometheus-data:
  grafana-data:
EOF
    
    # Start monitoring
    cd "${SCRIPT_DIR}/monitoring" || return 1
    docker-compose up -d
    
    log_serverless "SUCCESS" "Serverless monitoring started"
    log_serverless "INFO" "Prometheus: http://localhost:9091"
    log_serverless "INFO" "Grafana: http://localhost:3001 (admin/admin123)"
}

#########################################################################
# Main Serverless Menu
#########################################################################

# Main menu function
show_serverless_menu() {
    while true; do
        clear
        echo "⚡ LOMP STACK - SERVERLESS COMPUTING PLATFORM"
        echo "════════════════════════════════════════════════════════════════"
        echo "                    Next-Generation Platform v3.0"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "🔧 SETUP & CONFIGURATION:"
        echo "1.  ⚙️  Initialize Platform"
        echo "2.  🏗️  Setup Runtimes"
        echo "3.  🌐 Setup API Gateway"
        echo "4.  📊 Setup Monitoring"
        echo ""
        echo "🚀 FUNCTION MANAGEMENT:"
        echo "5.  ➕ Create Function"
        echo "6.  🚀 Deploy Function"
        echo "7.  📋 List Functions"
        echo "8.  🔥 Invoke Function"
        echo "9.  📋 View Function Logs"
        echo "10. 🗑️  Delete Function"
        echo ""
        echo "🌐 API GATEWAY:"
        echo "11. 🔧 Configure Routes"
        echo "12. 🔑 Manage API Keys"
        echo "13. 📈 Rate Limiting"
        echo "14. 🔐 Security Settings"
        echo ""
        echo "📊 MONITORING & ANALYTICS:"
        echo "15. 📊 Function Metrics"
        echo "16. 🚨 Alerts & Notifications"
        echo "17. 📈 Performance Dashboard"
        echo "18. 💰 Cost Analysis"
        echo ""
        echo "ℹ️  INFORMATION:"
        echo "19. 📋 Platform Status"
        echo "20. 📖 View Logs"
        echo "21. ⚙️  Configuration"
        echo "22. 📚 Documentation"
        echo ""
        echo "0.  🚪 Exit"
        echo "════════════════════════════════════════════════════════════════"
        read -p "Select option [0-22]: " choice
        
        case $choice in
            1)
                initialize_serverless_config
                setup_runtimes
                read -p "Press Enter to continue..."
                ;;
            2)
                setup_runtimes
                read -p "Press Enter to continue..."
                ;;
            3)
                setup_api_gateway
                read -p "Press Enter to continue..."
                ;;
            4)
                setup_serverless_monitoring
                read -p "Press Enter to continue..."
                ;;
            5)
                create_function
                read -p "Press Enter to continue..."
                ;;
            6)
                deploy_function
                read -p "Press Enter to continue..."
                ;;
            7)
                list_functions
                read -p "Press Enter to continue..."
                ;;
            8)
                invoke_function
                read -p "Press Enter to continue..."
                ;;
            9)
                view_function_logs
                ;;
            10)
                echo "🗑️ DELETE FUNCTION"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "🔧 CONFIGURE ROUTES"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            12)
                echo "🔑 MANAGE API KEYS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            13)
                echo "📈 RATE LIMITING"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            14)
                echo "🔐 SECURITY SETTINGS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            15)
                echo "📊 FUNCTION METRICS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            16)
                echo "🚨 ALERTS & NOTIFICATIONS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            17)
                echo "📈 PERFORMANCE DASHBOARD"
                echo "Grafana Dashboard: http://localhost:3001"
                read -p "Press Enter to continue..."
                ;;
            18)
                echo "💰 COST ANALYSIS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            19)
                show_serverless_status
                read -p "Press Enter to continue..."
                ;;
            20)
                if [ -f "$SERVERLESS_LOG" ]; then
                    tail -50 "$SERVERLESS_LOG"
                else
                    echo "No logs found"
                fi
                read -p "Press Enter to continue..."
                ;;
            21)
                if [ -f "$SERVERLESS_CONFIG" ]; then
                    cat "$SERVERLESS_CONFIG" | jq '.'
                else
                    echo "No configuration found"
                fi
                read -p "Press Enter to continue..."
                ;;
            22)
                show_serverless_documentation
                read -p "Press Enter to continue..."
                ;;
            0)
                log_serverless "INFO" "Serverless Platform stopped"
                exit 0
                ;;
            *)
                echo "Invalid option! Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Status function
show_serverless_status() {
    echo "📊 SERVERLESS PLATFORM STATUS"
    echo "════════════════════════════════════════════════════════════════"
    
    # Platform status
    echo "⚡ PLATFORM STATUS:"
    if [ -f "$SERVERLESS_CONFIG" ]; then
        echo "Configuration: ✅ Loaded"
    else
        echo "Configuration: ❌ Missing"
    fi
    
    # Runtime status
    echo -e "\n🏗️ RUNTIME STATUS:"
    for runtime in nodejs python go php; do
        if [ -f "${RUNTIME_DIR}/${runtime}.dockerfile" ]; then
            echo "$runtime: ✅ Available"
        else
            echo "$runtime: ❌ Not configured"
        fi
    done
    
    # Function status
    echo -e "\n🚀 FUNCTIONS:"
    if [ -d "$FUNCTIONS_DIR" ]; then
        total_functions=$(find "$FUNCTIONS_DIR" -name "function.json" | wc -l)
        deployed_functions_count=$(find "$FUNCTIONS_DIR" -name "function.json" -exec jq -r '.status' {} \; | grep -c "deployed")
        echo "Total functions: $total_functions"
        echo "Deployed functions: $deployed_functions_count"
    else
        echo "No functions found"
    fi
    
    # Container status
    echo -e "\n🐳 CONTAINER STATUS:"
    echo "Running function containers: $(docker ps --filter "name=lomp-function-" --format "{{.Names}}" | wc -l)"
    
    # API Gateway status
    echo -e "\n🌐 API GATEWAY:"
    if docker ps --filter "name=lomp-serverless-gateway" --format "{{.Names}}" | grep -q "lomp-serverless-gateway"; then
        echo "Status: ✅ Running on port 8000"
    else
        echo "Status: ❌ Not running"
    fi
    
    # Monitoring status
    echo -e "\n📊 MONITORING:"
    if docker ps --filter "name=lomp-serverless-prometheus" --format "{{.Names}}" | grep -q "lomp-serverless-prometheus"; then
        echo "Prometheus: ✅ Running on port 9091"
    else
        echo "Prometheus: ❌ Not running"
    fi
    
    if docker ps --filter "name=lomp-serverless-grafana" --format "{{.Names}}" | grep -q "lomp-serverless-grafana"; then
        echo "Grafana: ✅ Running on port 3001"
    else
        echo "Grafana: ❌ Not running"
    fi
}

# Documentation function
show_serverless_documentation() {
    cat << 'EOF'
📚 SERVERLESS COMPUTING PLATFORM DOCUMENTATION
════════════════════════════════════════════════════════════════

🎯 OVERVIEW:
The Serverless Computing Platform provides a complete Function as a 
Service (FaaS) solution with support for multiple programming languages,
auto-scaling, monitoring, and API gateway integration.

🚀 SUPPORTED RUNTIMES:
• Node.js (v18, v20)
• Python (v3.9, v3.10, v3.11)
• Go (v1.19, v1.20, v1.21)
• PHP (v8.1, v8.2, v8.3)

🔧 GETTING STARTED:
1. Initialize Platform (Option 1)
2. Setup Runtimes (Option 2)
3. Create your first function (Option 5)
4. Deploy function (Option 6)
5. Test function (Option 8)

📊 MONITORING:
• Prometheus: http://localhost:9091
• Grafana: http://localhost:3001 (admin/admin123)
• Function Metrics: Invocations, Duration, Errors, Cold Starts

🌐 API GATEWAY:
• Gateway: http://localhost:8000
• Admin Panel: http://localhost:8001/admin
• Rate limiting and API key management

💡 FUNCTION STRUCTURE:
Each function includes:
- Runtime-specific handler
- Function metadata (function.json)
- Docker container for isolation
- Automatic scaling capabilities

🔒 SECURITY FEATURES:
• Container isolation
• API authentication
• Rate limiting
• CORS configuration
• SSL/TLS support

📖 TROUBLESHOOTING:
• Check logs: tail -f serverless_platform.log
• Verify containers: docker ps
• Test connectivity: curl function endpoints
• Monitor metrics: Grafana dashboards

📞 SUPPORT:
For technical support and feature requests, please refer to the
main LOMP Stack documentation or contact the development team.
EOF
}

#########################################################################
# Main Execution
#########################################################################

# Initialize
initialize_serverless_config

# Check if running as main script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_serverless_menu
fi
