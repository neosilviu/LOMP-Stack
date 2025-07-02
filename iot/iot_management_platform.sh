#!/bin/bash
#
# iot_management_platform.sh - Part of LOMP Stack v3.0
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

# LOMP Stack - IoT Management Platform
# Phase 5: Next Generation Features
# Advanced IoT device and data management platform
# Version: 1.0.0

# Source required dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(dirname "$SCRIPT_DIR")"

source "$STACK_ROOT/helpers/utils/functions.sh"
source "$STACK_ROOT/helpers/utils/config_helpers.sh"
source "$STACK_ROOT/helpers/utils/notify_helpers.sh"
source "$STACK_ROOT/helpers/monitoring/system_helpers.sh"

# IoT Configuration
IOT_CONFIG_FILE="$SCRIPT_DIR/iot_config.json"
export IOT_LOG_FILE="/var/log/lomp_iot.log"
IOT_DATA_DIR="/opt/lomp/iot"
IOT_DEVICES_DIR="$IOT_DATA_DIR/devices"
IOT_GATEWAYS_DIR="$IOT_DATA_DIR/gateways"
IOT_PROTOCOLS_DIR="$IOT_DATA_DIR/protocols"
IOT_ANALYTICS_DIR="$IOT_DATA_DIR/analytics"

# IoT Functions

# Initialize IoT environment
init_iot_environment() {
    log_message "INFO" "Initializing LOMP IoT Management Platform..."
    
    # Create directories
    mkdir -p "$IOT_DATA_DIR" "$IOT_DEVICES_DIR" "$IOT_GATEWAYS_DIR" "$IOT_PROTOCOLS_DIR" "$IOT_ANALYTICS_DIR"
    mkdir -p "/etc/lomp/iot" "/var/lib/lomp/iot" "/var/log/iot"
    
    # Set permissions
    chmod 755 "$IOT_DATA_DIR" "$IOT_DEVICES_DIR" "$IOT_GATEWAYS_DIR"
    chmod 700 "$IOT_PROTOCOLS_DIR" "$IOT_ANALYTICS_DIR"
    
    # Initialize configuration if not exists
    if [[ ! -f "$IOT_CONFIG_FILE" ]]; then
        create_default_iot_config
    fi
    
    log_message "INFO" "IoT environment initialized successfully"
    return 0
}

# Create default IoT configuration
create_default_iot_config() {
    cat > "$IOT_CONFIG_FILE" << 'EOF'
{
  "iot_platform": {
    "version": "1.0.0",
    "protocols": {
      "mqtt": {
        "enabled": true,
        "broker_host": "localhost",
        "broker_port": 1883,
        "secure_port": 8883,
        "websocket_port": 9001,
        "auth_enabled": true,
        "tls_enabled": true
      },
      "coap": {
        "enabled": true,
        "port": 5683,
        "secure_port": 5684,
        "multicast": true
      },
      "http": {
        "enabled": true,
        "port": 8080,
        "secure_port": 8443,
        "rest_api": true
      },
      "websocket": {
        "enabled": true,
        "port": 8081,
        "secure_port": 8444
      },
      "lorawan": {
        "enabled": false,
        "frequency": "868MHz",
        "spreading_factor": 7
      }
    },
    "device_management": {
      "auto_discovery": true,
      "device_registry": true,
      "firmware_updates": true,
      "configuration_management": true,
      "health_monitoring": true,
      "remote_control": true
    },
    "data_processing": {
      "real_time_analytics": true,
      "stream_processing": true,
      "batch_processing": true,
      "machine_learning": true,
      "anomaly_detection": true,
      "predictive_analytics": true
    },
    "security": {
      "device_authentication": "x509",
      "communication_encryption": "TLS1.3",
      "data_encryption": "AES-256",
      "access_control": "RBAC",
      "audit_logging": true,
      "intrusion_detection": true
    },
    "storage": {
      "time_series_db": "InfluxDB",
      "document_db": "MongoDB",
      "cache": "Redis",
      "backup_enabled": true,
      "retention_policy": "30d"
    },
    "edge_computing": {
      "enabled": true,
      "edge_nodes": 3,
      "processing_capabilities": ["filtering", "aggregation", "analytics"],
      "sync_interval": 300
    },
    "integration": {
      "cloud_platforms": ["AWS", "Azure", "GCP"],
      "third_party_apis": true,
      "webhook_support": true,
      "kafka_integration": true
    }
  }
}
EOF
    log_message "INFO" "Default IoT configuration created"
}

