#!/bin/bash
#
# container_orchestration_manager.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v3.0 - Container Orchestration Manager
# Next-Generation Container Management and Orchestration
# 
# Features:
# - Docker Integration and Management
# - Kubernetes Cluster Orchestration
# - Docker Swarm Support
# - Container Registry Management
# - Auto-scaling and Load Balancing
# - Container Security and Monitoring
# - Multi-cloud Container Deployment
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

# Configuration
CONTAINER_CONFIG="${SCRIPT_DIR}/container_config.json"
CONTAINER_LOG="${SCRIPT_DIR}/../tmp/container_orchestration.log"
DOCKER_REGISTRY_DIR="${SCRIPT_DIR}/registry"
K8S_CONFIG_DIR="${SCRIPT_DIR}/kubernetes"
SWARM_CONFIG_DIR="${SCRIPT_DIR}/swarm"

# Logging function
log_container() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$CONTAINER_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize Container Configuration
#########################################################################
initialize_container_config() {
    if [ ! -f "$CONTAINER_CONFIG" ]; then
        cat > "$CONTAINER_CONFIG" << 'EOF'
{
    "orchestration": {
        "enabled": true,
        "default_platform": "docker",
        "supported_platforms": ["docker", "kubernetes", "docker-swarm"],
        "auto_scaling": {
            "enabled": true,
            "cpu_threshold": 70,
            "memory_threshold": 80,
            "min_replicas": 1,
            "max_replicas": 10
        }
    },
    "docker": {
        "enabled": true,
        "version": "latest",
        "registry": {
            "enabled": true,
            "port": 5000,
            "ssl": true,
            "authentication": true
        },
        "compose": {
            "enabled": true,
            "version": "3.8"
        }
    },
    "kubernetes": {
        "enabled": true,
        "cluster_name": "lomp-k8s-cluster",
        "master_node": true,
        "worker_nodes": 3,
        "network_plugin": "flannel",
        "ingress_controller": "nginx",
        "monitoring": {
            "prometheus": true,
            "grafana": true,
            "jaeger": false
        }
    },
    "docker_swarm": {
        "enabled": true,
        "manager_nodes": 1,
        "worker_nodes": 2,
        "overlay_network": "lomp-swarm-network",
        "secrets_management": true
    },
    "security": {
        "image_scanning": true,
        "vulnerability_assessment": true,
        "access_control": true,
        "network_policies": true,
        "secrets_encryption": true
    },
    "monitoring": {
        "enabled": true,
        "metrics_collection": true,
        "log_aggregation": true,
        "alerting": true,
        "dashboard": true
    }
}
EOF
        log_container "SUCCESS" "Container configuration created"
    fi
}

#########################################################################
# Docker Management Functions
#########################################################################

# Install Docker
install_docker() {
    log_container "INFO" "Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker >/dev/null 2>&1; then
        log_container "INFO" "Docker is already installed"
        docker --version
        return 0
    fi
    
    # Install Docker based on OS
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        
        # Add Docker GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Add Docker repository
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
    elif [[ -f /etc/redhat-release ]]; then
        # RHEL/CentOS/Fedora
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        log_container "ERROR" "Unsupported operating system for Docker installation"
        return 1
    fi
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Install Docker Compose if not installed
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_container "INFO" "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    log_container "SUCCESS" "Docker installation completed"
    docker --version
    docker-compose --version
}

# Setup Private Docker Registry
setup_docker_registry() {
    log_container "INFO" "Setting up private Docker registry..."
    
    mkdir -p "$DOCKER_REGISTRY_DIR"
    
    # Create registry configuration
    cat > "${DOCKER_REGISTRY_DIR}/config.yml" << 'EOF'
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF
    
    # Create Docker Compose for registry
    cat > "${DOCKER_REGISTRY_DIR}/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  registry:
    image: registry:2
    container_name: lomp-registry
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      REGISTRY_HTTP_TLS_CERTIFICATE: /certs/registry.crt
      REGISTRY_HTTP_TLS_KEY: /certs/registry.key
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
    volumes:
      - registry-data:/var/lib/registry
      - ./config.yml:/etc/docker/registry/config.yml
      - ./certs:/certs
      - ./auth:/auth
    networks:
      - registry-network

  registry-ui:
    image: joxit/docker-registry-ui:main
    container_name: lomp-registry-ui
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      REGISTRY_TITLE: LOMP Private Registry
      NGINX_PROXY_PASS_URL: http://registry:5000
      SINGLE_REGISTRY: true
    depends_on:
      - registry
    networks:
      - registry-network

volumes:
  registry-data:

networks:
  registry-network:
    driver: bridge
EOF
    
    # Create directories for certificates and authentication
    mkdir -p "${DOCKER_REGISTRY_DIR}/certs" "${DOCKER_REGISTRY_DIR}/auth"
    
    # Generate self-signed certificate
    openssl req -newkey rsa:4096 -nodes -sha256 -keyout "${DOCKER_REGISTRY_DIR}/certs/registry.key" -x509 -days 365 -out "${DOCKER_REGISTRY_DIR}/certs/registry.crt" -subj "/CN=localhost" 2>/dev/null || {
        log_container "WARNING" "OpenSSL not available, registry will run without SSL"
    }
    
    # Create authentication file
    if command -v htpasswd >/dev/null 2>&1; then
        htpasswd -Bbn admin "$(openssl rand -base64 32)" > "${DOCKER_REGISTRY_DIR}/auth/htpasswd"
        log_container "SUCCESS" "Registry authentication configured"
    else
        log_container "WARNING" "htpasswd not available, registry will run without authentication"
    fi
    
    # Start the registry
    cd "$DOCKER_REGISTRY_DIR" || return
    docker-compose up -d
    
    log_container "SUCCESS" "Private Docker registry started on port 5000"
    log_container "INFO" "Registry UI available at http://localhost:8080"
}

