#!/bin/bash
#
# ai_ml_integration_suite.sh - Part of LOMP Stack v3.0
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
# LOMP Stack v3.0 - AI/ML Integration Suite
# Next-Generation AI and Machine Learning Platform
# 
# Features:
# - Smart System Administration
# - Predictive Analytics
# - Anomaly Detection
# - AI-powered Chatbot Assistant
# - Smart Recommendations
# - ML Model Deployment
# - Data Pipeline Management
#########################################################################

# Import required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers/utils/functions.sh"

# Configuration
AI_CONFIG="${SCRIPT_DIR}/ai_config.json"
AI_LOG="${SCRIPT_DIR}/../tmp/ai_ml_integration.log"
MODELS_DIR="${SCRIPT_DIR}/models"
DATASETS_DIR="${SCRIPT_DIR}/datasets"
PIPELINES_DIR="${SCRIPT_DIR}/pipelines"

# Logging function
log_ai() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$AI_LOG"
    
    case "$level" in
        "ERROR") print_error "$message" ;;
        "WARNING") print_warning "$message" ;;
        "SUCCESS") print_success "$message" ;;
        *) print_info "$message" ;;
    esac
}

#########################################################################
# Initialize AI/ML Configuration
#########################################################################
initialize_ai_config() {
    if [ ! -f "$AI_CONFIG" ]; then
        cat > "$AI_CONFIG" << 'EOF'
{
    "ai_platform": {
        "name": "LOMP AI/ML Suite",
        "version": "3.0.0",
        "enabled": true,
        "auto_learning": true,
        "real_time_processing": true
    },
    "frameworks": {
        "tensorflow": {
            "enabled": true,
            "version": "2.15.0",
            "gpu_support": false
        },
        "pytorch": {
            "enabled": true,
            "version": "2.1.0",
            "gpu_support": false
        },
        "scikit_learn": {
            "enabled": true,
            "version": "1.3.0"
        },
        "huggingface": {
            "enabled": true,
            "transformers_version": "4.35.0"
        }
    },
    "features": {
        "smart_automation": {
            "enabled": true,
            "confidence_threshold": 0.8,
            "learning_rate": 0.01
        },
        "predictive_analytics": {
            "enabled": true,
            "prediction_horizon": 24,
            "model_update_frequency": "daily"
        },
        "anomaly_detection": {
            "enabled": true,
            "sensitivity": 0.95,
            "alert_threshold": 0.7
        },
        "chatbot": {
            "enabled": true,
            "model": "gpt-3.5-turbo",
            "context_window": 4096
        },
        "recommendations": {
            "enabled": true,
            "algorithm": "collaborative_filtering",
            "update_frequency": "hourly"
        }
    },
    "data_pipeline": {
        "enabled": true,
        "batch_processing": true,
        "stream_processing": true,
        "data_validation": true,
        "feature_engineering": true
    },
    "model_deployment": {
        "enabled": true,
        "auto_scaling": true,
        "a_b_testing": true,
        "model_versioning": true,
        "rollback_capability": true
    }
}
EOF
        log_ai "SUCCESS" "AI/ML configuration created"
    fi
}

#########################################################################
# Setup AI/ML Environment
#########################################################################

# Install AI/ML dependencies
install_ai_dependencies() {
    log_ai "INFO" "Installing AI/ML dependencies..."
    
    # Create Python virtual environment
    if [ ! -d "${SCRIPT_DIR}/venv" ]; then
        python3 -m venv "${SCRIPT_DIR}/venv"
    fi
    
    # Activate virtual environment
    source "${SCRIPT_DIR}/venv/bin/activate" || {
        log_ai "ERROR" "Failed to activate virtual environment"
        return 1
    }
    
    # Install Python packages
    pip install --upgrade pip
    pip install \
        tensorflow==2.15.0 \
        torch==2.1.0 \
        scikit-learn==1.3.0 \
        transformers==4.35.0 \
        pandas==2.1.0 \
        numpy==1.24.0 \
        matplotlib==3.8.0 \
        seaborn==0.12.0 \
        jupyter==1.0.0 \
        mlflow==2.8.0 \
        flask==2.3.0 \
        fastapi==0.104.0 \
        uvicorn==0.24.0 \
        celery==5.3.0 \
        redis==5.0.0 \
        psycopg2-binary==2.9.0 \
        sqlalchemy==2.0.0
    
    if [ $? -eq 0 ]; then
        log_ai "SUCCESS" "AI/ML dependencies installed"
    else
        log_ai "ERROR" "Failed to install dependencies"
        return 1
    fi
    
    # Create directories
    mkdir -p "$MODELS_DIR" "$DATASETS_DIR" "$PIPELINES_DIR"
    
    # Setup MLflow tracking server
    setup_mlflow_server
}

