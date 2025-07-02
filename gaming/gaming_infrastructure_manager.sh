#!/bin/bash
#
# gaming_infrastructure_manager.sh - Part of LOMP Stack v3.0
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

# LOMP Stack - Gaming Infrastructure Manager
# Phase 5: Next Generation Features
# Advanced gaming server and infrastructure management
# Version: 1.0.0

# Source required dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(dirname "$SCRIPT_DIR")"

source "$STACK_ROOT/helpers/utils/functions.sh"
source "$STACK_ROOT/helpers/utils/config_helpers.sh"
source "$STACK_ROOT/helpers/utils/notify_helpers.sh"
source "$STACK_ROOT/helpers/monitoring/system_helpers.sh"

# Gaming Configuration
GAMING_CONFIG_FILE="$SCRIPT_DIR/gaming_config.json"
export GAMING_LOG_FILE="/var/log/lomp_gaming.log"
GAMING_DATA_DIR="/opt/lomp/gaming"
GAMING_SERVERS_DIR="$GAMING_DATA_DIR/servers"
GAMING_ASSETS_DIR="$GAMING_DATA_DIR/assets"
GAMING_WORLDS_DIR="$GAMING_DATA_DIR/worlds"
GAMING_PLAYERS_DIR="$GAMING_DATA_DIR/players"

# Gaming Functions

# Initialize gaming environment
init_gaming_environment() {
    log_message "INFO" "Initializing LOMP Gaming Infrastructure Manager..."
    
    # Create directories
    mkdir -p "$GAMING_DATA_DIR" "$GAMING_SERVERS_DIR" "$GAMING_ASSETS_DIR" "$GAMING_WORLDS_DIR" "$GAMING_PLAYERS_DIR"
    mkdir -p "/etc/lomp/gaming" "/var/lib/lomp/gaming"
    
    # Set permissions
    chmod 755 "$GAMING_DATA_DIR" "$GAMING_SERVERS_DIR" "$GAMING_ASSETS_DIR"
    chmod 750 "$GAMING_WORLDS_DIR" "$GAMING_PLAYERS_DIR"
    
    # Initialize configuration if not exists
    if [[ ! -f "$GAMING_CONFIG_FILE" ]]; then
        create_default_gaming_config
    fi
    
    log_message "INFO" "Gaming environment initialized successfully"
    return 0
}

# Create default gaming configuration
create_default_gaming_config() {
    cat > "$GAMING_CONFIG_FILE" << 'EOF'
{
  "gaming": {
    "version": "1.0.0",
    "server_types": {
      "minecraft": {
        "enabled": true,
        "version": "1.20.1",
        "memory": "4G",
        "port": 25565,
        "plugins": ["WorldEdit", "Essentials", "LuckPerms"]
      },
      "nodejs_game": {
        "enabled": true,
        "port": 3000,
        "websocket_port": 3001,
        "max_players": 100
      },
      "unity_server": {
        "enabled": false,
        "port": 7777,
        "max_connections": 50
      },
      "unreal_server": {
        "enabled": false,
        "port": 7778,
        "max_connections": 50
      }
    },
    "networking": {
      "load_balancer": {
        "enabled": true,
        "algorithm": "round_robin",
        "health_check_interval": 30
      },
      "cdn": {
        "enabled": true,
        "cache_duration": 3600,
        "compression": true
      },
      "anti_ddos": {
        "enabled": true,
        "rate_limit": 100,
        "ban_duration": 3600
      }
    },
    "database": {
      "type": "mongodb",
      "host": "localhost",
      "port": 27017,
      "name": "gaming_db",
      "replication": true
    },
    "caching": {
      "redis": {
        "enabled": true,
        "host": "localhost",
        "port": 6379,
        "ttl": 3600
      }
    },
    "analytics": {
      "enabled": true,
      "player_tracking": true,
      "performance_monitoring": true,
      "real_time_stats": true
    },
    "security": {
      "authentication": "jwt",
      "encryption": "AES-256",
      "anti_cheat": true,
      "chat_moderation": true
    },
    "scaling": {
      "auto_scaling": true,
      "min_servers": 1,
      "max_servers": 10,
      "cpu_threshold": 80,
      "memory_threshold": 85
    }
  }
}
EOF
    log_message "INFO" "Default gaming configuration created"
}