# Container Management Functions
manage_containers() {
    while true; do
        clear
        echo "🐳 DOCKER CONTAINER MANAGEMENT"
        echo "────────────────────────────────────────────────────────────────"
        echo "1.  📋 List Running Containers"
        echo "2.  📦 List All Containers"
        echo "3.  🚀 Start Container"
        echo "4.  🛑 Stop Container"
        echo "5.  🔄 Restart Container"
        echo "6.  🗑️  Remove Container"
        echo "7.  📊 Container Stats"
        echo "8.  📋 Container Logs"
        echo "9.  🔍 Inspect Container"
        echo "10. 💻 Execute Command in Container"
        echo "11. 🌐 Container Networks"
        echo "12. 💾 Container Volumes"
        echo "0.  ⬅️  Back to Main Menu"
        echo "────────────────────────────────────────────────────────────────"
        read -p "Select option [0-12]: " choice
        
        case $choice in
            1)
                echo "📋 RUNNING CONTAINERS:"
                docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo "📦 ALL CONTAINERS:"
                docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter container name to start: " container_name
                if [ -n "$container_name" ]; then
                    docker start "$container_name" && log_container "SUCCESS" "Started container: $container_name"
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter container name to stop: " container_name
                if [ -n "$container_name" ]; then
                    docker stop "$container_name" && log_container "SUCCESS" "Stopped container: $container_name"
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                read -p "Enter container name to restart: " container_name
                if [ -n "$container_name" ]; then
                    docker restart "$container_name" && log_container "SUCCESS" "Restarted container: $container_name"
                fi
                read -p "Press Enter to continue..."
                ;;
            6)
                read -p "Enter container name to remove: " container_name
                if [ -n "$container_name" ]; then
                    read -p "Are you sure? (y/N): " confirm
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        docker rm -f "$container_name" && log_container "SUCCESS" "Removed container: $container_name"
                    fi
                fi
                read -p "Press Enter to continue..."
                ;;
            7)
                docker stats --no-stream
                read -p "Press Enter to continue..."
                ;;
            8)
                read -p "Enter container name for logs: " container_name
                if [ -n "$container_name" ]; then
                    docker logs "$container_name" | tail -50
                fi
                read -p "Press Enter to continue..."
                ;;
            9)
                read -p "Enter container name to inspect: " container_name
                if [ -n "$container_name" ]; then
                    docker inspect "$container_name" | jq '.[0] | {Name, State, Config, NetworkSettings}'
                fi
                read -p "Press Enter to continue..."
                ;;
            10)
                read -p "Enter container name: " container_name
                read -p "Enter command to execute: " exec_command
                if [ -n "$container_name" ] && [ -n "$exec_command" ]; then
                    docker exec -it "$container_name" $exec_command
                fi
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "🌐 DOCKER NETWORKS:"
                docker network ls
                read -p "Press Enter to continue..."
                ;;
            12)
                echo "💾 DOCKER VOLUMES:"
                docker volume ls
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

#########################################################################
# Kubernetes Cluster Management
#########################################################################

# Install Kubernetes
install_kubernetes() {
    log_container "INFO" "Installing Kubernetes..."
    
    # Check if kubectl is already installed
    if command -v kubectl >/dev/null 2>&1; then
        log_container "INFO" "Kubernetes tools already installed"
        kubectl version --client
        return 0
    fi
    
    # Install kubelet, kubeadm, kubectl
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl
        
        # Add Kubernetes GPG key
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
        
        # Add Kubernetes repository
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        
        # Install Kubernetes tools
        sudo apt-get update
        sudo apt-get install -y kubelet kubeadm kubectl
        sudo apt-mark hold kubelet kubeadm kubectl
        
    elif [[ -f /etc/redhat-release ]]; then
        # RHEL/CentOS/Fedora
        cat > /etc/yum.repos.d/kubernetes.repo << 'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
        sudo yum install -y kubelet kubeadm kubectl
        sudo systemctl enable kubelet
    else
        log_container "ERROR" "Unsupported OS for Kubernetes installation"
        return 1
    fi
    
    log_container "SUCCESS" "Kubernetes tools installed"
}