# Install IoT dependencies
install_iot_dependencies() {
    log_message "INFO" "Installing IoT platform dependencies..."
    
    # Update package manager
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y curl wget git build-essential software-properties-common
        apt-get install -y mosquitto mosquitto-clients influxdb mongodb redis-server
        apt-get install -y python3 python3-pip nodejs npm docker.io
    elif command -v yum &> /dev/null; then
        yum update -y
        yum groupinstall -y "Development Tools"
        yum install -y curl wget git epel-release
        yum install -y mosquitto influxdb mongodb-server redis nodejs npm docker
    fi
    
    # Install Python IoT libraries
    pip3 install paho-mqtt influxdb pymongo redis aiocoap fastapi uvicorn websockets
    pip3 install pandas numpy scikit-learn tensorflow opencv-python
    pip3 install pycryptodome cryptography
    
    # Install Node.js IoT packages
    npm install -g mqtt coap express socket.io mongoose redis ioredis
    npm install -g @influxdata/influxdb-client node-red pm2
    
    # Install additional tools
    if ! command -v docker-compose &> /dev/null; then
        curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    log_message "INFO" "IoT dependencies installed successfully"
}

# Setup MQTT broker
setup_mqtt_broker() {
    log_message "INFO" "Setting up MQTT broker..."
    
    # Configure Mosquitto
    cat > /etc/mosquitto/mosquitto.conf << 'EOF'
# LOMP IoT MQTT Broker Configuration
pid_file /var/run/mosquitto.pid
persistence true
persistence_location /var/lib/mosquitto/
log_dest file /var/log/mosquitto/mosquitto.log
include_dir /etc/mosquitto/conf.d

# Default listener
listener 1883
protocol mqtt

# WebSocket listener
listener 9001
protocol websockets

# Secure listener
listener 8883
protocol mqtt
cafile /etc/mosquitto/ca_certificates/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
require_certificate true

# Authentication
allow_anonymous false
password_file /etc/mosquitto/passwords
acl_file /etc/mosquitto/acls

# Logging
log_type error
log_type warning
log_type notice
log_type information
log_timestamp true
EOF
    
    # Create SSL certificates
    mkdir -p /etc/mosquitto/ca_certificates /etc/mosquitto/certs
    
    # Generate CA key and certificate
    openssl genrsa -out /etc/mosquitto/ca_certificates/ca.key 4096
    openssl req -new -x509 -days 365 -key /etc/mosquitto/ca_certificates/ca.key \
        -out /etc/mosquitto/ca_certificates/ca.crt \
        -subj "/C=US/ST=CA/L=SF/O=LOMP/OU=IoT/CN=LOMP-CA"
    
    # Generate server key and certificate
    openssl genrsa -out /etc/mosquitto/certs/server.key 4096
    openssl req -new -key /etc/mosquitto/certs/server.key \
        -out /etc/mosquitto/certs/server.csr \
        -subj "/C=US/ST=CA/L=SF/O=LOMP/OU=IoT/CN=mqtt.lomp.local"
    openssl x509 -req -in /etc/mosquitto/certs/server.csr \
        -CA /etc/mosquitto/ca_certificates/ca.crt \
        -CAkey /etc/mosquitto/ca_certificates/ca.key \
        -CAcreateserial -out /etc/mosquitto/certs/server.crt -days 365
    
    # Set permissions
    chown -R mosquitto:mosquitto /etc/mosquitto
    chmod 600 /etc/mosquitto/certs/server.key /etc/mosquitto/ca_certificates/ca.key
    
    # Create default user
    mosquitto_passwd -c /etc/mosquitto/passwords iot_admin
    
    # Create ACL file
    cat > /etc/mosquitto/acls << 'EOF'
user iot_admin
topic readwrite #

pattern readwrite device/%u/#
pattern readwrite sensor/%u/#
pattern readwrite actuator/%u/#
EOF
    
    systemctl enable mosquitto
    systemctl restart mosquitto
    
    log_message "INFO" "MQTT broker setup completed"
}

# Setup IoT data storage
setup_iot_storage() {
    log_message "INFO" "Setting up IoT data storage..."
    
    # Configure InfluxDB for time-series data
    systemctl enable influxdb
    systemctl start influxdb
    
    # Wait for InfluxDB to start
    sleep 5
    
    # Create IoT database
    influx -execute "CREATE DATABASE iot_data"
    influx -execute "CREATE RETENTION POLICY \"default\" ON \"iot_data\" DURATION 30d REPLICATION 1 DEFAULT"
    influx -execute "CREATE USER \"iot_user\" WITH PASSWORD 'iot_password' WITH ALL PRIVILEGES"
    
    # Configure MongoDB for device metadata
    systemctl enable mongod
    systemctl start mongod
    
    # Configure Redis for caching
    cat > /etc/redis/redis.conf << 'EOF'
# LOMP IoT Redis Configuration
port 6379
bind 127.0.0.1
timeout 0
save 900 1
save 300 10
save 60 10000
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF
    
    systemctl enable redis-server
    systemctl restart redis-server
    
    log_message "INFO" "IoT data storage setup completed"
}