# Install gaming dependencies
install_gaming_dependencies() {
    log_message "INFO" "Installing gaming dependencies..."
    
    # Update package manager
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y curl wget git build-essential software-properties-common
        apt-get install -y openjdk-17-jdk nodejs npm python3 python3-pip
    elif command -v yum &> /dev/null; then
        yum update -y
        yum groupinstall -y "Development Tools"
        yum install -y curl wget git java-17-openjdk nodejs npm python3 python3-pip
    fi
    
    # Install Docker for containerized game servers
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
    fi
    
    # Install MongoDB for game data
    if ! command -v mongod &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            apt-get update
            apt-get install -y mongodb-org
        fi
        systemctl enable mongod
        systemctl start mongod
    fi
    
    # Install Redis for caching and session management
    if ! command -v redis-server &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            apt-get install -y redis-server
        elif command -v yum &> /dev/null; then
            yum install -y redis
        fi
        systemctl enable redis
        systemctl start redis
    fi
    
    # Install Node.js gaming libraries
    npm install -g socket.io express mongoose redis ioredis
    
    # Install Python gaming libraries
    pip3 install pygame flask socketio redis pymongo
    
    log_message "INFO" "Gaming dependencies installed successfully"
}

# Setup Minecraft server
setup_minecraft_server() {
    local server_name="${1:-minecraft-server}"
    local version="${2:-1.20.1}"
    local memory="${3:-4G}"
    
    log_message "INFO" "Setting up Minecraft server: $server_name"
    
    local server_dir="$GAMING_SERVERS_DIR/$server_name"
    mkdir -p "$server_dir"
    
    # Download Minecraft server
    cd "$server_dir" || return 1
    wget -O "server.jar" "https://launcher.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar"
    
    # Create server properties
    cat > server.properties << EOF
motd=LOMP Stack Minecraft Server
server-port=25565
max-players=20
online-mode=true
white-list=false
spawn-protection=16
max-world-size=29999984
level-name=world
gamemode=survival
force-gamemode=false
difficulty=easy
spawn-monsters=true
spawn-animals=true
spawn-npcs=true
pvp=true
enable-command-block=false
max-memory-percent=70
EOF
    
    # Accept EULA
    echo "eula=true" > eula.txt
    
    # Create startup script
    cat > start.sh << EOF
#!/bin/bash
cd "$server_dir"
java -Xmx$memory -Xms$memory -jar server.jar nogui
EOF
    chmod +x start.sh
    
    # Create systemd service
    cat > "/etc/systemd/system/minecraft-$server_name.service" << EOF
[Unit]
Description=Minecraft Server ($server_name)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$server_dir
ExecStart=$server_dir/start.sh
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable "minecraft-$server_name"
    systemctl start "minecraft-$server_name"
    
    log_message "INFO" "Minecraft server $server_name setup completed"
}

# Create Node.js multiplayer game template
create_nodejs_game_template() {
    local game_name="$1"
    
    if [[ -z "$game_name" ]]; then
        log_message "ERROR" "Game name is required"
        return 1
    fi
    
    log_message "INFO" "Creating Node.js game template: $game_name"
    
    local game_dir="$GAMING_SERVERS_DIR/$game_name"
    mkdir -p "$game_dir"
    
    # Create package.json
    cat > "$game_dir/package.json" << EOF
{
  "name": "$game_name",
  "version": "1.0.0",
  "description": "LOMP Stack Multiplayer Game",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.0",
    "socket.io": "^4.7.0",
    "mongoose": "^7.5.0",
    "redis": "^4.6.0",
    "jsonwebtoken": "^9.0.0",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "compression": "^1.7.4"
  },
  "devDependencies": {
    "nodemon": "^3.0.0",
    "jest": "^29.0.0"
  }
}
EOF
    
    # Create main server file
    cat > "$game_dir/server.js" << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const redis = require('redis');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json());