# Initialize Kubernetes cluster
init_kubernetes_cluster() {
    log_container "INFO" "Initializing Kubernetes cluster..."
    
    mkdir -p "$K8S_CONFIG_DIR"
    
    # Disable swap (required for Kubernetes)
    sudo swapoff -a
    sudo sed -i '/swap/d' /etc/fstab
    
    # Initialize cluster
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="$(hostname -I | awk '{print $1}')" | sudo tee "${K8S_CONFIG_DIR}/init.log" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # Setup kubectl for regular user
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
        
        # Install Flannel network plugin
        kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
        
        # Remove taint from master node (for single node cluster)
        kubectl taint nodes --all node-role.kubernetes.io/master-
        
        log_container "SUCCESS" "Kubernetes cluster initialized"
        
        # Generate join command for worker nodes
        kubeadm token create --print-join-command > "${K8S_CONFIG_DIR}/join-command.sh"
        
        return 0
    else
        log_container "ERROR" "Failed to initialize Kubernetes cluster"
        return 1
    fi
}

# Kubernetes management interface
manage_kubernetes() {
    while true; do
        clear
        echo "☸️ KUBERNETES CLUSTER MANAGEMENT"
        echo "────────────────────────────────────────────────────────────────"
        echo "1.  📋 Cluster Status"
        echo "2.  🖥️  Node Information"
        echo "3.  📦 Pod Management"
        echo "4.  🚀 Deploy Application"
        echo "5.  🔧 Service Management"
        echo "6.  📊 Resource Usage"
        echo "7.  📋 Namespace Management"
        echo "8.  🔍 Events and Logs"
        echo "9.  💾 ConfigMaps & Secrets"
        echo "10. 🌐 Ingress Controller"
        echo "11. 📈 Monitoring Setup"
        echo "12. 🔧 Cluster Configuration"
        echo "0.  ⬅️  Back to Main Menu"
        echo "────────────────────────────────────────────────────────────────"
        read -p "Select option [0-12]: " choice
        
        case $choice in
            1)
                echo "📋 CLUSTER STATUS:"
                kubectl cluster-info
                echo -e "\n🖥️ NODES:"
                kubectl get nodes -o wide
                echo -e "\n📊 COMPONENT STATUS:"
                kubectl get componentstatuses
                read -p "Press Enter to continue..."
                ;;
            2)
                echo "🖥️ NODE INFORMATION:"
                kubectl get nodes -o wide
                echo -e "\nSelect a node for detailed info:"
                kubectl get nodes --no-headers | awk '{print NR". "$1}'
                read -p "Enter node number: " node_num
                if [ -n "$node_num" ]; then
                    node_name=$(kubectl get nodes --no-headers | sed -n "${node_num}p" | awk '{print $1}')
                    kubectl describe node "$node_name"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                manage_kubernetes_pods
                ;;
            4)
                deploy_kubernetes_app
                ;;
            5)
                manage_kubernetes_services
                ;;
            6)
                echo "📊 RESOURCE USAGE:"
                kubectl top nodes 2>/dev/null || echo "Metrics server not installed"
                kubectl top pods --all-namespaces 2>/dev/null || echo "Metrics server not installed"
                read -p "Press Enter to continue..."
                ;;
            7)
                manage_kubernetes_namespaces
                ;;
            8)
                echo "🔍 CLUSTER EVENTS:"
                kubectl get events --sort-by=.metadata.creationTimestamp
                read -p "Press Enter to continue..."
                ;;
            9)
                manage_kubernetes_config
                ;;
            10)
                setup_kubernetes_ingress
                ;;
            11)
                setup_kubernetes_monitoring
                ;;
            12)
                configure_kubernetes_cluster
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Pod management functions
manage_kubernetes_pods() {
    while true; do
        clear
        echo "📦 KUBERNETES POD MANAGEMENT"
        echo "────────────────────────────────────────────────────────────────"
        echo "1. 📋 List All Pods"
        echo "2. 🔍 Pod Details"
        echo "3. 📋 Pod Logs"
        echo "4. 💻 Execute Command in Pod"
        echo "5. 🗑️  Delete Pod"
        echo "6. 📊 Pod Resources"
        echo "0. ⬅️  Back"
        echo "────────────────────────────────────────────────────────────────"
        read -p "Select option [0-6]: " choice
        
        case $choice in
            1)
                echo "📋 ALL PODS:"
                kubectl get pods --all-namespaces -o wide
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter pod name: " pod_name
                read -p "Enter namespace (default: default): " namespace
                namespace=${namespace:-default}
                if [ -n "$pod_name" ]; then
                    kubectl describe pod "$pod_name" -n "$namespace"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter pod name: " pod_name
                read -p "Enter namespace (default: default): " namespace
                namespace=${namespace:-default}
                if [ -n "$pod_name" ]; then
                    kubectl logs "$pod_name" -n "$namespace" --tail=50
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter pod name: " pod_name
                read -p "Enter namespace (default: default): " namespace
                read -p "Enter command: " command
                namespace=${namespace:-default}
                if [ -n "$pod_name" ] && [ -n "$command" ]; then
                    kubectl exec -it "$pod_name" -n "$namespace" -- $command
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                read -p "Enter pod name: " pod_name
                read -p "Enter namespace (default: default): " namespace
                namespace=${namespace:-default}
                if [ -n "$pod_name" ]; then
                    read -p "Are you sure? (y/N): " confirm
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        kubectl delete pod "$pod_name" -n "$namespace"
                    fi
                fi
                read -p "Press Enter to continue..."
                ;;
            6)
                echo "📊 POD RESOURCES:"
                kubectl top pods --all-namespaces 2>/dev/null || echo "Metrics server not installed"
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