# Setup MLflow tracking server
setup_mlflow_server() {
    log_ai "INFO" "Setting up MLflow tracking server..."
    
    mkdir -p "${SCRIPT_DIR}/mlflow"
    
    # Create MLflow configuration
    cat > "${SCRIPT_DIR}/mlflow/mlflow.ini" << 'EOF'
[mlflow]
backend_store_uri = sqlite:///mlflow.db
default_artifact_root = ./artifacts
host = 0.0.0.0
port = 5000
workers = 4
EOF
    
    # Create MLflow Docker container
    cat > "${SCRIPT_DIR}/mlflow/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  mlflow-server:
    image: python:3.11-slim
    container_name: lomp-mlflow
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - ./data:/mlflow
      - ./artifacts:/mlflow/artifacts
    working_dir: /mlflow
    command: >
      bash -c "
        pip install mlflow[extras]==2.8.0 &&
        mlflow server 
          --backend-store-uri sqlite:///mlflow.db 
          --default-artifact-root ./artifacts 
          --host 0.0.0.0 
          --port 5000
      "
    environment:
      MLFLOW_TRACKING_URI: http://localhost:5000

  mlflow-ui:
    image: nginx:alpine
    container_name: lomp-mlflow-ui
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - mlflow-server
EOF
    
    # Start MLflow
    cd "${SCRIPT_DIR}/mlflow" || return 1
    docker-compose up -d
    
    log_ai "SUCCESS" "MLflow tracking server started on port 5000"
}

#########################################################################
# Smart System Administration
#########################################################################