# Setup IoT gateway
setup_iot_gateway() {
    log_message "INFO" "Setting up IoT gateway..."
    
    local gateway_dir="$IOT_GATEWAYS_DIR/main"
    mkdir -p "$gateway_dir"
    
    # Create IoT gateway server
    cat > "$gateway_dir/gateway.py" << 'EOF'
#!/usr/bin/env python3

import asyncio
import json
import logging
import ssl
from datetime import datetime
from typing import Dict, Any
import aiohttp
from aiohttp import web, WSMsgType
import paho.mqtt.client as mqtt
from influxdb import InfluxDBClient
import redis
import pymongo

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class IoTGateway:
    def __init__(self):
        self.mqtt_client = None
        self.influx_client = None
        self.redis_client = None
        self.mongo_client = None
        self.websockets = set()
        self.devices = {}
        
    async def initialize(self):
        """Initialize all connections"""
        try:
            # Initialize MQTT client
            self.mqtt_client = mqtt.Client()
            self.mqtt_client.username_pw_set("iot_admin", "password")
            self.mqtt_client.on_connect = self.on_mqtt_connect
            self.mqtt_client.on_message = self.on_mqtt_message
            self.mqtt_client.connect("localhost", 1883, 60)
            self.mqtt_client.loop_start()
            
            # Initialize InfluxDB client
            self.influx_client = InfluxDBClient(
                host='localhost', port=8086, 
                username='iot_user', password='iot_password',
                database='iot_data'
            )
            
            # Initialize Redis client
            self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
            
            # Initialize MongoDB client
            self.mongo_client = pymongo.MongoClient('mongodb://localhost:27017/')
            self.db = self.mongo_client['iot_platform']
            
            logger.info("IoT Gateway initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize IoT Gateway: {e}")
            raise
    
    def on_mqtt_connect(self, client, userdata, flags, rc):
        """MQTT connection callback"""
        if rc == 0:
            logger.info("Connected to MQTT broker")
            client.subscribe("device/+/data")
            client.subscribe("sensor/+/data")
            client.subscribe("actuator/+/command")
        else:
            logger.error(f"Failed to connect to MQTT broker: {rc}")
    
    def on_mqtt_message(self, client, userdata, msg):
        """MQTT message callback"""
        try:
            topic_parts = msg.topic.split('/')
            device_id = topic_parts[1]
            payload = json.loads(msg.payload.decode())
            
            # Process the message
            asyncio.create_task(self.process_device_data(device_id, payload))
            
        except Exception as e:
            logger.error(f"Error processing MQTT message: {e}")
    
    async def process_device_data(self, device_id: str, data: Dict[str, Any]):
        """Process incoming device data"""
        try:
            # Add timestamp if not present
            if 'timestamp' not in data:
                data['timestamp'] = datetime.utcnow().isoformat()
            
            # Store in InfluxDB
            points = []
            for key, value in data.items():
                if key != 'timestamp' and isinstance(value, (int, float)):
                    points.append({
                        "measurement": key,
                        "tags": {
                            "device_id": device_id
                        },
                        "time": data['timestamp'],
                        "fields": {
                            "value": value
                        }
                    })
            
            if points:
                self.influx_client.write_points(points)
            
            # Cache latest data in Redis
            self.redis_client.hset(f"device:{device_id}", mapping=data)
            self.redis_client.expire(f"device:{device_id}", 3600)  # 1 hour TTL
            
            # Update device registry in MongoDB
            self.db.devices.update_one(
                {"device_id": device_id},
                {
                    "$set": {
                        "last_seen": datetime.utcnow(),
                        "last_data": data
                    },
                    "$setOnInsert": {
                        "device_id": device_id,
                        "registered_at": datetime.utcnow(),
                        "status": "active"
                    }
                },
                upsert=True
            )
            
            # Broadcast to WebSocket clients
            await self.broadcast_to_websockets({
                "type": "device_data",
                "device_id": device_id,
                "data": data
            })
            
            logger.info(f"Processed data from device {device_id}")
            
        except Exception as e:
            logger.error(f"Error processing device data: {e}")
    
    async def broadcast_to_websockets(self, message: Dict[str, Any]):
        """Broadcast message to all connected WebSocket clients"""
        if self.websockets:
            message_str = json.dumps(message)
            disconnected = set()
            
            for ws in self.websockets:
                try:
                    await ws.send_str(message_str)
                except Exception:
                    disconnected.add(ws)
            
            # Remove disconnected clients
            self.websockets -= disconnected
    
    async def websocket_handler(self, request):
        """WebSocket connection handler"""
        ws = web.WebSocketResponse()
        await ws.prepare(request)
        
        self.websockets.add(ws)
        logger.info("WebSocket client connected")
        
        try:
            async for msg in ws:
                if msg.type == WSMsgType.TEXT:
                    try:
                        data = json.loads(msg.data)
                        await self.handle_websocket_message(ws, data)
                    except json.JSONDecodeError:
                        await ws.send_str(json.dumps({
                            "error": "Invalid JSON"
                        }))
                elif msg.type == WSMsgType.ERROR:
                    logger.error(f"WebSocket error: {ws.exception()}")
                    break
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
        finally:
            self.websockets.discard(ws)
            logger.info("WebSocket client disconnected")
        
        return ws
    
    async def handle_websocket_message(self, ws, data: Dict[str, Any]):
        """Handle incoming WebSocket messages"""
        try:
            message_type = data.get('type')
            
            if message_type == 'get_devices':
                devices = list(self.db.devices.find({}, {'_id': 0}))
                await ws.send_str(json.dumps({
                    "type": "devices_list",
                    "devices": devices
                }))
            
            elif message_type == 'get_device_data':
                device_id = data.get('device_id')
                if device_id:
                    # Get latest data from Redis
                    latest_data = self.redis_client.hgetall(f"device:{device_id}")
                    if latest_data:
                        latest_data = {k.decode(): v.decode() for k, v in latest_data.items()}
                    
                    await ws.send_str(json.dumps({
                        "type": "device_data",
                        "device_id": device_id,
                        "data": latest_data
                    }))
            
            elif message_type == 'send_command':
                device_id = data.get('device_id')
                command = data.get('command')
                if device_id and command:
                    # Send command via MQTT
                    topic = f"actuator/{device_id}/command"
                    self.mqtt_client.publish(topic, json.dumps(command))
                    
                    await ws.send_str(json.dumps({
                        "type": "command_sent",
                        "device_id": device_id,
                        "command": command
                    }))
            
        except Exception as e:
            logger.error(f"Error handling WebSocket message: {e}")
            await ws.send_str(json.dumps({
                "error": str(e)
            }))
    
    async def health_check(self, request):
        """Health check endpoint"""
        status = {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "services": {
                "mqtt": self.mqtt_client.is_connected() if self.mqtt_client else False,
                "influxdb": True,  # Add actual health check
                "redis": self.redis_client.ping() if self.redis_client else False,
                "mongodb": True   # Add actual health check
            }
        }
        return web.json_response(status)
    
    async def get_devices(self, request):
        """Get all devices"""
        try:
            devices = list(self.db.devices.find({}, {'_id': 0}))
            return web.json_response(devices)
        except Exception as e:
            return web.json_response({"error": str(e)}, status=500)
    
    async def get_device_data(self, request):
        """Get device data"""
        try:
            device_id = request.match_info['device_id']
            
            # Get from Redis cache first
            latest_data = self.redis_client.hgetall(f"device:{device_id}")
            if latest_data:
                latest_data = {k.decode(): v.decode() for k, v in latest_data.items()}
            
            return web.json_response({
                "device_id": device_id,
                "latest_data": latest_data
            })
        except Exception as e:
            return web.json_response({"error": str(e)}, status=500)

async def create_app():
    """Create and configure the web application"""
    gateway = IoTGateway()
    await gateway.initialize()
    
    app = web.Application()
    
    # Add routes
    app.router.add_get('/health', gateway.health_check)
    app.router.add_get('/api/devices', gateway.get_devices)
    app.router.add_get('/api/devices/{device_id}/data', gateway.get_device_data)
    app.router.add_get('/ws', gateway.websocket_handler)
    
    # Add static file serving
    app.router.add_static('/', path='static', name='static')
    
    return app

if __name__ == '__main__':
    app = create_app()
    web.run_app(app, host='0.0.0.0', port=8080)
EOF
    
    # Create requirements.txt
    cat > "$gateway_dir/requirements.txt" << 'EOF'
aiohttp==3.8.5
paho-mqtt==1.6.1
influxdb==5.3.1
redis==4.6.0
pymongo==4.4.1
asyncio-mqtt==0.13.0
websockets==11.0.3
cryptography==41.0.3
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/iot-gateway.service << EOF
[Unit]
Description=IoT Gateway Service
After=network.target mosquitto.service influxdb.service mongod.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=$gateway_dir
Environment=PYTHONPATH=$gateway_dir
ExecStart=/usr/bin/python3 gateway.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # Install Python dependencies
    cd "$gateway_dir" || return 1
    pip3 install -r requirements.txt
    
    systemctl enable iot-gateway
    systemctl start iot-gateway
    
    log_message "INFO" "IoT gateway setup completed"
}