#########################################################################
# Kubernetes Management Functions
#########################################################################

# Install Kubernetes
install_kubernetes() {
    log_container "INFO" "Installing Kubernetes..."
    
    # Check if kubectl is already installed
    if command -v kubectl >/dev/null 2>&1; then
        log_container "INFO" "Kubernetes tools already installed"
        kubectl version --client
        return 0
    fi
    
    # Install kubectl
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl
        
        # Add Kubernetes GPG key
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
        
        # Add Kubernetes repository
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        
        # Install Kubernetes components
        sudo apt-get update
        sudo apt-get install -y kubelet kubeadm kubectl
        sudo apt-mark hold kubelet kubeadm kubectl
        
    elif [[ -f /etc/redhat-release ]]; then
        # RHEL/CentOS/Fedora
        cat > /etc/yum.repos.d/kubernetes.repo << 'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
        sudo yum install -y kubelet kubeadm kubectl
        sudo systemctl enable kubelet
    fi
    
    # Install minikube for local development
    if ! command -v minikube >/dev/null 2>&1; then
        log_container "INFO" "Installing Minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm minikube-linux-amd64
    fi
    
    # Install Helm
    if ! command -v helm >/dev/null 2>&1; then
        log_container "INFO" "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    log_container "SUCCESS" "Kubernetes installation completed"
    kubectl version --client
    minikube version
    helm version
}

# Setup Kubernetes Cluster
setup_kubernetes_cluster() {
    log_container "INFO" "Setting up Kubernetes cluster..."
    
    mkdir -p "$K8S_CONFIG_DIR"
    
    # Create cluster configuration
    cat > "${K8S_CONFIG_DIR}/cluster-config.yaml" << 'EOF'
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
metadata:
  name: lomp-k8s-cluster
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "localhost:6443"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "10.244.0.0/16"
  dnsDomain: "cluster.local"
apiServer:
  advertiseAddress: "0.0.0.0"
  bindPort: 6443
etcd:
  local:
    dataDir: "/var/lib/etcd"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
metadata:
  name: lomp-init-config
localAPIEndpoint:
  advertiseAddress: "0.0.0.0"
  bindPort: 6443
nodeRegistration:
  criSocket: "unix:///var/run/containerd/containerd.sock"
EOF
    
    # Start minikube cluster for development
    if command -v minikube >/dev/null 2>&1; then
        log_container "INFO" "Starting Minikube cluster..."
        minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=20g
        
        # Enable addons
        minikube addons enable dashboard
        minikube addons enable metrics-server
        minikube addons enable ingress
        
        log_container "SUCCESS" "Minikube cluster started successfully"
        kubectl get nodes
    fi
    
    # Create namespace for LOMP applications
    kubectl create namespace lomp-apps 2>/dev/null || true
    
    # Create sample deployment
    cat > "${K8S_CONFIG_DIR}/sample-deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lomp-web
  namespace: lomp-apps
  labels:
    app: lomp-web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: lomp-web
  template:
    metadata:
      labels:
        app: lomp-web
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: lomp-web-service
  namespace: lomp-apps
spec:
  selector:
    app: lomp-web
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: lomp-web-ingress
  namespace: lomp-apps
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: lomp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: lomp-web-service
            port:
              number: 80
EOF
    
    log_container "SUCCESS" "Kubernetes cluster configuration completed"
}