app.use(express.static('public'));

// Database connections
mongoose.connect('mongodb://localhost:27017/gaming_db', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

const redisClient = redis.createClient({
    host: 'localhost',
    port: 6379
});

// Game state
const gameState = {
    players: new Map(),
    rooms: new Map(),
    matches: new Map()
};

// Player schema
const playerSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    stats: {
        gamesPlayed: { type: Number, default: 0 },
        wins: { type: Number, default: 0 },
        losses: { type: Number, default: 0 },
        score: { type: Number, default: 0 }
    },
    createdAt: { type: Date, default: Date.now }
});

const Player = mongoose.model('Player', playerSchema);

// Authentication middleware
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
        return res.sendStatus(401);
    }
    
    jwt.verify(token, process.env.JWT_SECRET || 'secret', (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
};

// Routes
app.post('/api/register', async (req, res) => {
    try {
        const { username, email, password } = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);
        
        const player = new Player({
            username,
            email,
            password: hashedPassword
        });
        
        await player.save();
        
        const token = jwt.sign(
            { id: player._id, username: player.username },
            process.env.JWT_SECRET || 'secret'
        );
        
        res.json({ token, player: { id: player._id, username: player.username } });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const player = await Player.findOne({ username });
        
        if (!player || !await bcrypt.compare(password, player.password)) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const token = jwt.sign(
            { id: player._id, username: player.username },
            process.env.JWT_SECRET || 'secret'
        );
        
        res.json({ token, player: { id: player._id, username: player.username } });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/stats', authenticateToken, async (req, res) => {
    try {
        const player = await Player.findById(req.user.id);
        res.json(player.stats);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Socket.IO connection handling
io.on('connection', (socket) => {
    console.log('Player connected:', socket.id);
    
    // Player authentication
    socket.on('authenticate', async (token) => {
        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
            socket.userId = decoded.id;
            socket.username = decoded.username;
            
            gameState.players.set(socket.id, {
                id: decoded.id,
                username: decoded.username,
                socket: socket,
                x: 0,
                y: 0,
                health: 100,
                score: 0
            });
            
            socket.emit('authenticated', { success: true });
            io.emit('playerJoined', { username: decoded.username });
        } catch (error) {
            socket.emit('authenticated', { success: false, error: 'Invalid token' });
        }
    });
    
    // Game events
    socket.on('joinRoom', (roomId) => {
        if (!gameState.rooms.has(roomId)) {
            gameState.rooms.set(roomId, {
                id: roomId,
                players: new Set(),
                gameStarted: false
            });
        }
        
        const room = gameState.rooms.get(roomId);
        room.players.add(socket.id);
        socket.join(roomId);
        socket.currentRoom = roomId;
        
        socket.emit('roomJoined', { roomId, playerCount: room.players.size });
        socket.to(roomId).emit('playerJoinedRoom', { 
            playerId: socket.id, 
            username: socket.username 
        });
    });
    
    socket.on('playerMove', (data) => {
        const player = gameState.players.get(socket.id);
        if (player) {
            player.x = data.x;
            player.y = data.y;
            
            if (socket.currentRoom) {
                socket.to(socket.currentRoom).emit('playerMoved', {
                    playerId: socket.id,
                    x: data.x,
                    y: data.y
                });
            }
        }
    });
    
    socket.on('playerAction', (data) => {
        if (socket.currentRoom) {
            socket.to(socket.currentRoom).emit('playerAction', {
                playerId: socket.id,
                username: socket.username,
                action: data.action,
                data: data.data
            });
        }
    });
    
    socket.on('chatMessage', (message) => {
        if (socket.currentRoom && socket.username) {
            io.to(socket.currentRoom).emit('chatMessage', {
                username: socket.username,
                message: message,
                timestamp: Date.now()
            });
        }
    });
    
    // Disconnect handling
    socket.on('disconnect', () => {
        console.log('Player disconnected:', socket.id);
        
        gameState.players.delete(socket.id);
        
        if (socket.currentRoom) {
            const room = gameState.rooms.get(socket.currentRoom);
            if (room) {
                room.players.delete(socket.id);
                socket.to(socket.currentRoom).emit('playerLeft', {
                    playerId: socket.id,
                    username: socket.username
                });
                
                if (room.players.size === 0) {
                    gameState.rooms.delete(socket.currentRoom);
                }
            }
        }
        
        if (socket.username) {
            io.emit('playerLeft', { username: socket.username });
        }
    });
});

// Game loop
setInterval(() => {
    // Update game state
    for (const [roomId, room] of gameState.rooms) {
        if (room.gameStarted && room.players.size > 0) {
            // Broadcast game state to room
            const roomPlayers = Array.from(room.players).map(playerId => {
                const player = gameState.players.get(playerId);
                return player ? {
                    id: playerId,
                    username: player.username,
                    x: player.x,
                    y: player.y,
                    health: player.health,
                    score: player.score
                } : null;
            }).filter(Boolean);
            
            io.to(roomId).emit('gameState', { players: roomPlayers });
        }
    }
}, 1000 / 60); // 60 FPS

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Game server running on port ${PORT}`);
});
EOF
    
    # Create client-side game template
    mkdir -p "$game_dir/public"
    cat > "$game_dir/public/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LOMP Stack Multiplayer Game</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            font-family: 'Arial', sans-serif;
            overflow: hidden;
        }
        
        #gameContainer {
            width: 100vw;
            height: 100vh;
            position: relative;
        }
        
        #gameCanvas {
            background: #000;
            border: 2px solid #333;
            display: block;
            margin: 20px auto;
        }
        
        #ui {
            position: absolute;
            top: 10px;
            left: 10px;
            color: white;
            z-index: 100;
        }
        
        #chatContainer {
            position: absolute;
            bottom: 10px;
            left: 10px;
            width: 300px;
            height: 200px;
            background: rgba(0, 0, 0, 0.7);
            border-radius: 10px;
            padding: 10px;
            z-index: 100;
        }
        
        #chatMessages {
            height: 150px;
            overflow-y: auto;
            color: white;
            font-size: 12px;
            margin-bottom: 10px;
        }
        
        #chatInput {
            width: 100%;
            padding: 5px;
            border: none;
            border-radius: 5px;
        }
        
        #loginForm {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(255, 255, 255, 0.9);
            padding: 30px;
            border-radius: 15px;
            text-align: center;
            z-index: 200;
        }
        
        .hidden {
            display: none;
        }
        
        input, button {
            margin: 5px;
            padding: 10px;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        
        button {
            background: #4CAF50;
            color: white;
            cursor: pointer;
        }
        
        button:hover {
            background: #45a049;
        }
    </style>
</head>
<body>
    <div id="gameContainer">
        <div id="loginForm">
            <h2>LOMP Stack Game</h2>
            <div>
                <input type="text" id="username" placeholder="Username" required>
                <input type="password" id="password" placeholder="Password" required>
            </div>
            <div>
                <button onclick="login()">Login</button>
                <button onclick="register()">Register</button>
            </div>
        </div>
        
        <div id="ui" class="hidden">
            <div>Player: <span id="playerName"></span></div>
            <div>Score: <span id="playerScore">0</span></div>
            <div>Health: <span id="playerHealth">100</span></div>
            <div>Players Online: <span id="playersOnline">0</span></div>
        </div>
        
        <canvas id="gameCanvas" width="800" height="600" class="hidden"></canvas>
        
        <div id="chatContainer" class="hidden">
            <div id="chatMessages"></div>
            <input type="text" id="chatInput" placeholder="Type a message..." onkeypress="handleChatInput(event)">
        </div>
    </div>
    
    <script src="/socket.io/socket.io.js"></script>
    <script>
        let socket;
        let token = localStorage.getItem('gameToken');
        let player = null;
        let players = new Map();
        let canvas, ctx;
        
        // Initialize game
        function init() {
            canvas = document.getElementById('gameCanvas');
            ctx = canvas.getContext('2d');
            
            if (token) {
                connectWithToken(token);
            }
        }
        
        // Authentication functions
        async function login() {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            try {
                const response = await fetch('/api/login', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ username, password })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    token = data.token;
                    localStorage.setItem('gameToken', token);
                    connectWithToken(token);
                } else {
                    alert('Login failed: ' + data.error);
                }
            } catch (error) {
                alert('Login error: ' + error.message);
            }
        }
        
        async function register() {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const email = username + '@example.com'; // Simple email generation
            
            try {
                const response = await fetch('/api/register', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ username, email, password })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    token = data.token;
                    localStorage.setItem('gameToken', token);
                    connectWithToken(token);
                } else {
                    alert('Registration failed: ' + data.error);
                }
            } catch (error) {
                alert('Registration error: ' + error.message);
            }
        }
        
        // Socket connection
        function connectWithToken(token) {
            socket = io();
            
            socket.on('connect', () => {
                socket.emit('authenticate', token);
            });
            
            socket.on('authenticated', (data) => {
                if (data.success) {
                    document.getElementById('loginForm').classList.add('hidden');
                    document.getElementById('ui').classList.remove('hidden');
                    document.getElementById('gameCanvas').classList.remove('hidden');
                    document.getElementById('chatContainer').classList.remove('hidden');
                    
                    // Join default room
                    socket.emit('joinRoom', 'lobby');
                    
                    // Start game loop
                    gameLoop();
                } else {
                    alert('Authentication failed: ' + data.error);
                    localStorage.removeItem('gameToken');
                }
            });
            
            // Game events
            socket.on('gameState', (data) => {
                players.clear();
                data.players.forEach(p => {
                    players.set(p.id, p);
                });
                document.getElementById('playersOnline').textContent = data.players.length;
            });
            
            socket.on('chatMessage', (data) => {
                addChatMessage(data.username + ': ' + data.message);
            });
            
            socket.on('playerJoined', (data) => {
                addChatMessage(data.username + ' joined the game');
            });
            
            socket.on('playerLeft', (data) => {
                addChatMessage(data.username + ' left the game');
            });
        }
        
        // Game rendering
        function gameLoop() {
            // Clear canvas
            ctx.fillStyle = '#000';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            
            // Draw players
            players.forEach((player, id) => {
                ctx.fillStyle = id === socket.id ? '#00ff00' : '#ff0000';
                ctx.fillRect(player.x, player.y, 20, 20);
                
                // Draw username
                ctx.fillStyle = '#fff';
                ctx.font = '12px Arial';
                ctx.fillText(player.username, player.x, player.y - 5);
            });
            
            requestAnimationFrame(gameLoop);
        }
        
        // Input handling
        document.addEventListener('keydown', (e) => {
            if (!socket) return;
            
            const moveSpeed = 5;
            let newX = 0, newY = 0;
            
            switch(e.key) {
                case 'ArrowUp': newY = -moveSpeed; break;
                case 'ArrowDown': newY = moveSpeed; break;
                case 'ArrowLeft': newX = -moveSpeed; break;
                case 'ArrowRight': newX = moveSpeed; break;
                case ' ': 
                    socket.emit('playerAction', { action: 'shoot' });
                    break;
            }
            
            if (newX !== 0 || newY !== 0) {
                const currentPlayer = players.get(socket.id);
                if (currentPlayer) {
                    socket.emit('playerMove', {
                        x: Math.max(0, Math.min(canvas.width - 20, currentPlayer.x + newX)),
                        y: Math.max(0, Math.min(canvas.height - 20, currentPlayer.y + newY))
                    });
                }
            }
        });
        
        // Chat functions
        function handleChatInput(event) {
            if (event.key === 'Enter') {
                const input = document.getElementById('chatInput');
                if (input.value.trim() && socket) {
                    socket.emit('chatMessage', input.value);
                    input.value = '';
                }
            }
        }
        
        function addChatMessage(message) {
            const chatMessages = document.getElementById('chatMessages');
            const messageElement = document.createElement('div');
            messageElement.textContent = message;
            chatMessages.appendChild(messageElement);
            chatMessages.scrollTop = chatMessages.scrollHeight;
        }
        
        // Initialize when page loads
        window.onload = init;
    </script>
</body>
</html>
EOF
    
    # Install dependencies
    cd "$game_dir" || return 1
    npm install
    
    # Create systemd service
    cat > "/etc/systemd/system/nodejs-game-$game_name.service" << EOF
[Unit]
Description=Node.js Game Server ($game_name)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$game_dir
Environment=NODE_ENV=production
Environment=JWT_SECRET=$(openssl rand -base64 32)
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable "nodejs-game-$game_name"
    systemctl start "nodejs-game-$game_name"
    
    log_message "INFO" "Node.js game template $game_name created successfully"
}

# Setup game load balancer
setup_game_load_balancer() {
    log_message "INFO" "Setting up game load balancer..."
    
    local lb_dir="$GAMING_DATA_DIR/load_balancer"
    mkdir -p "$lb_dir"
    
    # Install HAProxy if not present
    if ! command -v haproxy &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            apt-get install -y haproxy
        elif command -v yum &> /dev/null; then
            yum install -y haproxy
        fi
    fi
    
    # Create HAProxy configuration
    cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    daemon
    maxconn 4096
    log stdout local0

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    log global

frontend gaming_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/gaming.pem
    redirect scheme https if !{ ssl_fc }
    default_backend gaming_servers

backend gaming_servers
    balance roundrobin
    option httpchk GET /health
    server game1 127.0.0.1:3000 check
    server game2 127.0.0.1:3001 check
    server game3 127.0.0.1:3002 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
EOF
    
    # Create SSL certificate (self-signed for demo)
    openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/private/gaming.key -out /etc/ssl/certs/gaming.crt -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=gaming.local"
    cat /etc/ssl/certs/gaming.crt /etc/ssl/private/gaming.key > /etc/ssl/certs/gaming.pem
    
    systemctl enable haproxy
    systemctl restart haproxy
    
    log_message "INFO" "Game load balancer setup completed"
}

# Setup game analytics
setup_game_analytics() {
    log_message "INFO" "Setting up game analytics..."
    
    local analytics_dir="$GAMING_DATA_DIR/analytics"
    mkdir -p "$analytics_dir"
    
    # Create analytics server
    cat > "$analytics_dir/analytics.js" << 'EOF'
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');

const app = express();
app.use(express.json());

// Analytics data schema
const analyticsSchema = new mongoose.Schema({
    event: String,
    playerId: String,
    gameId: String,
    timestamp: { type: Date, default: Date.now },
    data: mongoose.Schema.Types.Mixed
});

const Analytics = mongoose.model('Analytics', analyticsSchema);

// Connect to databases
mongoose.connect('mongodb://localhost:27017/gaming_analytics');
const redisClient = redis.createClient();

// Analytics endpoints
app.post('/api/analytics/event', async (req, res) => {
    try {
        const { event, playerId, gameId, data } = req.body;
        
        const analyticsRecord = new Analytics({
            event,
            playerId,
            gameId,
            data
        });
        
        await analyticsRecord.save();
        
        // Update real-time stats in Redis
        await redisClient.incr(`events:${event}`);
        await redisClient.incr(`players:${playerId}:events`);
        
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/analytics/stats', async (req, res) => {
    try {
        const { timeframe = '24h' } = req.query;
        
        const timeAgo = new Date();
        timeAgo.setHours(timeAgo.getHours() - (timeframe === '24h' ? 24 : 1));
        
        const stats = await Analytics.aggregate([
            { $match: { timestamp: { $gte: timeAgo } } },
            { $group: { 
                _id: '$event', 
                count: { $sum: 1 } 
            }}
        ]);
        
        const playerCount = await Analytics.distinct('playerId', {
            timestamp: { $gte: timeAgo }
        });
        
        res.json({
            events: stats,
            uniquePlayers: playerCount.length,
            timeframe
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 3010;
app.listen(PORT, () => {
    console.log(`Analytics server running on port ${PORT}`);
});
EOF
    
    cd "$analytics_dir" || return 1
    npm init -y
    npm install express mongoose redis
    
    # Create systemd service
    cat > /etc/systemd/system/game-analytics.service << EOF
[Unit]
Description=Game Analytics Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$analytics_dir
ExecStart=/usr/bin/node analytics.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable game-analytics
    systemctl start game-analytics
    
    log_message "INFO" "Game analytics setup completed"
}

# Monitor gaming infrastructure
monitor_gaming_infrastructure() {
    log_message "INFO" "Starting gaming infrastructure monitoring..."
    
    # Create monitoring script
    cat > "$GAMING_DATA_DIR/monitor.sh" << 'EOF'
#!/bin/bash

LOGFILE="/var/log/gaming_monitoring.log"

while true; do
    echo "$(date): === Gaming Infrastructure Monitoring ===" >> "$LOGFILE"
    
    # Check game servers
    for service in minecraft-* nodejs-game-* game-analytics haproxy; do
        if systemctl list-units --type=service | grep -q "$service"; then
            if systemctl is-active --quiet "$service"; then
                echo "$(date): $service: Running" >> "$LOGFILE"
            else
                echo "$(date): $service: Stopped" >> "$LOGFILE"
            fi
        fi
    done
    
    # Check database connections
    if systemctl is-active --quiet mongod; then
        echo "$(date): MongoDB: Running" >> "$LOGFILE"
        MONGO_CONNECTIONS=$(mongo --eval "db.serverStatus().connections.current" --quiet 2>/dev/null || echo "N/A")
        echo "$(date): MongoDB Connections: $MONGO_CONNECTIONS" >> "$LOGFILE"
    else
        echo "$(date): MongoDB: Stopped" >> "$LOGFILE"
    fi
    
    if systemctl is-active --quiet redis; then
        echo "$(date): Redis: Running" >> "$LOGFILE"
        REDIS_CONNECTIONS=$(redis-cli info clients | grep connected_clients | cut -d: -f2 | tr -d '\r' 2>/dev/null || echo "N/A")
        echo "$(date): Redis Connections: $REDIS_CONNECTIONS" >> "$LOGFILE"
    else
        echo "$(date): Redis: Stopped" >> "$LOGFILE"
    fi
    
    # Check system resources
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    echo "$(date): CPU Usage: ${CPU_USAGE}%" >> "$LOGFILE"
    echo "$(date): Memory Usage: ${MEMORY_USAGE}%" >> "$LOGFILE"
    
    echo "$(date): ======================================" >> "$LOGFILE"
    
    sleep 300  # 5 minutes
done
EOF

    chmod +x "$GAMING_DATA_DIR/monitor.sh"
    nohup "$GAMING_DATA_DIR/monitor.sh" &
    
    log_message "INFO" "Gaming infrastructure monitoring started"
}

# Show gaming status
show_gaming_status() {
    clear
    echo "==============================================="
    echo "        LOMP Gaming Infrastructure Status"
    echo "==============================================="
    echo
    
    # Service status
    echo "🎮 Gaming Services:"
    services=("haproxy" "mongod" "redis" "game-analytics")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "  ✅ $service: Running"
        else
            echo "  ❌ $service: Stopped"
        fi
    done
    
    # Game servers
    echo
    echo "🎯 Game Servers:"
    minecraft_servers=$(systemctl list-units --type=service | grep "minecraft-" | wc -l)
    nodejs_servers=$(systemctl list-units --type=service | grep "nodejs-game-" | wc -l)
    echo "  🟢 Minecraft Servers: $minecraft_servers"
    echo "  🟡 Node.js Game Servers: $nodejs_servers"
    echo
    
    # Database status
    echo "💾 Databases:"
    if systemctl is-active --quiet mongod; then
        if command -v mongo &> /dev/null; then
            mongo_connections=$(mongo --eval "db.serverStatus().connections.current" --quiet 2>/dev/null || echo "N/A")
            echo "  📊 MongoDB Connections: $mongo_connections"
        else
            echo "  📊 MongoDB: Running (connections unknown)"
        fi
    else
        echo "  ❌ MongoDB: Not running"
    fi
    
    if systemctl is-active --quiet redis; then
        if command -v redis-cli &> /dev/null; then
            redis_connections=$(redis-cli info clients 2>/dev/null | grep connected_clients | cut -d: -f2 | tr -d '\r' || echo "N/A")
            echo "  ⚡ Redis Connections: $redis_connections"
        else
            echo "  ⚡ Redis: Running (connections unknown)"
        fi
    else
        echo "  ❌ Redis: Not running"
    fi
    echo
    
    # System resources
    echo "🖥️ System Resources:"
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    memory_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    echo "  💻 CPU Usage: ${cpu_usage}%"
    echo "  🧠 Memory Usage: ${memory_usage}%"
    echo
    
    # Game worlds and assets
    echo "🌍 Game Content:"
    if [[ -d "$GAMING_WORLDS_DIR" ]]; then
        world_count=$(ls -1 "$GAMING_WORLDS_DIR" 2>/dev/null | wc -l)
        echo "  🗺️  Game Worlds: $world_count"
    else
        echo "  🗺️  Game Worlds: 0"
    fi
    
    if [[ -d "$GAMING_ASSETS_DIR" ]]; then
        asset_count=$(find "$GAMING_ASSETS_DIR" -type f 2>/dev/null | wc -l)
        echo "  🎨 Game Assets: $asset_count"
    else
        echo "  🎨 Game Assets: 0"
    fi
    echo
}

# Main gaming menu
gaming_infrastructure_menu() {
    while true; do
        show_gaming_status
        echo "==============================================="
        echo "        Gaming Infrastructure Manager"
        echo "==============================================="
        echo "1.  🚀 Initialize Gaming Environment"
        echo "2.  📦 Install Dependencies"
        echo "3.  ⛏️  Setup Minecraft Server"
        echo "4.  🎯 Create Node.js Game Template"
        echo "5.  ⚖️  Setup Load Balancer"
        echo "6.  📊 Setup Analytics"
        echo "7.  🔍 Monitor Infrastructure"
        echo "8.  🎮 Game Server Management"
        echo "9.  🌍 World Management"
        echo "10. 👥 Player Management"
        echo "11. 🎨 Asset Management"
        echo "12. 🛡️  Anti-Cheat System"
        echo "13. 📋 Show Status"
        echo "0.  ← Return to Main Menu"
        echo "==============================================="
        
        read -p "Select option [0-13]: " choice
        
        case $choice in
            1)
                init_gaming_environment
                read -p "Press Enter to continue..."
                ;;
            2)
                install_gaming_dependencies
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter server name [minecraft-server]: " server_name
                read -p "Enter Minecraft version [1.20.1]: " version
                read -p "Enter memory allocation [4G]: " memory
                setup_minecraft_server "${server_name:-minecraft-server}" "${version:-1.20.1}" "${memory:-4G}"
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter game name: " game_name
                create_nodejs_game_template "$game_name"
                read -p "Press Enter to continue..."
                ;;
            5)
                setup_game_load_balancer
                read -p "Press Enter to continue..."
                ;;
            6)
                setup_game_analytics
                read -p "Press Enter to continue..."
                ;;
            7)
                monitor_gaming_infrastructure
                read -p "Press Enter to continue..."
                ;;
            8)
                echo "Game Server Management - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            9)
                echo "World Management - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            10)
                echo "Player Management - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "Asset Management - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            12)
                echo "Anti-Cheat System - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            13)
                show_gaming_status
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
            init_gaming_environment
            ;;
        "install")
            install_gaming_dependencies
            ;;
        "minecraft")
            setup_minecraft_server "${2:-minecraft-server}" "${3:-1.20.1}" "${4:-4G}"
            ;;
        "nodejs")
            create_nodejs_game_template "$2"
            ;;
        "loadbalancer")
            setup_game_load_balancer
            ;;
        "analytics")
            setup_game_analytics
            ;;
        "monitor")
            monitor_gaming_infrastructure
            ;;
        "status")
            show_gaming_status
            ;;
        "menu"|*)
            gaming_infrastructure_menu
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