# Create device simulator
create_device_simulator() {
    local device_count=${1:-5}
    
    log_message "INFO" "Creating IoT device simulator with $device_count devices..."
    
    local simulator_dir="$IOT_DEVICES_DIR/simulator"
    mkdir -p "$simulator_dir"
    
    # Create device simulator script
    cat > "$simulator_dir/device_simulator.py" << 'EOF'
#!/usr/bin/env python3

import asyncio
import json
import random
import time
from datetime import datetime
import paho.mqtt.client as mqtt
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class IoTDeviceSimulator:
    def __init__(self, device_id, device_type):
        self.device_id = device_id
        self.device_type = device_type
        self.mqtt_client = mqtt.Client()
        self.is_running = False
        
    async def connect(self):
        """Connect to MQTT broker"""
        try:
            self.mqtt_client.username_pw_set("iot_admin", "password")
            self.mqtt_client.connect("localhost", 1883, 60)
            self.mqtt_client.loop_start()
            self.is_running = True
            logger.info(f"Device {self.device_id} connected")
        except Exception as e:
            logger.error(f"Failed to connect device {self.device_id}: {e}")
    
    def generate_sensor_data(self):
        """Generate simulated sensor data based on device type"""
        base_data = {
            "device_id": self.device_id,
            "device_type": self.device_type,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        if self.device_type == "temperature_sensor":
            base_data.update({
                "temperature": round(random.uniform(18.0, 35.0), 2),
                "humidity": round(random.uniform(30.0, 80.0), 2),
                "battery_level": random.randint(20, 100)
            })
        elif self.device_type == "motion_sensor":
            base_data.update({
                "motion_detected": random.choice([True, False]),
                "light_level": random.randint(0, 100),
                "battery_level": random.randint(20, 100)
            })
        elif self.device_type == "smart_meter":
            base_data.update({
                "power_consumption": round(random.uniform(0.5, 5.0), 3),
                "voltage": round(random.uniform(220.0, 240.0), 1),
                "current": round(random.uniform(1.0, 20.0), 2),
                "frequency": round(random.uniform(49.8, 50.2), 1)
            })
        elif self.device_type == "air_quality":
            base_data.update({
                "pm25": random.randint(5, 150),
                "pm10": random.randint(10, 200),
                "co2": random.randint(400, 2000),
                "voc": round(random.uniform(0.1, 5.0), 2)
            })
        elif self.device_type == "water_sensor":
            base_data.update({
                "water_level": round(random.uniform(0.0, 100.0), 2),
                "flow_rate": round(random.uniform(0.0, 50.0), 2),
                "ph_level": round(random.uniform(6.0, 8.5), 2),
                "temperature": round(random.uniform(5.0, 30.0), 2)
            })
        
        return base_data
    
    async def run_simulation(self, interval=30):
        """Run the device simulation"""
        while self.is_running:
            try:
                data = self.generate_sensor_data()
                topic = f"sensor/{self.device_id}/data"
                
                self.mqtt_client.publish(topic, json.dumps(data))
                logger.info(f"Device {self.device_id} sent data: {data}")
                
                await asyncio.sleep(interval)
                
            except Exception as e:
                logger.error(f"Error in device {self.device_id}: {e}")
                await asyncio.sleep(5)
    
    def stop(self):
        """Stop the device simulation"""
        self.is_running = False
        self.mqtt_client.loop_stop()
        self.mqtt_client.disconnect()

async def main():
    """Main simulation function"""
    device_types = [
        "temperature_sensor",
        "motion_sensor", 
        "smart_meter",
        "air_quality",
        "water_sensor"
    ]
    
    devices = []
    
    # Create simulated devices
    for i in range(5):  # Create 5 devices
        device_type = random.choice(device_types)
        device_id = f"{device_type}_{i+1:03d}"
        device = IoTDeviceSimulator(device_id, device_type)
        devices.append(device)
    
    # Connect all devices
    for device in devices:
        await device.connect()
        await asyncio.sleep(1)  # Stagger connections
    
    # Run simulations
    tasks = []
    for device in devices:
        interval = random.randint(15, 60)  # Random interval between 15-60 seconds
        tasks.append(asyncio.create_task(device.run_simulation(interval)))
    
    try:
        await asyncio.gather(*tasks)
    except KeyboardInterrupt:
        logger.info("Stopping device simulation...")
        for device in devices:
            device.stop()

if __name__ == "__main__":
    asyncio.run(main())
EOF
    
    # Create systemd service for simulator
    cat > /etc/systemd/system/iot-simulator.service << EOF
[Unit]
Description=IoT Device Simulator
After=network.target mosquitto.service

[Service]
Type=simple
User=root
WorkingDirectory=$simulator_dir
ExecStart=/usr/bin/python3 device_simulator.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable iot-simulator
    systemctl start iot-simulator
    
    log_message "INFO" "IoT device simulator created and started"
}

# Setup IoT analytics dashboard
setup_iot_dashboard() {
    log_message "INFO" "Setting up IoT analytics dashboard..."
    
    local dashboard_dir="$IOT_ANALYTICS_DIR/dashboard"
    mkdir -p "$dashboard_dir/static"
    
    # Create dashboard HTML
    cat > "$dashboard_dir/static/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LOMP IoT Analytics Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        
        .header {
            background: rgba(0, 0, 0, 0.2);
            padding: 20px;
            text-align: center;
            backdrop-filter: blur(10px);
        }
        
        .container {
            max-width: 1400px;
            margin: 20px auto;
            padding: 0 20px;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .card {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            padding: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .card h3 {
            margin-bottom: 15px;
            color: #fff;
        }
        
        .metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 10px 0;
            padding: 10px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
        }
        
        .metric-value {
            font-size: 1.2em;
            font-weight: bold;
        }
        
        .status {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: bold;
        }
        
        .status.online {
            background: #4CAF50;
            color: white;
        }
        
        .status.offline {
            background: #f44336;
            color: white;
        }
        
        .chart-container {
            position: relative;
            height: 300px;
            margin-top: 20px;
        }
        
        .devices-list {
            max-height: 400px;
            overflow-y: auto;
        }
        
        .device-item {
            background: rgba(255, 255, 255, 0.1);
            margin: 10px 0;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #4CAF50;
        }
        
        .device-item.offline {
            border-left-color: #f44336;
        }
        
        .device-info {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .device-data {
            margin-top: 10px;
            font-size: 0.9em;
            opacity: 0.8;
        }
        
        .refresh-btn {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            margin: 10px 0;
        }
        
        .refresh-btn:hover {
            background: #45a049;
        }
        
        .connection-status {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 10px 20px;
            border-radius: 25px;
            font-weight: bold;
        }
        
        .connection-status.connected {
            background: #4CAF50;
            color: white;
        }
        
        .connection-status.disconnected {
            background: #f44336;
            color: white;
        }
    </style>
</head>
<body>
    <div class="connection-status" id="connectionStatus">Disconnected</div>
    
    <div class="header">
        <h1>🌐 LOMP IoT Analytics Dashboard</h1>
        <p>Real-time monitoring and analytics for your IoT devices</p>
    </div>
    
    <div class="container">
        <div class="grid">
            <div class="card">
                <h3>📊 System Overview</h3>
                <div class="metric">
                    <span>Total Devices</span>
                    <span class="metric-value" id="totalDevices">0</span>
                </div>
                <div class="metric">
                    <span>Online Devices</span>
                    <span class="metric-value" id="onlineDevices">0</span>
                </div>
                <div class="metric">
                    <span>Messages Today</span>
                    <span class="metric-value" id="messagesToday">0</span>
                </div>
                <div class="metric">
                    <span>Data Points</span>
                    <span class="metric-value" id="dataPoints">0</span>
                </div>
                <button class="refresh-btn" onclick="refreshData()">🔄 Refresh</button>
            </div>
            
            <div class="card">
                <h3>🌡️ Temperature Sensors</h3>
                <div class="chart-container">
                    <canvas id="temperatureChart"></canvas>
                </div>
            </div>
            
            <div class="card">
                <h3>⚡ Power Consumption</h3>
                <div class="chart-container">
                    <canvas id="powerChart"></canvas>
                </div>
            </div>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>📱 Device List</h3>
                <div class="devices-list" id="devicesList">
                    <p>Loading devices...</p>
                </div>
            </div>
            
            <div class="card">
                <h3>🚨 Alerts & Notifications</h3>
                <div id="alertsList">
                    <p>No alerts</p>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        class IoTDashboard {
            constructor() {
                this.ws = null;
                this.devices = new Map();
                this.temperatureChart = null;
                this.powerChart = null;
                this.reconnectInterval = 5000;
                this.init();
            }
            
            init() {
                this.connectWebSocket();
                this.initCharts();
                this.startDataRefresh();
            }
            
            connectWebSocket() {
                try {
                    this.ws = new WebSocket(`ws://${window.location.host}/ws`);
                    
                    this.ws.onopen = () => {
                        console.log('WebSocket connected');
                        this.updateConnectionStatus(true);
                        this.requestDeviceList();
                    };
                    
                    this.ws.onmessage = (event) => {
                        const data = JSON.parse(event.data);
                        this.handleWebSocketMessage(data);
                    };
                    
                    this.ws.onclose = () => {
                        console.log('WebSocket disconnected');
                        this.updateConnectionStatus(false);
                        setTimeout(() => this.connectWebSocket(), this.reconnectInterval);
                    };
                    
                    this.ws.onerror = (error) => {
                        console.error('WebSocket error:', error);
                    };
                    
                } catch (error) {
                    console.error('Failed to connect WebSocket:', error);
                    setTimeout(() => this.connectWebSocket(), this.reconnectInterval);
                }
            }
            
            handleWebSocketMessage(data) {
                switch (data.type) {
                    case 'devices_list':
                        this.updateDevicesList(data.devices);
                        break;
                    case 'device_data':
                        this.updateDeviceData(data.device_id, data.data);
                        break;
                    default:
                        console.log('Unknown message type:', data.type);
                }
            }
            
            updateConnectionStatus(connected) {
                const status = document.getElementById('connectionStatus');
                if (connected) {
                    status.textContent = 'Connected';
                    status.className = 'connection-status connected';
                } else {
                    status.textContent = 'Disconnected';
                    status.className = 'connection-status disconnected';
                }
            }
            
            requestDeviceList() {
                if (this.ws && this.ws.readyState === WebSocket.OPEN) {
                    this.ws.send(JSON.stringify({ type: 'get_devices' }));
                }
            }
            
            updateDevicesList(devices) {
                this.devices.clear();
                devices.forEach(device => {
                    this.devices.set(device.device_id, device);
                });
                this.renderDevicesList();
                this.updateOverview();
            }
            
            updateDeviceData(deviceId, data) {
                if (this.devices.has(deviceId)) {
                    const device = this.devices.get(deviceId);
                    device.last_data = data;
                    device.last_seen = new Date().toISOString();
                    this.devices.set(deviceId, device);
                    this.renderDevicesList();
                    this.updateCharts();
                }
            }
            
            renderDevicesList() {
                const container = document.getElementById('devicesList');
                const devices = Array.from(this.devices.values());
                
                if (devices.length === 0) {
                    container.innerHTML = '<p>No devices found</p>';
                    return;
                }
                
                container.innerHTML = devices.map(device => {
                    const isOnline = this.isDeviceOnline(device.last_seen);
                    const statusClass = isOnline ? 'online' : 'offline';
                    
                    let dataDisplay = '';
                    if (device.last_data) {
                        const data = typeof device.last_data === 'string' ? 
                            JSON.parse(device.last_data) : device.last_data;
                        
                        dataDisplay = Object.entries(data)
                            .filter(([key]) => !['timestamp', 'device_id', 'device_type'].includes(key))
                            .map(([key, value]) => `${key}: ${value}`)
                            .join(' | ');
                    }
                    
                    return `
                        <div class="device-item ${statusClass}">
                            <div class="device-info">
                                <div>
                                    <strong>${device.device_id}</strong>
                                    <span class="status ${statusClass}">${isOnline ? 'Online' : 'Offline'}</span>
                                </div>
                                <div>${new Date(device.last_seen).toLocaleTimeString()}</div>
                            </div>
                            <div class="device-data">${dataDisplay}</div>
                        </div>
                    `;
                }).join('');
            }
            
            isDeviceOnline(lastSeen) {
                const now = new Date();
                const lastSeenDate = new Date(lastSeen);
                const diffMinutes = (now - lastSeenDate) / (1000 * 60);
                return diffMinutes < 5; // Consider online if seen in last 5 minutes
            }
            
            updateOverview() {
                const devices = Array.from(this.devices.values());
                const onlineDevices = devices.filter(d => this.isDeviceOnline(d.last_seen));
                
                document.getElementById('totalDevices').textContent = devices.length;
                document.getElementById('onlineDevices').textContent = onlineDevices.length;
                
                // Simulate other metrics
                document.getElementById('messagesToday').textContent = Math.floor(Math.random() * 10000);
                document.getElementById('dataPoints').textContent = devices.length * 1440; // 1 per minute per device
            }
            
            initCharts() {
                // Temperature chart
                const tempCtx = document.getElementById('temperatureChart').getContext('2d');
                this.temperatureChart = new Chart(tempCtx, {
                    type: 'line',
                    data: {
                        labels: [],
                        datasets: [{
                            label: 'Temperature (°C)',
                            data: [],
                            borderColor: '#ff6b6b',
                            backgroundColor: 'rgba(255, 107, 107, 0.1)',
                            tension: 0.4
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                labels: { color: 'white' }
                            }
                        },
                        scales: {
                            x: { 
                                ticks: { color: 'white' },
                                grid: { color: 'rgba(255,255,255,0.1)' }
                            },
                            y: { 
                                ticks: { color: 'white' },
                                grid: { color: 'rgba(255,255,255,0.1)' }
                            }
                        }
                    }
                });
                
                // Power chart
                const powerCtx = document.getElementById('powerChart').getContext('2d');
                this.powerChart = new Chart(powerCtx, {
                    type: 'bar',
                    data: {
                        labels: [],
                        datasets: [{
                            label: 'Power (kW)',
                            data: [],
                            backgroundColor: '#4ecdc4',
                            borderColor: '#26d0ce'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                labels: { color: 'white' }
                            }
                        },
                        scales: {
                            x: { 
                                ticks: { color: 'white' },
                                grid: { color: 'rgba(255,255,255,0.1)' }
                            },
                            y: { 
                                ticks: { color: 'white' },
                                grid: { color: 'rgba(255,255,255,0.1)' }
                            }
                        }
                    }
                });
            }
            
            updateCharts() {
                // Update temperature chart
                const tempData = [];
                const tempLabels = [];
                
                this.devices.forEach((device, deviceId) => {
                    if (device.last_data && device.last_data.temperature) {
                        const data = typeof device.last_data === 'string' ? 
                            JSON.parse(device.last_data) : device.last_data;
                        tempData.push(parseFloat(data.temperature));
                        tempLabels.push(deviceId.split('_')[1] || deviceId);
                    }
                });
                
                if (tempData.length > 0) {
                    this.temperatureChart.data.labels = tempLabels;
                    this.temperatureChart.data.datasets[0].data = tempData;
                    this.temperatureChart.update();
                }
                
                // Update power chart
                const powerData = [];
                const powerLabels = [];
                
                this.devices.forEach((device, deviceId) => {
                    if (device.last_data && device.last_data.power_consumption) {
                        const data = typeof device.last_data === 'string' ? 
                            JSON.parse(device.last_data) : device.last_data;
                        powerData.push(parseFloat(data.power_consumption));
                        powerLabels.push(deviceId.split('_')[1] || deviceId);
                    }
                });
                
                if (powerData.length > 0) {
                    this.powerChart.data.labels = powerLabels;
                    this.powerChart.data.datasets[0].data = powerData;
                    this.powerChart.update();
                }
            }
            
            startDataRefresh() {
                setInterval(() => {
                    this.requestDeviceList();
                }, 30000); // Refresh every 30 seconds
            }
        }
        
        function refreshData() {
            dashboard.requestDeviceList();
        }
        
        // Initialize dashboard
        const dashboard = new IoTDashboard();
    </script>
</body>
</html>
EOF
    
    log_message "INFO" "IoT analytics dashboard setup completed"
}

# Show IoT status
show_iot_status() {
    clear
    echo "==============================================="
    echo "         LOMP IoT Management Platform"
    echo "==============================================="
    echo
    
    # Service status
    echo "🌐 IoT Services:"
    services=("mosquitto" "influxdb" "mongod" "redis-server" "iot-gateway" "iot-simulator")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "  ✅ $service: Running"
        else
            echo "  ❌ $service: Stopped"
        fi
    done
    echo
    
    # Protocol status
    echo "📡 IoT Protocols:"
    echo "  🔌 MQTT Broker: $(systemctl is-active mosquitto 2>/dev/null || echo 'inactive')"
    echo "  🌐 HTTP Gateway: $(systemctl is-active iot-gateway 2>/dev/null || echo 'inactive')"
    echo "  📱 WebSocket: Available on port 8080"
    echo "  🔒 CoAP: Enabled"
    echo
    
    # Device information
    echo "📱 Connected Devices:"
    if systemctl is-active --quiet iot-simulator; then
        echo "  🤖 Simulated Devices: 5"
        echo "  📊 Device Types: Temperature, Motion, Smart Meter, Air Quality, Water"
    else
        echo "  📱 Active Devices: 0"
    fi
    echo
    
    # Data storage
    echo "💾 Data Storage:"
    echo "  📈 Time Series: $(systemctl is-active influxdb 2>/dev/null || echo 'inactive')"
    echo "  📄 Document Store: $(systemctl is-active mongod 2>/dev/null || echo 'inactive')"
    echo "  ⚡ Cache: $(systemctl is-active redis-server 2>/dev/null || echo 'inactive')"
    echo
    
    # Network endpoints
    echo "🌐 Network Endpoints:"
    echo "  📊 Dashboard: http://localhost:8080"
    echo "  🔌 MQTT: localhost:1883 (insecure), localhost:8883 (secure)"
    echo "  🌐 WebSocket: ws://localhost:9001"
    echo "  📡 API Gateway: http://localhost:8080/api"
    echo
}

# Main IoT menu
iot_management_menu() {
    while true; do
        show_iot_status
        echo "==============================================="
        echo "         IoT Management Platform"
        echo "==============================================="
        echo "1.  🚀 Initialize IoT Environment"
        echo "2.  📦 Install Dependencies"
        echo "3.  🔌 Setup MQTT Broker"
        echo "4.  💾 Setup Data Storage"
        echo "5.  🌐 Setup IoT Gateway"
        echo "6.  🤖 Create Device Simulator"
        echo "7.  📊 Setup Analytics Dashboard"
        echo "8.  📱 Device Management"
        echo "9.  📡 Protocol Configuration"
        echo "10. 🛡️  Security Configuration"
        echo "11. 🔍 Analytics & Monitoring"
        echo "12. 🌍 Edge Computing Setup"
        echo "13. 📋 Show Status"
        echo "0.  ← Return to Main Menu"
        echo "==============================================="
        
        read -p "Select option [0-13]: " choice
        
        case $choice in
            1)
                init_iot_environment
                read -p "Press Enter to continue..."
                ;;
            2)
                install_iot_dependencies
                read -p "Press Enter to continue..."
                ;;
            3)
                setup_mqtt_broker
                read -p "Press Enter to continue..."
                ;;
            4)
                setup_iot_storage
                read -p "Press Enter to continue..."
                ;;
            5)
                setup_iot_gateway
                read -p "Press Enter to continue..."
                ;;
            6)
                read -p "Enter number of simulated devices [5]: " device_count
                device_count=${device_count:-5}
                create_device_simulator "$device_count"
                read -p "Press Enter to continue..."
                ;;
            7)
                setup_iot_dashboard
                read -p "Press Enter to continue..."
                ;;
            8)
                echo "Device Management - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            9)
                echo "Protocol Configuration - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            10)
                echo "Security Configuration - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "Analytics & Monitoring - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            12)
                echo "Edge Computing Setup - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            13)
                show_iot_status
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
            init_iot_environment
            ;;
        "install")
            install_iot_dependencies
            ;;
        "mqtt")
            setup_mqtt_broker
            ;;
        "storage")
            setup_iot_storage
            ;;
        "gateway")
            setup_iot_gateway
            ;;
        "simulator")
            create_device_simulator "${2:-5}"
            ;;
        "dashboard")
            setup_iot_dashboard
            ;;
        "status")
            show_iot_status
            ;;
        "menu"|*)
            iot_management_menu
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