# Kubernetes Management Menu
manage_kubernetes() {
    while true; do
        clear
        echo "☸️ KUBERNETES CLUSTER MANAGEMENT"
        echo "────────────────────────────────────────────────────────────────"
        echo "1.  📋 Cluster Status"
        echo "2.  🏗️  Deploy Application"
        echo "3.  📦 List Pods"
        echo "4.  🔄 List Services"
        echo "5.  🌐 List Ingresses"
        echo "6.  📊 Resource Usage"
        echo "7.  📋 View Logs"
        echo "8.  🔧 Scale Deployment"
        echo "9.  🗑️  Delete Resource"
        echo "10. 💻 Dashboard Access"
        echo "11. 📝 Apply YAML"
        echo "12. 🔍 Describe Resource"
        echo "0.  ⬅️  Back to Main Menu"
        echo "────────────────────────────────────────────────────────────────"
        read -p "Select option [0-12]: " choice
        
        case $choice in
            1)
                echo "📋 CLUSTER STATUS:"
                kubectl cluster-info
                echo
                echo "NODES:"
                kubectl get nodes -o wide
                echo
                echo "NAMESPACES:"
                kubectl get namespaces
                read -p "Press Enter to continue..."
                ;;
            2)
                echo "🏗️ DEPLOYING SAMPLE APPLICATION:"
                kubectl apply -f "${K8S_CONFIG_DIR}/sample-deployment.yaml"
                echo
                echo "Checking deployment status..."
                kubectl get deployments -n lomp-apps
                read -p "Press Enter to continue..."
                ;;
            3)
                echo "📦 PODS:"
                kubectl get pods --all-namespaces -o wide
                read -p "Press Enter to continue..."
                ;;
            4)
                echo "🔄 SERVICES:"
                kubectl get services --all-namespaces -o wide
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "🌐 INGRESSES:"
                kubectl get ingresses --all-namespaces -o wide
                read -p "Press Enter to continue..."
                ;;
            6)
                echo "📊 RESOURCE USAGE:"
                kubectl top nodes 2>/dev/null || echo "Metrics server not available"
                echo
                kubectl top pods --all-namespaces 2>/dev/null || echo "Metrics server not available"
                read -p "Press Enter to continue..."
                ;;
            7)
                read -p "Enter pod name: " pod_name
                read -p "Enter namespace (default: default): " namespace
                namespace=${namespace:-default}
                kubectl logs "$pod_name" -n "$namespace" --tail=50
                read -p "Press Enter to continue..."
                ;;
            8)
                read -p "Enter deployment name: " deployment_name
                read -p "Enter namespace (default: lomp-apps): " namespace
                read -p "Enter number of replicas: " replicas
                namespace=${namespace:-lomp-apps}
                kubectl scale deployment "$deployment_name" --replicas="$replicas" -n "$namespace"
                read -p "Press Enter to continue..."
                ;;
            9)
                read -p "Enter resource type (pod/service/deployment/etc): " resource_type
                read -p "Enter resource name: " resource_name
                read -p "Enter namespace (default: default): " namespace
                namespace=${namespace:-default}
                kubectl delete "$resource_type" "$resource_name" -n "$namespace"
                read -p "Press Enter to continue..."
                ;;
            10)
                echo "💻 ACCESSING KUBERNETES DASHBOARD:"
                if command -v minikube >/dev/null 2>&1; then
                    echo "Starting dashboard..."
                    minikube dashboard &
                    log_container "INFO" "Dashboard started in background"
                else
                    echo "Dashboard access token:"
                    kubectl -n kubernetes-dashboard create token admin-user 2>/dev/null || echo "Dashboard not configured"
                fi
                read -p "Press Enter to continue..."
                ;;
            11)
                read -p "Enter path to YAML file: " yaml_file
                if [[ -f "$yaml_file" ]]; then
                    kubectl apply -f "$yaml_file"
                else
                    echo "File not found: $yaml_file"
                fi
                read -p "Press Enter to continue..."
                ;;
            12)
                read -p "Enter resource type: " resource_type
                read -p "Enter resource name: " resource_name
                read -p "Enter namespace (default: default): " namespace
                namespace=${namespace:-default}
                kubectl describe "$resource_type" "$resource_name" -n "$namespace"
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo "❌ Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

#########################################################################
# Docker Swarm Management
#########################################################################

# Initialize Docker Swarm
init_docker_swarm() {
    log_container "INFO" "Initializing Docker Swarm..."
    
    mkdir -p "$SWARM_CONFIG_DIR"
    
    # Check if already in swarm mode
    if docker info | grep -q "Swarm: active"; then
        log_container "INFO" "Docker Swarm already initialized"
        return 0
    fi
    
    # Initialize swarm
    local advertise_addr
    advertise_addr=$(hostname -I | awk '{print $1}')
    docker swarm init --advertise-addr "$advertise_addr" > "${SWARM_CONFIG_DIR}/init.log" 2>&1
    
    if [ $? -eq 0 ]; then
        # Save join tokens
        docker swarm join-token worker > "${SWARM_CONFIG_DIR}/worker-token.txt"
        docker swarm join-token manager > "${SWARM_CONFIG_DIR}/manager-token.txt"
        
        # Create overlay network
        docker network create --driver overlay --attachable lomp-swarm-network
        
        log_container "SUCCESS" "Docker Swarm initialized successfully"
        return 0
    else
        log_container "ERROR" "Failed to initialize Docker Swarm"
        return 1
    fi
}