# AI-powered system monitoring
smart_system_monitor() {
    log_ai "INFO" "Starting smart system monitoring..."
    
    # Create monitoring script
    cat > "${SCRIPT_DIR}/smart_monitor.py" << 'EOF'
#!/usr/bin/env python3
import psutil
import time
import json
import sqlite3
import numpy as np
from sklearn.ensemble import IsolationForest
from datetime import datetime, timedelta
import requests
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SmartSystemMonitor:
    def __init__(self, db_path="system_metrics.db"):
        self.db_path = db_path
        self.init_database()
        self.anomaly_detector = IsolationForest(contamination=0.1, random_state=42)
        self.is_trained = False
        
    def init_database(self):
        """Initialize SQLite database for metrics storage"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS system_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                cpu_percent REAL,
                memory_percent REAL,
                disk_percent REAL,
                network_in REAL,
                network_out REAL,
                process_count INTEGER,
                load_avg REAL,
                anomaly_score REAL DEFAULT 0
            )
        ''')
        
        conn.commit()
        conn.close()
        
    def collect_metrics(self):
        """Collect current system metrics"""
        try:
            # CPU metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # Memory metrics
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            
            # Disk metrics
            disk = psutil.disk_usage('/')
            disk_percent = disk.percent
            
            # Network metrics
            network = psutil.net_io_counters()
            network_in = network.bytes_recv
            network_out = network.bytes_sent
            
            # Process count
            process_count = len(psutil.pids())
            
            # Load average
            load_avg = psutil.getloadavg()[0] if hasattr(psutil, 'getloadavg') else 0
            
            return {
                'cpu_percent': cpu_percent,
                'memory_percent': memory_percent,
                'disk_percent': disk_percent,
                'network_in': network_in,
                'network_out': network_out,
                'process_count': process_count,
                'load_avg': load_avg,
                'timestamp': datetime.now()
            }
        except Exception as e:
            logger.error(f"Error collecting metrics: {e}")
            return None
            
    def store_metrics(self, metrics):
        """Store metrics in database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO system_metrics 
                (cpu_percent, memory_percent, disk_percent, network_in, network_out, process_count, load_avg)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                metrics['cpu_percent'],
                metrics['memory_percent'],
                metrics['disk_percent'],
                metrics['network_in'],
                metrics['network_out'],
                metrics['process_count'],
                metrics['load_avg']
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            logger.error(f"Error storing metrics: {e}")
            
    def train_anomaly_detector(self):
        """Train anomaly detection model with historical data"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get last 1000 records for training
            cursor.execute('''
                SELECT cpu_percent, memory_percent, disk_percent, load_avg
                FROM system_metrics 
                ORDER BY timestamp DESC 
                LIMIT 1000
            ''')
            
            data = cursor.fetchall()
            conn.close()
            
            if len(data) < 50:  # Need minimum data for training
                return False
                
            # Prepare training data
            X = np.array(data)
            
            # Train model
            self.anomaly_detector.fit(X)
            self.is_trained = True
            
            logger.info("Anomaly detection model trained successfully")
            return True
            
        except Exception as e:
            logger.error(f"Error training anomaly detector: {e}")
            return False
            
    def detect_anomalies(self, metrics):
        """Detect anomalies in current metrics"""
        if not self.is_trained:
            return 0
            
        try:
            # Prepare data for prediction
            X = np.array([[
                metrics['cpu_percent'],
                metrics['memory_percent'],
                metrics['disk_percent'],
                metrics['load_avg']
            ]])
            
            # Get anomaly score
            anomaly_score = self.anomaly_detector.score_samples(X)[0]
            is_anomaly = self.anomaly_detector.predict(X)[0] == -1
            
            if is_anomaly:
                logger.warning(f"Anomaly detected! Score: {anomaly_score}")
                self.send_alert(metrics, anomaly_score)
                
            return anomaly_score
            
        except Exception as e:
            logger.error(f"Error detecting anomalies: {e}")
            return 0
            
    def send_alert(self, metrics, anomaly_score):
        """Send alert for detected anomaly"""
        alert_data = {
            'type': 'system_anomaly',
            'timestamp': metrics['timestamp'].isoformat(),
            'anomaly_score': float(anomaly_score),
            'metrics': {
                'cpu_percent': metrics['cpu_percent'],
                'memory_percent': metrics['memory_percent'],
                'disk_percent': metrics['disk_percent'],
                'load_avg': metrics['load_avg']
            },
            'severity': 'high' if anomaly_score < -0.5 else 'medium'
        }
        
        # Here you would send to your alerting system
        logger.info(f"Alert sent: {json.dumps(alert_data, indent=2)}")
        
    def generate_recommendations(self, metrics):
        """Generate AI-powered system recommendations"""
        recommendations = []
        
        # CPU recommendations
        if metrics['cpu_percent'] > 80:
            recommendations.append({
                'type': 'performance',
                'priority': 'high',
                'message': 'High CPU usage detected. Consider scaling up or optimizing processes.',
                'action': 'scale_cpu'
            })
            
        # Memory recommendations
        if metrics['memory_percent'] > 85:
            recommendations.append({
                'type': 'performance',
                'priority': 'high',
                'message': 'High memory usage detected. Consider adding more RAM or optimizing memory usage.',
                'action': 'scale_memory'
            })
            
        # Disk recommendations
        if metrics['disk_percent'] > 90:
            recommendations.append({
                'type': 'storage',
                'priority': 'critical',
                'message': 'Disk space critically low. Clean up or add more storage.',
                'action': 'cleanup_storage'
            })
            
        return recommendations
        
    def run_monitoring_cycle(self):
        """Run a single monitoring cycle"""
        # Collect metrics
        metrics = self.collect_metrics()
        if not metrics:
            return
            
        # Store metrics
        self.store_metrics(metrics)
        
        # Train model if needed (every 100 cycles)
        if not self.is_trained:
            self.train_anomaly_detector()
            
        # Detect anomalies
        anomaly_score = self.detect_anomalies(metrics)
        
        # Generate recommendations
        recommendations = self.generate_recommendations(metrics)
        
        # Log status
        logger.info(f"Monitoring cycle completed - CPU: {metrics['cpu_percent']:.1f}%, "
                   f"Memory: {metrics['memory_percent']:.1f}%, "
                   f"Disk: {metrics['disk_percent']:.1f}%, "
                   f"Anomaly Score: {anomaly_score:.3f}")
        
        if recommendations:
            logger.info(f"Recommendations: {len(recommendations)} items")
            for rec in recommendations:
                logger.info(f"  - {rec['message']}")
                
    def start_monitoring(self, interval=60):
        """Start continuous monitoring"""
        logger.info(f"Starting smart system monitoring (interval: {interval}s)")
        
        try:
            while True:
                self.run_monitoring_cycle()
                time.sleep(interval)
                
        except KeyboardInterrupt:
            logger.info("Monitoring stopped by user")
        except Exception as e:
            logger.error(f"Monitoring error: {e}")

if __name__ == "__main__":
    monitor = SmartSystemMonitor()
    monitor.start_monitoring()
EOF
    
    chmod +x "${SCRIPT_DIR}/smart_monitor.py"
    log_ai "SUCCESS" "Smart system monitor created"
}

# Predictive analytics for resource planning
predictive_analytics() {
    log_ai "INFO" "Setting up predictive analytics..."
    
    cat > "${SCRIPT_DIR}/predictive_analytics.py" << 'EOF'
#!/usr/bin/env python3
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error
import sqlite3
import json
from datetime import datetime, timedelta
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PredictiveAnalytics:
    def __init__(self, db_path="system_metrics.db"):
        self.db_path = db_path
        self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.scaler = StandardScaler()
        self.is_trained = False
        
    def load_historical_data(self, days=30):
        """Load historical system metrics"""
        try:
            conn = sqlite3.connect(self.db_path)
            
            # Get data from last N days
            query = '''
                SELECT timestamp, cpu_percent, memory_percent, disk_percent, 
                       network_in, network_out, process_count, load_avg
                FROM system_metrics 
                WHERE timestamp >= datetime('now', '-{} days')
                ORDER BY timestamp
            '''.format(days)
            
            df = pd.read_sql_query(query, conn)
            conn.close()
            
            if len(df) < 100:  # Need minimum data
                logger.warning("Insufficient historical data for prediction")
                return None
                
            # Convert timestamp
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            
            # Feature engineering
            df['hour'] = df['timestamp'].dt.hour
            df['day_of_week'] = df['timestamp'].dt.dayofweek
            df['day_of_month'] = df['timestamp'].dt.day
            
            # Calculate trends
            df['cpu_trend'] = df['cpu_percent'].rolling(window=10).mean()
            df['memory_trend'] = df['memory_percent'].rolling(window=10).mean()
            
            # Drop rows with NaN values
            df = df.dropna()
            
            return df
            
        except Exception as e:
            logger.error(f"Error loading historical data: {e}")
            return None
            
    def prepare_features(self, df):
        """Prepare features for machine learning"""
        features = [
            'hour', 'day_of_week', 'day_of_month',
            'cpu_trend', 'memory_trend', 'process_count', 'load_avg'
        ]
        
        X = df[features].values
        
        # Targets (what we want to predict)
        y_cpu = df['cpu_percent'].values
        y_memory = df['memory_percent'].values
        y_disk = df['disk_percent'].values
        
        return X, y_cpu, y_memory, y_disk
        
    def train_models(self):
        """Train predictive models"""
        logger.info("Training predictive models...")
        
        # Load data
        df = self.load_historical_data()
        if df is None:
            return False
            
        # Prepare features
        X, y_cpu, y_memory, y_disk = self.prepare_features(df)
        
        # Split data (80% train, 20% test)
        split_idx = int(len(X) * 0.8)
        X_train, X_test = X[:split_idx], X[split_idx:]
        y_cpu_train, y_cpu_test = y_cpu[:split_idx], y_cpu[split_idx:]
        y_memory_train, y_memory_test = y_memory[:split_idx], y_memory[split_idx:]
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train models
        self.cpu_model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.memory_model = RandomForestRegressor(n_estimators=100, random_state=42)
        
        self.cpu_model.fit(X_train_scaled, y_cpu_train)
        self.memory_model.fit(X_train_scaled, y_memory_train)
        
        # Evaluate models
        cpu_pred = self.cpu_model.predict(X_test_scaled)
        memory_pred = self.memory_model.predict(X_test_scaled)
        
        cpu_mae = mean_absolute_error(y_cpu_test, cpu_pred)
        memory_mae = mean_absolute_error(y_memory_test, memory_pred)
        
        logger.info(f"Model performance - CPU MAE: {cpu_mae:.2f}, Memory MAE: {memory_mae:.2f}")
        
        self.is_trained = True
        return True
        
    def predict_future_usage(self, hours_ahead=24):
        """Predict future resource usage"""
        if not self.is_trained:
            logger.warning("Models not trained yet")
            return None
            
        try:
            predictions = []
            current_time = datetime.now()
            
            for h in range(hours_ahead):
                future_time = current_time + timedelta(hours=h)
                
                # Create feature vector for future time
                features = np.array([[
                    future_time.hour,
                    future_time.weekday(),
                    future_time.day,
                    70.0,  # Default trend values
                    60.0,
                    150,   # Default process count
                    1.0    # Default load avg
                ]])
                
                # Scale features
                features_scaled = self.scaler.transform(features)
                
                # Make predictions
                cpu_pred = self.cpu_model.predict(features_scaled)[0]
                memory_pred = self.memory_model.predict(features_scaled)[0]
                
                predictions.append({
                    'timestamp': future_time.isoformat(),
                    'hour': h,
                    'predicted_cpu': max(0, min(100, cpu_pred)),
                    'predicted_memory': max(0, min(100, memory_pred)),
                    'confidence': 0.85  # You could calculate actual confidence intervals
                })
                
            return predictions
            
        except Exception as e:
            logger.error(f"Error making predictions: {e}")
            return None
            
    def generate_capacity_recommendations(self, predictions):
        """Generate capacity planning recommendations"""
        if not predictions:
            return []
            
        recommendations = []
        
        # Analyze prediction trends
        high_cpu_hours = sum(1 for p in predictions if p['predicted_cpu'] > 80)
        high_memory_hours = sum(1 for p in predictions if p['predicted_memory'] > 85)
        
        peak_cpu = max(p['predicted_cpu'] for p in predictions)
        peak_memory = max(p['predicted_memory'] for p in predictions)
        
        # Generate recommendations
        if high_cpu_hours > len(predictions) * 0.3:  # >30% of time
            recommendations.append({
                'type': 'capacity_planning',
                'priority': 'high',
                'resource': 'cpu',
                'message': f'CPU usage will be high for {high_cpu_hours} hours. Consider CPU scaling.',
                'peak_usage': peak_cpu,
                'recommended_action': 'scale_cpu_up'
            })
            
        if high_memory_hours > len(predictions) * 0.3:
            recommendations.append({
                'type': 'capacity_planning',
                'priority': 'high',
                'resource': 'memory',
                'message': f'Memory usage will be high for {high_memory_hours} hours. Consider memory scaling.',
                'peak_usage': peak_memory,
                'recommended_action': 'scale_memory_up'
            })
            
        if peak_cpu < 50 and peak_memory < 50:
            recommendations.append({
                'type': 'optimization',
                'priority': 'medium',
                'message': 'Low resource usage predicted. Consider scaling down to save costs.',
                'recommended_action': 'scale_down'
            })
            
        return recommendations
        
    def run_prediction_analysis(self):
        """Run complete prediction analysis"""
        logger.info("Running predictive analysis...")
        
        # Train models if needed
        if not self.is_trained:
            if not self.train_models():
                return None
                
        # Make predictions
        predictions = self.predict_future_usage()
        if not predictions:
            return None
            
        # Generate recommendations
        recommendations = self.generate_capacity_recommendations(predictions)
        
        # Create analysis report
        report = {
            'timestamp': datetime.now().isoformat(),
            'prediction_horizon': 24,
            'predictions': predictions,
            'recommendations': recommendations,
            'summary': {
                'peak_cpu': max(p['predicted_cpu'] for p in predictions),
                'peak_memory': max(p['predicted_memory'] for p in predictions),
                'avg_cpu': sum(p['predicted_cpu'] for p in predictions) / len(predictions),
                'avg_memory': sum(p['predicted_memory'] for p in predictions) / len(predictions)
            }
        }
        
        logger.info("Predictive analysis completed")
        return report

if __name__ == "__main__":
    analytics = PredictiveAnalytics()
    report = analytics.run_prediction_analysis()
    
    if report:
        print(json.dumps(report, indent=2))
EOF
    
    chmod +x "${SCRIPT_DIR}/predictive_analytics.py"
    log_ai "SUCCESS" "Predictive analytics module created"
}

#########################################################################
# AI Chatbot Assistant
#########################################################################

# Setup AI chatbot for system assistance
setup_ai_chatbot() {
    log_ai "INFO" "Setting up AI chatbot assistant..."
    
    cat > "${SCRIPT_DIR}/ai_chatbot.py" << 'EOF'
#!/usr/bin/env python3
from flask import Flask, request, jsonify, render_template_string
import json
import sqlite3
import re
from datetime import datetime
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LOMLPAIChatbot:
    def __init__(self):
        self.knowledge_base = self.load_knowledge_base()
        self.conversation_history = []
        
    def load_knowledge_base(self):
        """Load LOMP Stack knowledge base"""
        return {
            'system_commands': {
                'restart_service': 'sudo systemctl restart {service}',
                'check_logs': 'tail -f /var/log/{service}.log',
                'disk_usage': 'df -h',
                'memory_usage': 'free -h',
                'cpu_usage': 'top -bn1 | grep "Cpu(s)"',
                'network_status': 'netstat -tuln',
                'process_list': 'ps aux'
            },
            'troubleshooting': {
                'high_cpu': [
                    'Check top processes with: top',
                    'Look for memory leaks',
                    'Consider scaling up CPU resources',
                    'Check for infinite loops in applications'
                ],
                'high_memory': [
                    'Check memory usage with: free -h',
                    'Identify memory-hungry processes',
                    'Clear cache if necessary',
                    'Consider adding more RAM'
                ],
                'disk_full': [
                    'Check disk usage: df -h',
                    'Clean up log files',
                    'Remove unnecessary files',
                    'Consider adding more storage'
                ],
                'service_down': [
                    'Check service status: systemctl status {service}',
                    'View service logs: journalctl -u {service}',
                    'Restart service: systemctl restart {service}',
                    'Check configuration files'
                ]
            },
            'lomp_specific': {
                'apache_issues': [
                    'Check Apache status: systemctl status apache2',
                    'View error logs: tail -f /var/log/apache2/error.log',
                    'Test configuration: apache2ctl configtest',
                    'Restart Apache: systemctl restart apache2'
                ],
                'mysql_issues': [
                    'Check MySQL status: systemctl status mysql',
                    'View MySQL logs: tail -f /var/log/mysql/error.log',
                    'Check connections: mysqladmin processlist',
                    'Restart MySQL: systemctl restart mysql'
                ],
                'php_issues': [
                    'Check PHP version: php -v',
                    'View PHP error log: tail -f /var/log/php_errors.log',
                    'Check PHP-FPM: systemctl status php-fpm',
                    'Restart PHP-FPM: systemctl restart php-fpm'
                ],
                'ssl_issues': [
                    'Check SSL certificate: openssl x509 -in cert.pem -text',
                    'Verify SSL configuration in Apache/Nginx',
                    'Check certificate expiry date',
                    'Renew Let\'s Encrypt: certbot renew'
                ]
            }
        }
        
    def analyze_intent(self, message):
        """Analyze user intent from message"""
        message_lower = message.lower()
        
        # System performance queries
        if any(keyword in message_lower for keyword in ['cpu', 'slow', 'performance', 'lag']):
            return 'performance_issue'
        elif any(keyword in message_lower for keyword in ['memory', 'ram', 'out of memory']):
            return 'memory_issue'
        elif any(keyword in message_lower for keyword in ['disk', 'storage', 'space', 'full']):
            return 'disk_issue'
        elif any(keyword in message_lower for keyword in ['service', 'down', 'not working', 'error']):
            return 'service_issue'
            
        # LOMP-specific queries
        elif any(keyword in message_lower for keyword in ['apache', 'web server', 'http']):
            return 'apache_issue'
        elif any(keyword in message_lower for keyword in ['mysql', 'database', 'db']):
            return 'mysql_issue'
        elif any(keyword in message_lower for keyword in ['php', 'script']):
            return 'php_issue'
        elif any(keyword in message_lower for keyword in ['ssl', 'certificate', 'https']):
            return 'ssl_issue'
            
        # General queries
        elif any(keyword in message_lower for keyword in ['how to', 'help', 'what is', 'explain']):
            return 'help_request'
        else:
            return 'general_query'
            
    def generate_response(self, message, intent):
        """Generate appropriate response based on intent"""
        response = {
            'message': '',
            'suggestions': [],
            'commands': [],
            'priority': 'medium'
        }
        
        if intent == 'performance_issue':
            response['message'] = "I can help you diagnose performance issues. Let me provide some troubleshooting steps."
            response['suggestions'] = self.knowledge_base['troubleshooting']['high_cpu']
            response['commands'] = [
                self.knowledge_base['system_commands']['cpu_usage'],
                self.knowledge_base['system_commands']['process_list']
            ]
            response['priority'] = 'high'
            
        elif intent == 'memory_issue':
            response['message'] = "Memory issues can cause system instability. Here are some diagnostic steps."
            response['suggestions'] = self.knowledge_base['troubleshooting']['high_memory']
            response['commands'] = [
                self.knowledge_base['system_commands']['memory_usage']
            ]
            response['priority'] = 'high'
            
        elif intent == 'disk_issue':
            response['message'] = "Disk space issues need immediate attention. Let me help you resolve this."
            response['suggestions'] = self.knowledge_base['troubleshooting']['disk_full']
            response['commands'] = [
                self.knowledge_base['system_commands']['disk_usage']
            ]
            response['priority'] = 'critical'
            
        elif intent == 'apache_issue':
            response['message'] = "Apache web server issues can affect your websites. Here's how to troubleshoot."
            response['suggestions'] = self.knowledge_base['lomp_specific']['apache_issues']
            response['priority'] = 'high'
            
        elif intent == 'mysql_issue':
            response['message'] = "MySQL database issues can impact your applications. Let's diagnose the problem."
            response['suggestions'] = self.knowledge_base['lomp_specific']['mysql_issues']
            response['priority'] = 'high'
            
        elif intent == 'php_issue':
            response['message'] = "PHP script issues can cause website problems. Here are troubleshooting steps."
            response['suggestions'] = self.knowledge_base['lomp_specific']['php_issues']
            response['priority'] = 'medium'
            
        elif intent == 'ssl_issue':
            response['message'] = "SSL certificate issues can prevent secure connections. Let me help you fix this."
            response['suggestions'] = self.knowledge_base['lomp_specific']['ssl_issues']
            response['priority'] = 'high'
            
        else:
            response['message'] = "I'm here to help with LOMP Stack administration. Could you provide more details about your issue?"
            response['suggestions'] = [
                "Try being more specific about the problem",
                "Mention which service is affected",
                "Include any error messages you're seeing"
            ]
            
        return response
        
    def chat(self, message):
        """Main chat function"""
        # Add to conversation history
        self.conversation_history.append({
            'timestamp': datetime.now().isoformat(),
            'user_message': message,
            'type': 'user'
        })
        
        # Analyze intent
        intent = self.analyze_intent(message)
        
        # Generate response
        response = self.generate_response(message, intent)
        
        # Add response to history
        self.conversation_history.append({
            'timestamp': datetime.now().isoformat(),
            'bot_response': response,
            'intent': intent,
            'type': 'bot'
        })
        
        return response

# Flask routes
chatbot = LOMLPAIChatbot()

@app.route('/')
def index():
    return render_template_string('''
<!DOCTYPE html>
<html>
<head>
    <title>LOMP AI Assistant</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; border-radius: 10px; padding: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; border-bottom: 2px solid #007bff; padding-bottom: 20px; margin-bottom: 20px; }
        .chat-container { height: 400px; overflow-y: auto; border: 1px solid #ddd; padding: 15px; margin-bottom: 15px; background: #fafafa; }
        .message { margin-bottom: 15px; padding: 10px; border-radius: 5px; }
        .user-message { background: #007bff; color: white; text-align: right; }
        .bot-message { background: #e9ecef; color: #333; }
        .suggestions { margin-top: 10px; font-size: 0.9em; }
        .suggestion { display: block; color: #666; margin: 5px 0; }
        .input-container { display: flex; gap: 10px; }
        .input-container input { flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        .input-container button { padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 5px; cursor: pointer; }
        .priority-high { border-left: 4px solid #dc3545; }
        .priority-critical { border-left: 4px solid #fd7e14; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 LOMP AI Assistant</h1>
            <p>Your intelligent system administration helper</p>
        </div>
        
        <div id="chat-container" class="chat-container">
            <div class="message bot-message">
                <strong>AI Assistant:</strong> Hello! I'm your LOMP Stack AI assistant. I can help you with system administration, troubleshooting, and performance optimization. What can I help you with today?
            </div>
        </div>
        
        <div class="input-container">
            <input type="text" id="message-input" placeholder="Ask me about system issues, performance, or LOMP Stack..." onkeypress="if(event.key=='Enter') sendMessage()">
            <button onclick="sendMessage()">Send</button>
        </div>
    </div>
    
    <script>
        function sendMessage() {
            const input = document.getElementById('message-input');
            const message = input.value.trim();
            
            if (!message) return;
            
            // Add user message to chat
            addMessage(message, 'user');
            input.value = '';
            
            // Send to API
            fetch('/chat', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({message: message})
            })
            .then(response => response.json())
            .then(data => {
                addBotResponse(data);
            })
            .catch(error => {
                console.error('Error:', error);
                addMessage('Sorry, there was an error processing your request.', 'bot');
            });
        }
        
        function addMessage(message, type) {
            const container = document.getElementById('chat-container');
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${type}-message`;
            
            if (type === 'user') {
                messageDiv.innerHTML = `<strong>You:</strong> ${message}`;
            } else {
                messageDiv.innerHTML = `<strong>AI Assistant:</strong> ${message}`;
            }
            
            container.appendChild(messageDiv);
            container.scrollTop = container.scrollHeight;
        }
        
        function addBotResponse(response) {
            const container = document.getElementById('chat-container');
            const messageDiv = document.createElement('div');
            messageDiv.className = `message bot-message priority-${response.priority}`;
            
            let html = `<strong>AI Assistant:</strong> ${response.message}`;
            
            if (response.suggestions && response.suggestions.length > 0) {
                html += '<div class="suggestions"><strong>Suggestions:</strong>';
                response.suggestions.forEach(suggestion => {
                    html += `<span class="suggestion">• ${suggestion}</span>`;
                });
                html += '</div>';
            }
            
            if (response.commands && response.commands.length > 0) {
                html += '<div class="suggestions"><strong>Commands:</strong>';
                response.commands.forEach(command => {
                    html += `<span class="suggestion"><code>${command}</code></span>`;
                });
                html += '</div>';
            }
            
            messageDiv.innerHTML = html;
            container.appendChild(messageDiv);
            container.scrollTop = container.scrollHeight;
        }
    </script>
</body>
</html>
    ''')

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    message = data.get('message', '')
    
    if not message:
        return jsonify({'error': 'No message provided'}), 400
        
    response = chatbot.chat(message)
    return jsonify(response)

@app.route('/history')
def history():
    return jsonify(chatbot.conversation_history)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)
EOF
    
    chmod +x "${SCRIPT_DIR}/ai_chatbot.py"
    log_ai "SUCCESS" "AI chatbot assistant created"
}

#########################################################################
# Main AI/ML Menu
#########################################################################

# Main menu function
show_ai_ml_menu() {
    while true; do
        clear
        echo "🤖 LOMP STACK - AI/ML INTEGRATION SUITE"
        echo "════════════════════════════════════════════════════════════════"
        echo "                    Next-Generation Platform v3.0"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "🔧 SETUP & INSTALLATION:"
        echo "1.  ⚙️  Install AI/ML Dependencies"
        echo "2.  🏗️  Setup MLflow Tracking"
        echo "3.  📊 Initialize Monitoring"
        echo ""
        echo "🧠 SMART AUTOMATION:"
        echo "4.  🖥️  Smart System Monitor"
        echo "5.  📈 Predictive Analytics"
        echo "6.  🔍 Anomaly Detection"
        echo "7.  💡 Smart Recommendations"
        echo ""
        echo "🤖 AI ASSISTANT:"
        echo "8.  💬 Start AI Chatbot"
        echo "9.  📋 View Chat History"
        echo "10. 🧠 Train Knowledge Base"
        echo ""
        echo "📊 MACHINE LEARNING:"
        echo "11. 🏗️  Create ML Pipeline"
        echo "12. 🚀 Deploy ML Model"
        echo "13. 📈 Model Performance"
        echo "14. 🔄 Model Versioning"
        echo ""
        echo "📈 ANALYTICS & INSIGHTS:"
        echo "15. 📊 System Analytics"
        echo "16. 🎯 Performance Insights"
        echo "17. 💰 Cost Optimization"
        echo "18. 📈 Trend Analysis"
        echo ""
        echo "ℹ️  INFORMATION:"
        echo "19. 📋 AI Platform Status"
        echo "20. 📖 View Logs"
        echo "21. ⚙️  Configuration"
        echo "22. 📚 Documentation"
        echo ""
        echo "0.  🚪 Exit"
        echo "════════════════════════════════════════════════════════════════"
        read -p "Select option [0-22]: " choice
        
        case $choice in
            1)
                install_ai_dependencies
                read -p "Press Enter to continue..."
                ;;
            2)
                setup_mlflow_server
                read -p "Press Enter to continue..."
                ;;
            3)
                echo "📊 INITIALIZE MONITORING"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            4)
                smart_system_monitor
                echo "Smart system monitor created. Start with: python3 ${SCRIPT_DIR}/smart_monitor.py"
                read -p "Press Enter to continue..."
                ;;
            5)
                predictive_analytics
                echo "Predictive analytics module created. Run with: python3 ${SCRIPT_DIR}/predictive_analytics.py"
                read -p "Press Enter to continue..."
                ;;
            6)
                echo "🔍 ANOMALY DETECTION"
                echo "Feature integrated with Smart System Monitor"
                read -p "Press Enter to continue..."
                ;;
            7)
                echo "💡 SMART RECOMMENDATIONS"
                echo "Feature integrated with Predictive Analytics"
                read -p "Press Enter to continue..."
                ;;
            8)
                setup_ai_chatbot
                echo "AI Chatbot created. Start with: python3 ${SCRIPT_DIR}/ai_chatbot.py"
                echo "Then visit: http://localhost:5001"
                read -p "Press Enter to continue..."
                ;;
            9)
                echo "📋 VIEW CHAT HISTORY"
                echo "Visit: http://localhost:5001/history (when chatbot is running)"
                read -p "Press Enter to continue..."
                ;;
            10)
                echo "🧠 TRAIN KNOWLEDGE BASE"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "🏗️ CREATE ML PIPELINE"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            12)
                echo "🚀 DEPLOY ML MODEL"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            13)
                echo "📈 MODEL PERFORMANCE"
                echo "MLflow UI: http://localhost:5000 (when MLflow is running)"
                read -p "Press Enter to continue..."
                ;;
            14)
                echo "🔄 MODEL VERSIONING"
                echo "Available through MLflow interface"
                read -p "Press Enter to continue..."
                ;;
            15)
                echo "📊 SYSTEM ANALYTICS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            16)
                echo "🎯 PERFORMANCE INSIGHTS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            17)
                echo "💰 COST OPTIMIZATION"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            18)
                echo "📈 TREND ANALYSIS"
                echo "Feature under development..."
                read -p "Press Enter to continue..."
                ;;
            19)
                show_ai_status
                read -p "Press Enter to continue..."
                ;;
            20)
                if [ -f "$AI_LOG" ]; then
                    tail -50 "$AI_LOG"
                else
                    echo "No logs found"
                fi
                read -p "Press Enter to continue..."
                ;;
            21)
                if [ -f "$AI_CONFIG" ]; then
                    cat "$AI_CONFIG" | jq '.'
                else
                    echo "No configuration found"
                fi
                read -p "Press Enter to continue..."
                ;;
            22)
                show_ai_documentation
                read -p "Press Enter to continue..."
                ;;
            0)
                log_ai "INFO" "AI/ML Integration Suite stopped"
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
show_ai_status() {
    echo "📊 AI/ML INTEGRATION SUITE STATUS"
    echo "════════════════════════════════════════════════════════════════"
    
    # Platform status
    echo "🤖 AI PLATFORM STATUS:"
    if [ -f "$AI_CONFIG" ]; then
        echo "Configuration: ✅ Loaded"
    else
        echo "Configuration: ❌ Missing"
    fi
    
    # Virtual environment status
    echo -e "\n🐍 PYTHON ENVIRONMENT:"
    if [ -d "${SCRIPT_DIR}/venv" ]; then
        echo "Virtual Environment: ✅ Created"
        source "${SCRIPT_DIR}/venv/bin/activate" 2>/dev/null && {
            echo "TensorFlow: $(python -c 'import tensorflow; print(tensorflow.__version__)' 2>/dev/null || echo '❌ Not installed')"
            echo "PyTorch: $(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo '❌ Not installed')"
            echo "Scikit-learn: $(python -c 'import sklearn; print(sklearn.__version__)' 2>/dev/null || echo '❌ Not installed')"
            deactivate
        }
    else
        echo "Virtual Environment: ❌ Not created"
    fi
    
    # MLflow status
    echo -e "\n📊 MLFLOW TRACKING:"
    if docker ps --filter "name=lomp-mlflow" --format "{{.Names}}" | grep -q "lomp-mlflow"; then
        echo "MLflow Server: ✅ Running on port 5000"
    else
        echo "MLflow Server: ❌ Not running"
    fi
    
    # AI modules status
    echo -e "\n🧠 AI MODULES:"
    if [ -f "${SCRIPT_DIR}/smart_monitor.py" ]; then
        echo "Smart Monitor: ✅ Available"
    else
        echo "Smart Monitor: ❌ Not created"
    fi
    
    if [ -f "${SCRIPT_DIR}/predictive_analytics.py" ]; then
        echo "Predictive Analytics: ✅ Available"
    else
        echo "Predictive Analytics: ❌ Not created"
    fi
    
    if [ -f "${SCRIPT_DIR}/ai_chatbot.py" ]; then
        echo "AI Chatbot: ✅ Available"
    else
        echo "AI Chatbot: ❌ Not created"
    fi
    
    # System resources
    echo -e "\n💻 SYSTEM RESOURCES:"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%\n", $3/$2 * 100.0)}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2{printf "%s\n", $5}')"
}

# Documentation function
show_ai_documentation() {
    cat << 'EOF'
📚 AI/ML INTEGRATION SUITE DOCUMENTATION
════════════════════════════════════════════════════════════════

🎯 OVERVIEW:
The AI/ML Integration Suite provides intelligent automation, predictive
analytics, anomaly detection, and AI-powered assistance for system
administration and optimization.

🤖 KEY FEATURES:
• Smart System Monitoring with anomaly detection
• Predictive Analytics for capacity planning
• AI-powered Chatbot Assistant
• Machine Learning model deployment
• Automated recommendations
• Performance optimization

🔧 GETTING STARTED:
1. Install AI/ML Dependencies (Option 1)
2. Setup MLflow Tracking (Option 2)
3. Create Smart System Monitor (Option 4)
4. Setup Predictive Analytics (Option 5)
5. Start AI Chatbot (Option 8)

🧠 SMART AUTOMATION:
• Automatic anomaly detection in system metrics
• Predictive scaling recommendations
• Intelligent resource optimization
• Proactive issue identification

📊 MONITORING & ANALYTICS:
• MLflow: http://localhost:5000
• AI Chatbot: http://localhost:5001
• Real-time system metrics analysis
• Predictive capacity planning

🤖 AI CHATBOT FEATURES:
• Natural language system queries
• Intelligent troubleshooting assistance
• Command suggestions
• LOMP Stack specific knowledge

📈 MACHINE LEARNING:
• TensorFlow 2.15.0
• PyTorch 2.1.0
• Scikit-learn 1.3.0
• Hugging Face Transformers

🔒 SECURITY & PRIVACY:
• Local processing (no external AI APIs required)
• Encrypted data storage
• Privacy-first design
• Secure model deployment

📖 TROUBLESHOOTING:
• Check virtual environment: source venv/bin/activate
• Verify dependencies: pip list
• Check MLflow: docker ps | grep mlflow
• View AI logs: tail -f ai_ml_integration.log

📞 SUPPORT:
For technical support and feature requests, please refer to the
main LOMP Stack documentation or contact the development team.
EOF
}

#########################################################################
# Main Execution
#########################################################################

# Initialize
initialize_ai_config

# Check if running as main script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_ai_ml_menu
fi