# Manage Docker Swarm
manage_docker_swarm() {
    while true; do
        clear
        echo "🐝 DOCKER SWARM MANAGEMENT"
        echo "────────────────────────────────────────────────────────────────"
        echo "1.  📋 Swarm Status"
        echo "2.  🖥️  Node Management"
        echo "3.  🚀 Service Management"
        echo "4.  📦 Stack Management"
        echo "5.  🌐 Network Management"
        echo "6.  🔑 Secret Management"
        echo "7.  📊 Service Logs"
        echo "8.  📈 Service Scaling"
        echo "9.  🔄 Rolling Updates"
        echo "10. 📋 Join Tokens"
        echo "0.  ⬅️  Back to Main Menu"
        echo "────────────────────────────────────────────────────────────────"
        read -p "Select option [0-10]: " choice
        
        case $choice in
            1)
                echo "📋 SWARM STATUS:"
                docker info | grep -A 10 "Swarm:"
                echo -e "\n🖥️ NODES:"
                docker node ls
                echo -e "\n🚀 SERVICES:"
                docker service ls
                read -p "Press Enter to continue..."
                ;;
            2)
                manage_swarm_nodes
                ;;
            3)
                manage_swarm_services
                ;;
            4)
                manage_swarm_stacks
                ;;
            5)
                manage_swarm_networks
                ;;
            6)
                manage_swarm_secrets
                ;;
            7)
                read -p "Enter service name: " service_name
                if [ -n "$service_name" ]; then
                    docker service logs "$service_name" --tail=50
                fi
                read -p "Press Enter to continue..."
                ;;
            8)
                read -p "Enter service name: " service_name
                read -p "Enter number of replicas: " replicas
                if [ -n "$service_name" ] && [ -n "$replicas" ]; then
                    docker service scale "$service_name=$replicas"
                    log_container "SUCCESS" "Scaled service $service_name to $replicas replicas"
                fi
                read -p "Press Enter to continue..."
                ;;
            9)
                read -p "Enter service name: " service_name
                read -p "Enter new image: " new_image
                if [ -n "$service_name" ] && [ -n "$new_image" ]; then
                    docker service update --image "$new_image" "$service_name"
                    log_container "SUCCESS" "Updated service $service_name with image $new_image"
                fi
                read -p "Press Enter to continue..."
                ;;
            10)
                echo "🔑 JOIN TOKENS:"
                echo "Worker Token:"
                docker swarm join-token worker -q
                echo -e "\nManager Token:"
                docker swarm join-token manager -q
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option!"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

#########################################################################
# Container Security Functions
#########################################################################

# Security scanning and vulnerability assessment
container_security_scan() {
    log_container "INFO" "Starting container security scan..."
    
    # Install Trivy if not present
    if ! command -v trivy >/dev/null 2>&1; then
        log_container "INFO" "Installing Trivy security scanner..."
        
        if [[ -f /etc/debian_version ]]; then
            sudo apt-get update
            sudo apt-get install wget apt-transport-https gnupg lsb-release
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update
            sudo apt-get install trivy
        elif [[ -f /etc/redhat-release ]]; then
            cat > /etc/yum.repos.d/trivy.repo << 'EOF'
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
gpgcheck=0
enabled=1
EOF
            sudo yum install trivy
        fi
    fi
    
    # Scan Docker images
    echo "🔍 SCANNING DOCKER IMAGES FOR VULNERABILITIES:"
    for image in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>"); do
        echo "Scanning: $image"
        trivy image --severity HIGH,CRITICAL "$image"
    done
    
    # Scan running containers
    echo -e "\n🔍 SCANNING RUNNING CONTAINERS:"
    for container in $(docker ps --format "{{.Names}}"); do
        echo "Scanning container: $container"
        trivy image "$(docker inspect "$container" --format='{{.Config.Image}}')"
    done
    
    log_container "SUCCESS" "Security scan completed"
}

# Container monitoring setup
setup_container_monitoring() {
    log_container "INFO" "Setting up container monitoring..."
    
    mkdir -p "${SCRIPT_DIR}/monitoring"
    
    # Create monitoring stack with Prometheus, Grafana, and cAdvisor
    cat > "${SCRIPT_DIR}/monitoring/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: lomp-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
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
    container_name: lomp-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin123
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: lomp-cadvisor
    restart: unless-stopped
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro

  node-exporter:
    image: prom/node-exporter:latest
    container_name: lomp-node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

volumes:
  prometheus-data:
  grafana-data:

networks:
  default:
    name: lomp-monitoring
EOF
    
    # Create Prometheus configuration
    cat > "${SCRIPT_DIR}/monitoring/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']
EOF
    
    # Start monitoring stack
    cd "${SCRIPT_DIR}/monitoring" || return
    docker-compose up -d
    
    log_container "SUCCESS" "Container monitoring started"
    log_container "INFO" "Prometheus: http://localhost:9090"
    log_container "INFO" "Grafana: http://localhost:3000 (admin/admin123)"
    log_container "INFO" "cAdvisor: http://localhost:8081"
}

#########################################################################
# Main Container Orchestration Menu
#########################################################################

# Auto-scaling configuration
configure_auto_scaling() {
    log_container "INFO" "Configuring auto-scaling..."
    
    echo "🔧 AUTO-SCALING CONFIGURATION"
    echo "────────────────────────────────────────────────────────────────"
    echo "1. Docker Swarm Auto-scaling"
    echo "2. Kubernetes HPA (Horizontal Pod Autoscaler)"
    echo "3. Custom Metrics Auto-scaling"
    echo "4. View Current Auto-scaling Status"
    echo "────────────────────────────────────────────────────────────────"
    read -p "Select option [1-4]: " choice
    
    case $choice in
        1)
            echo "🐝 DOCKER SWARM AUTO-SCALING"
            read -p "Enter service name: " service_name
            read -p "Enter minimum replicas: " min_replicas
            read -p "Enter maximum replicas: " max_replicas
            read -p "Enter CPU threshold (%): " cpu_threshold
            
            # Create auto-scaling script
            cat > "${SCRIPT_DIR}/autoscale_${service_name}.sh" << EOF
#!/bin/bash
SERVICE_NAME="$service_name"
MIN_REPLICAS=$min_replicas
MAX_REPLICAS=$max_replicas
CPU_THRESHOLD=$cpu_threshold

while true; do
    current_replicas=\$(docker service inspect \$SERVICE_NAME --format='{{.Spec.Replicas}}' 2>/dev/null || echo "0")
    cpu_usage=\$(docker stats --no-stream --format "table {{.CPUPerc}}" | tail -n +2 | sed 's/%//' | awk '{sum+=\$1} END {print sum/NR}')
    
    if (( \$(echo "\$cpu_usage > \$CPU_THRESHOLD" | bc -l) )) && [ \$current_replicas -lt \$MAX_REPLICAS ]; then
        new_replicas=\$((current_replicas + 1))
        docker service scale \$SERVICE_NAME=\$new_replicas
        echo "[Auto-Scale] Scaled up \$SERVICE_NAME to \$new_replicas replicas (CPU: \$cpu_usage%)"
    elif (( \$(echo "\$cpu_usage < \$((CPU_THRESHOLD / 2))" | bc -l) )) && [ \$current_replicas -gt \$MIN_REPLICAS ]; then
        new_replicas=\$((current_replicas - 1))
        docker service scale \$SERVICE_NAME=\$new_replicas
        echo "[Auto-Scale] Scaled down \$SERVICE_NAME to \$new_replicas replicas (CPU: \$cpu_usage%)"
    fi
    
    sleep 30
done
EOF
            chmod +x "${SCRIPT_DIR}/autoscale_${service_name}.sh"
            log_container "SUCCESS" "Auto-scaling configured for $service_name"
            ;;
        2)
            echo "☸️ KUBERNETES HPA CONFIGURATION"
            read -p "Enter deployment name: " deployment_name
            read -p "Enter minimum pods: " min_pods
            read -p "Enter maximum pods: " max_pods
            read -p "Enter CPU target (%): " cpu_target
            
            kubectl autoscale deployment "$deployment_name" --cpu-percent="$cpu_target" --min="$min_pods" --max="$max_pods"
            log_container "SUCCESS" "HPA configured for deployment $deployment_name"
            ;;
        3)
            echo "📊 CUSTOM METRICS AUTO-SCALING"
            echo "Feature under development..."
            ;;
        4)
            echo "📊 CURRENT AUTO-SCALING STATUS:"
            if command -v kubectl >/dev/null 2>&1; then
                echo "Kubernetes HPA:"
                kubectl get hpa
            fi
            echo -e "\nDocker Swarm Services:"
            docker service ls
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Main menu function
show_container_orchestration_menu() {
    while true; do
        clear
        echo "🐳 LOMP STACK - CONTAINER ORCHESTRATION MANAGER"
        echo "════════════════════════════════════════════════════════════════"
        echo "                    Next-Generation Platform v3.0"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "🔧 SETUP & INSTALLATION:"
        echo "1.  🐳 Install Docker"
        echo "2.  ☸️  Install Kubernetes"
        echo "3.  🐝 Initialize Docker Swarm"
        echo "4.  📦 Setup Private Registry"
        echo "5.  📊 Setup Monitoring"
        echo ""
        echo "🚀 MANAGEMENT INTERFACES:"
        echo "6.  🐳 Docker Container Management"
        echo "7.  ☸️  Kubernetes Cluster Management"
        echo "8.  🐝 Docker Swarm Management"
        echo "9.  📦 Multi-Platform Deployment"
        echo ""
        echo "🛡️ ADVANCED FEATURES:"
        echo "10. 🔒 Security Scanning"
        echo "11. 📈 Auto-scaling Configuration"
        echo "12. 🔄 Load Balancing Setup"
        echo "13. 💾 Backup & Recovery"
        echo "14. 📊 Performance Analytics"
        echo ""
        echo "ℹ️  INFORMATION & STATUS:"
        echo "15. 📋 System Status"
        echo "16. 📖 View Logs"
        echo "17. ⚙️  Configuration"
        echo "18. 📚 Documentation"
        echo ""
        echo "0.  🚪 Exit"
        echo "════════════════════════════════════════════════════════════════"
        read -p "Select option [0-18]: " choice
        
        case $choice in
            1)
                install_docker
                read -p "Press Enter to continue..."
                ;;
            2)
                install_kubernetes
                read -p "Press Enter to continue..."
                ;;
            3)
                init_docker_swarm
                read -p "Press Enter to continue..."
                ;;
            4)
                setup_docker_registry
                read -p "Press Enter to continue..."
                ;;
            5)
                setup_container_monitoring
                read -p "Press Enter to continue..."
                ;;
            6)
                manage_containers
                ;;
            7)
                manage_kubernetes
                ;;
            8)
                manage_docker_swarm
                ;;
            9)
                echo "🚀 MULTI-PLATFORM DEPLOYMENT"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            10)
                container_security_scan
                read -p "Press Enter to continue..."
                ;;
            11)
                configure_auto_scaling
                ;;
            12)
                echo "🔄 LOAD BALANCING SETUP"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            13)
                echo "💾 BACKUP & RECOVERY"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            14)
                echo "📊 PERFORMANCE ANALYTICS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            15)
                show_system_status
                read -p "Press Enter to continue..."
                ;;
            16)
                if [ -f "$CONTAINER_LOG" ]; then
                    tail -50 "$CONTAINER_LOG"
                else
                    echo "No logs found"
                fi
                read -p "Press Enter to continue..."
                ;;
            17)
                if [ -f "$CONTAINER_CONFIG" ]; then
                    cat "$CONTAINER_CONFIG" | jq '.'
                else
                    echo "No configuration found"
                fi
                read -p "Press Enter to continue..."
                ;;
            18)
                show_documentation
                read -p "Press Enter to continue..."
                ;;
            0)
                log_container "INFO" "Container Orchestration Manager stopped"
                exit 0
                ;;
            *)
                echo "Invalid option! Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# System status function
show_system_status() {
    echo "📊 CONTAINER ORCHESTRATION STATUS"
    echo "════════════════════════════════════════════════════════════════"
    
    # Docker status
    echo "🐳 DOCKER STATUS:"
    if command -v docker >/dev/null 2>&1; then
        docker version --format 'Version: {{.Server.Version}}' 2>/dev/null || echo "Docker not running"
        echo "Running containers: $(docker ps -q | wc -l)"
        echo "Total containers: $(docker ps -aq | wc -l)"
        echo "Images: $(docker images -q | wc -l)"
    else
        echo "Docker not installed"
    fi
    
    echo ""
    
    # Kubernetes status
    echo "☸️ KUBERNETES STATUS:"
    if command -v kubectl >/dev/null 2>&1; then
        kubectl version --client --short 2>/dev/null || echo "Kubectl installed but cluster not accessible"
        kubectl get nodes --no-headers 2>/dev/null | wc -l | xargs echo "Nodes:"
        kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l | xargs echo "Pods:"
    else
        echo "Kubernetes not installed"
    fi
    
    echo ""
    
    # Docker Swarm status
    echo "🐝 DOCKER SWARM STATUS:"
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "Swarm: Active"
        docker node ls 2>/dev/null | tail -n +2 | wc -l | xargs echo "Nodes:"
        docker service ls 2>/dev/null | tail -n +2 | wc -l | xargs echo "Services:"
    else
        echo "Swarm: Inactive"
    fi
    
    echo ""
    
    # System resources
    echo "💻 SYSTEM RESOURCES:"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%\n", $3/$2 * 100.0)}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2{printf "%s\n", $5}')"
}

# Documentation function
show_documentation() {
    cat << 'EOF'
📚 CONTAINER ORCHESTRATION MANAGER DOCUMENTATION
════════════════════════════════════════════════════════════════

🎯 OVERVIEW:
The Container Orchestration Manager provides comprehensive container 
management capabilities including Docker, Kubernetes, and Docker Swarm.

🚀 KEY FEATURES:
• Docker container management and registry
• Kubernetes cluster orchestration
• Docker Swarm cluster management
• Auto-scaling and load balancing
• Security scanning and monitoring
• Multi-platform deployment support

🔧 INSTALLATION ORDER:
1. Install Docker (required for all platforms)
2. Setup Private Registry (optional but recommended)
3. Install Kubernetes OR Initialize Docker Swarm
4. Setup Monitoring (recommended)
5. Configure Auto-scaling (optional)

📊 MONITORING:
• Prometheus: http://localhost:9090
• Grafana: http://localhost:3000 (admin/admin123)
• cAdvisor: http://localhost:8081
• Registry UI: http://localhost:8080

🛡️ SECURITY:
• Image vulnerability scanning with Trivy
• Network policies and secrets management
• Access control and authentication
• Regular security assessments

📖 TROUBLESHOOTING:
• Check logs: tail -f /path/to/container_orchestration.log
• Verify Docker: docker info
• Check Kubernetes: kubectl cluster-info
• Verify Swarm: docker node ls

📞 SUPPORT:
For technical support and feature requests, please refer to the
main LOMP Stack documentation or contact the development team.
EOF
}

#########################################################################
# Main Execution
#########################################################################

# Initialize
initialize_container_config

# Check if running as main script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_container_orchestration_menu
fi
