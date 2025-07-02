#!/bin/bash
#
# blockchain_web3_manager.sh - Part of LOMP Stack v3.0
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

# LOMP Stack - Blockchain & Web3 Manager
# Phase 5: Next Generation Features
# Advanced blockchain and Web3 infrastructure management
# Version: 1.0.0

# Source required dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(dirname "$SCRIPT_DIR")"

source "$STACK_ROOT/helpers/utils/functions.sh"
source "$STACK_ROOT/helpers/utils/config_helpers.sh"
source "$STACK_ROOT/helpers/utils/notify_helpers.sh"
source "$STACK_ROOT/helpers/monitoring/system_helpers.sh"

# Blockchain Configuration
BLOCKCHAIN_CONFIG_FILE="$SCRIPT_DIR/blockchain_config.json"
export BLOCKCHAIN_LOG_FILE="/var/log/lomp_blockchain.log"
BLOCKCHAIN_DATA_DIR="/opt/lomp/blockchain"
BLOCKCHAIN_NODES_DIR="$BLOCKCHAIN_DATA_DIR/nodes"
BLOCKCHAIN_CONTRACTS_DIR="$BLOCKCHAIN_DATA_DIR/contracts"
BLOCKCHAIN_WALLETS_DIR="$BLOCKCHAIN_DATA_DIR/wallets"

# Blockchain Functions

# Initialize blockchain environment
init_blockchain_environment() {
    log_message "INFO" "Initializing LOMP Blockchain & Web3 Manager..."
    
    # Create directories
    mkdir -p "$BLOCKCHAIN_DATA_DIR" "$BLOCKCHAIN_NODES_DIR" "$BLOCKCHAIN_CONTRACTS_DIR" "$BLOCKCHAIN_WALLETS_DIR"
    mkdir -p "/etc/lomp/blockchain" "/var/lib/lomp/blockchain"
    
    # Set permissions
    chmod 755 "$BLOCKCHAIN_DATA_DIR" "$BLOCKCHAIN_NODES_DIR"
    chmod 700 "$BLOCKCHAIN_CONTRACTS_DIR" "$BLOCKCHAIN_WALLETS_DIR"
    
    # Initialize configuration if not exists
    if [[ ! -f "$BLOCKCHAIN_CONFIG_FILE" ]]; then
        create_default_blockchain_config
    fi
    
    log_message "INFO" "Blockchain environment initialized successfully"
    return 0
}

# Create default blockchain configuration
create_default_blockchain_config() {
    cat > "$BLOCKCHAIN_CONFIG_FILE" << 'EOF'
{
  "blockchain": {
    "version": "1.0.0",
    "networks": {
      "ethereum": {
        "enabled": true,
        "node_type": "geth",
        "chain_id": 1,
        "rpc_port": 8545,
        "ws_port": 8546,
        "sync_mode": "snap"
      },
      "polygon": {
        "enabled": false,
        "node_type": "polygon-edge",
        "chain_id": 137,
        "rpc_port": 8547,
        "ws_port": 8548
      },
      "binance": {
        "enabled": false,
        "node_type": "bsc",
        "chain_id": 56,
        "rpc_port": 8549,
        "ws_port": 8550
      }
    },
    "consensus": {
      "algorithm": "proof_of_stake",
      "validators": 4,
      "block_time": 12,
      "finality": 64
    },
    "smart_contracts": {
      "compiler": "solc",
      "version": "0.8.19",
      "optimization": true,
      "gas_limit": 8000000
    },
    "security": {
      "encryption": "AES-256",
      "key_management": "HSM",
      "multi_sig": true,
      "audit_enabled": true
    },
    "storage": {
      "type": "ipfs",
      "replication": 3,
      "encryption": true,
      "backup_enabled": true
    },
    "monitoring": {
      "enabled": true,
      "metrics": ["transactions", "gas_usage", "block_time", "network_health"],
      "alerting": true,
      "performance_tracking": true
    }
  }
}
EOF
    log_message "INFO" "Default blockchain configuration created"
}

# Install blockchain dependencies
install_blockchain_dependencies() {
    log_message "INFO" "Installing blockchain dependencies..."
    
    # Update package manager
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y curl wget git build-essential software-properties-common
    elif command -v yum &> /dev/null; then
        yum update -y
        yum groupinstall -y "Development Tools"
        yum install -y curl wget git
    fi
    
    # Install Node.js and npm
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # Install Go (required for many blockchain clients)
    if ! command -v go &> /dev/null; then
        wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
        tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    
    # Install Python and pip (for Web3.py)
    if ! command -v python3 &> /dev/null; then
        apt-get install -y python3 python3-pip
    fi
    
    # Install Rust (for some blockchain tools)
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck source=/dev/null
        source ~/.cargo/env
    fi
    
    # Install blockchain-specific tools
    npm install -g @truffle/truffle ganache hardhat @openzeppelin/contracts web3
    pip3 install web3 eth-account py-evm
    
    log_message "INFO" "Blockchain dependencies installed successfully"
}

# Setup Ethereum node
setup_ethereum_node() {
    local node_type=${1:-"geth"}
    
    log_message "INFO" "Setting up Ethereum node with $node_type..."
    
    case $node_type in
        "geth")
            setup_geth_node
            ;;
        "erigon")
            setup_erigon_node
            ;;
        "nethermind")
            setup_nethermind_node
            ;;
        *)
            log_message "ERROR" "Unsupported Ethereum node type: $node_type"
            return 1
            ;;
    esac
    
    log_message "INFO" "Ethereum node setup completed"
}

# Setup Geth node
setup_geth_node() {
    # Download and install Geth
    if ! command -v geth &> /dev/null; then
        add-apt-repository -y ppa:ethereum/ethereum
        apt-get update
        apt-get install -y ethereum
    fi
    
    # Create Geth data directory
    mkdir -p "$BLOCKCHAIN_NODES_DIR/geth"
    
    # Initialize Geth
    geth --datadir "$BLOCKCHAIN_NODES_DIR/geth" init << 'EOF'
{
  "config": {
    "chainId": 1337,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0
  },
  "alloc": {},
  "coinbase": "0x0000000000000000000000000000000000000000",
  "difficulty": "0x20000",
  "extraData": "",
  "gasLimit": "0x2fefd8",
  "nonce": "0x0000000000000042",
  "mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "timestamp": "0x00"
}
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/geth.service << EOF
[Unit]
Description=Ethereum Geth Client
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/geth --datadir $BLOCKCHAIN_NODES_DIR/geth --http --http.addr 0.0.0.0 --http.port 8545 --http.api eth,net,web3,personal --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3 --allow-insecure-unlock
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable geth
    systemctl start geth
}

# Setup IPFS for decentralized storage
setup_ipfs_storage() {
    log_message "INFO" "Setting up IPFS decentralized storage..."
    
    # Download and install IPFS
    if ! command -v ipfs &> /dev/null; then
        wget https://dist.ipfs.tech/kubo/v0.22.0/kubo_v0.22.0_linux-amd64.tar.gz
        tar -xzf kubo_v0.22.0_linux-amd64.tar.gz
        cd kubo || return 1
        bash install.sh
        cd .. && rm -rf kubo kubo_v0.22.0_linux-amd64.tar.gz
    fi
    
    # Initialize IPFS
    export IPFS_PATH="$BLOCKCHAIN_DATA_DIR/ipfs"
    mkdir -p "$IPFS_PATH"
    ipfs init
    
    # Configure IPFS
    ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
    ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "GET", "POST"]'
    
    # Create systemd service
    cat > /etc/systemd/system/ipfs.service << EOF
[Unit]
Description=IPFS Daemon
After=network.target

[Service]
Type=simple
User=root
Environment=IPFS_PATH=$BLOCKCHAIN_DATA_DIR/ipfs
ExecStart=/usr/local/bin/ipfs daemon
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable ipfs
    systemctl start ipfs
    
    log_message "INFO" "IPFS storage setup completed"
}

# Deploy smart contract
deploy_smart_contract() {
    local contract_name="$1"
    local contract_source="$2"
    
    if [[ -z "$contract_name" || -z "$contract_source" ]]; then
        log_message "ERROR" "Contract name and source are required"
        return 1
    fi
    
    log_message "INFO" "Deploying smart contract: $contract_name"
    
    local contract_dir="$BLOCKCHAIN_CONTRACTS_DIR/$contract_name"
    mkdir -p "$contract_dir"
    
    # Create contract file
    cat > "$contract_dir/$contract_name.sol" << EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

$contract_source
EOF
    
    # Create deployment script
    cat > "$contract_dir/deploy.js" << EOF
const fs = require('fs');
const solc = require('solc');
const Web3 = require('web3');

// Connect to Ethereum node
const web3 = new Web3('http://localhost:8545');

async function deployContract() {
    try {
        // Read contract source
        const source = fs.readFileSync('$contract_name.sol', 'utf8');
        
        // Compile contract
        const input = {
            language: 'Solidity',
            sources: {
                '$contract_name.sol': {
                    content: source
                }
            },
            settings: {
                outputSelection: {
                    '*': {
                        '*': ['*']
                    }
                }
            }
        };
        
        const output = JSON.parse(solc.compile(JSON.stringify(input)));
        const bytecode = output.contracts['$contract_name.sol']['$contract_name'].evm.bytecode.object;
        const abi = output.contracts['$contract_name.sol']['$contract_name'].abi;
        
        // Get accounts
        const accounts = await web3.eth.getAccounts();
        
        // Deploy contract
        const contract = new web3.eth.Contract(abi);
        const deployed = await contract.deploy({
            data: '0x' + bytecode
        }).send({
            from: accounts[0],
            gas: 3000000
        });
        
        console.log('Contract deployed at:', deployed.options.address);
        
        // Save deployment info
        fs.writeFileSync('deployment.json', JSON.stringify({
            address: deployed.options.address,
            abi: abi,
            deployedAt: new Date().toISOString()
        }, null, 2));
        
    } catch (error) {
        console.error('Deployment failed:', error);
    }
}

deployContract();
EOF
    
    # Install required npm packages
    cd "$contract_dir" || return 1
    npm init -y
    npm install solc web3
    
    # Deploy the contract
    node deploy.js
    
    log_message "INFO" "Smart contract $contract_name deployed successfully"
}

# Create DApp template
create_dapp_template() {
    local dapp_name="$1"
    
    if [[ -z "$dapp_name" ]]; then
        log_message "ERROR" "DApp name is required"
        return 1
    fi
    
    log_message "INFO" "Creating DApp template: $dapp_name"
    
    local dapp_dir="$BLOCKCHAIN_DATA_DIR/dapps/$dapp_name"
    mkdir -p "$dapp_dir"
    
    # Create package.json
    cat > "$dapp_dir/package.json" << EOF
{
  "name": "$dapp_name",
  "version": "1.0.0",
  "description": "LOMP Stack DApp",
  "main": "index.js",
  "scripts": {
    "start": "npm run build && npm run serve",
    "build": "webpack --mode production",
    "dev": "webpack-dev-server --mode development",
    "serve": "http-server dist",
    "test": "mocha test/**/*.js"
  },
  "dependencies": {
    "web3": "^4.0.0",
    "@metamask/detect-provider": "^2.0.0",
    "ethers": "^6.0.0"
  },
  "devDependencies": {
    "webpack": "^5.0.0",
    "webpack-cli": "^5.0.0",
    "webpack-dev-server": "^4.0.0",
    "html-webpack-plugin": "^5.0.0",
    "css-loader": "^6.0.0",
    "style-loader": "^3.0.0",
    "http-server": "^14.0.0",
    "mocha": "^10.0.0",
    "chai": "^4.0.0"
  }
}
EOF
    
    # Create HTML template
    cat > "$dapp_dir/src/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LOMP Stack DApp</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .wallet-status {
            background: rgba(255, 255, 255, 0.2);
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        button {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            margin: 5px;
        }
        button:hover {
            background: #45a049;
        }
        .contract-interaction {
            background: rgba(255, 255, 255, 0.1);
            padding: 20px;
            border-radius: 10px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 LOMP Stack DApp</h1>
        
        <div class="wallet-status">
            <h3>Wallet Status</h3>
            <div id="wallet-info">
                <p>Status: <span id="wallet-status">Disconnected</span></p>
                <p>Address: <span id="wallet-address">-</span></p>
                <p>Balance: <span id="wallet-balance">-</span> ETH</p>
            </div>
            <button id="connect-wallet">Connect Wallet</button>
        </div>
        
        <div class="contract-interaction">
            <h3>Smart Contract Interaction</h3>
            <div id="contract-info">
                <p>Contract: <span id="contract-address">Not deployed</span></p>
            </div>
            <button id="deploy-contract">Deploy Contract</button>
            <button id="interact-contract">Interact with Contract</button>
        </div>
        
        <div id="output"></div>
    </div>
    
    <script src="app.js"></script>
</body>
</html>
EOF
    
    # Create JavaScript application
    cat > "$dapp_dir/src/app.js" << 'EOF'
import Web3 from 'web3';
import detectEthereumProvider from '@metamask/detect-provider';

class DApp {
    constructor() {
        this.web3 = null;
        this.account = null;
        this.contract = null;
        this.init();
    }
    
    async init() {
        // Initialize Web3
        const provider = await detectEthereumProvider();
        
        if (provider) {
            this.web3 = new Web3(provider);
            this.setupEventListeners();
            this.updateUI();
        } else {
            this.showMessage('Please install MetaMask!', 'error');
        }
    }
    
    setupEventListeners() {
        document.getElementById('connect-wallet').addEventListener('click', () => this.connectWallet());
        document.getElementById('deploy-contract').addEventListener('click', () => this.deployContract());
        document.getElementById('interact-contract').addEventListener('click', () => this.interactWithContract());
        
        // Listen for account changes
        if (window.ethereum) {
            window.ethereum.on('accountsChanged', (accounts) => {
                this.account = accounts[0];
                this.updateUI();
            });
        }
    }
    
    async connectWallet() {
        try {
            const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts'
            });
            
            this.account = accounts[0];
            this.updateUI();
            this.showMessage('Wallet connected successfully!', 'success');
        } catch (error) {
            this.showMessage('Failed to connect wallet: ' + error.message, 'error');
        }
    }
    
    async updateUI() {
        if (this.account) {
            document.getElementById('wallet-status').textContent = 'Connected';
            document.getElementById('wallet-address').textContent = this.account;
            
            // Get balance
            const balance = await this.web3.eth.getBalance(this.account);
            const balanceEth = this.web3.utils.fromWei(balance, 'ether');
            document.getElementById('wallet-balance').textContent = parseFloat(balanceEth).toFixed(4);
        } else {
            document.getElementById('wallet-status').textContent = 'Disconnected';
            document.getElementById('wallet-address').textContent = '-';
            document.getElementById('wallet-balance').textContent = '-';
        }
    }
    
    async deployContract() {
        if (!this.account) {
            this.showMessage('Please connect your wallet first!', 'error');
            return;
        }
        
        // Simple contract ABI and bytecode (example)
        const contractABI = [
            {
                "inputs": [],
                "name": "getValue",
                "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
                "stateMutability": "view",
                "type": "function"
            },
            {
                "inputs": [{"internalType": "uint256", "name": "_value", "type": "uint256"}],
                "name": "setValue",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function"
            }
        ];
        
        const contractBytecode = "0x608060405234801561001057600080fd5b50610150806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c806320965255146100"
        
        try {
            this.showMessage('Deploying contract...', 'info');
            
            const contract = new this.web3.eth.Contract(contractABI);
            const deployedContract = await contract.deploy({
                data: contractBytecode
            }).send({
                from: this.account,
                gas: 1000000
            });
            
            this.contract = deployedContract;
            document.getElementById('contract-address').textContent = deployedContract.options.address;
            this.showMessage('Contract deployed successfully!', 'success');
            
        } catch (error) {
            this.showMessage('Failed to deploy contract: ' + error.message, 'error');
        }
    }
    
    async interactWithContract() {
        if (!this.contract) {
            this.showMessage('Please deploy a contract first!', 'error');
            return;
        }
        
        try {
            // Example interaction: set a value
            await this.contract.methods.setValue(42).send({
                from: this.account,
                gas: 100000
            });
            
            // Get the value back
            const value = await this.contract.methods.getValue().call();
            this.showMessage(`Contract interaction successful! Value: ${value}`, 'success');
            
        } catch (error) {
            this.showMessage('Failed to interact with contract: ' + error.message, 'error');
        }
    }
    
    showMessage(message, type) {
        const output = document.getElementById('output');
        const messageDiv = document.createElement('div');
        messageDiv.style.padding = '10px';
        messageDiv.style.margin = '10px 0';
        messageDiv.style.borderRadius = '5px';
        messageDiv.textContent = message;
        
        switch (type) {
            case 'success':
                messageDiv.style.background = 'rgba(76, 175, 80, 0.3)';
                break;
            case 'error':
                messageDiv.style.background = 'rgba(244, 67, 54, 0.3)';
                break;
            case 'info':
                messageDiv.style.background = 'rgba(33, 150, 243, 0.3)';
                break;
        }
        
        output.appendChild(messageDiv);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (messageDiv.parentNode) {
                messageDiv.parentNode.removeChild(messageDiv);
            }
        }, 5000);
    }
}

// Initialize DApp when page loads
document.addEventListener('DOMContentLoaded', () => {
    new DApp();
});
EOF
    
    # Create webpack config
    cat > "$dapp_dir/webpack.config.js" << 'EOF'
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
    entry: './src/app.js',
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'bundle.js'
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: './src/index.html'
        })
    ],
    module: {
        rules: [
            {
                test: /\.css$/,
                use: ['style-loader', 'css-loader']
            }
        ]
    },
    devServer: {
        static: './dist',
        port: 3000
    },
    resolve: {
        fallback: {
            "crypto": require.resolve("crypto-browserify"),
            "stream": require.resolve("stream-browserify"),
            "assert": require.resolve("assert"),
            "http": require.resolve("stream-http"),
            "https": require.resolve("https-browserify"),
            "os": require.resolve("os-browserify"),
            "url": require.resolve("url")
        }
    }
};
EOF
    
    # Install dependencies
    cd "$dapp_dir" || return 1
    npm install
    
    log_message "INFO" "DApp template $dapp_name created successfully"
}

# Setup Web3 API gateway
setup_web3_gateway() {
    log_message "INFO" "Setting up Web3 API Gateway..."
    
    local gateway_dir="$BLOCKCHAIN_DATA_DIR/gateway"
    mkdir -p "$gateway_dir"
    
    # Create API gateway server
    cat > "$gateway_dir/server.js" << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const Web3 = require('web3');

const app = express();
const port = process.env.PORT || 3001;

// Initialize Web3
const web3 = new Web3('http://localhost:8545');

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Authentication middleware
const authenticate = (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    if (!apiKey || apiKey !== process.env.API_KEY) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
};

// Routes

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Get network info
app.get('/api/network/info', authenticate, async (req, res) => {
    try {
        const [chainId, blockNumber, gasPrice] = await Promise.all([
            web3.eth.getChainId(),
            web3.eth.getBlockNumber(),
            web3.eth.getGasPrice()
        ]);
        
        res.json({
            chainId: chainId.toString(),
            blockNumber: blockNumber.toString(),
            gasPrice: gasPrice.toString()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get account balance
app.get('/api/account/:address/balance', authenticate, async (req, res) => {
    try {
        const { address } = req.params;
        const balance = await web3.eth.getBalance(address);
        
        res.json({
            address,
            balance: balance.toString(),
            balanceEth: web3.utils.fromWei(balance, 'ether')
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Send transaction
app.post('/api/transaction/send', authenticate, async (req, res) => {
    try {
        const { from, to, value, data, privateKey } = req.body;
        
        const account = web3.eth.accounts.privateKeyToAccount(privateKey);
        web3.eth.accounts.wallet.add(account);
        
        const transaction = {
            from,
            to,
            value: web3.utils.toWei(value.toString(), 'ether'),
            gas: 21000,
            data: data || '0x'
        };
        
        const result = await web3.eth.sendTransaction(transaction);
        
        res.json({
            transactionHash: result.transactionHash,
            blockNumber: result.blockNumber?.toString(),
            gasUsed: result.gasUsed?.toString()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Deploy contract
app.post('/api/contract/deploy', authenticate, async (req, res) => {
    try {
        const { abi, bytecode, from, privateKey, constructorArgs } = req.body;
        
        const account = web3.eth.accounts.privateKeyToAccount(privateKey);
        web3.eth.accounts.wallet.add(account);
        
        const contract = new web3.eth.Contract(abi);
        const deployed = await contract.deploy({
            data: bytecode,
            arguments: constructorArgs || []
        }).send({
            from,
            gas: 3000000
        });
        
        res.json({
            contractAddress: deployed.options.address,
            transactionHash: deployed.transactionHash
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Contract interaction
app.post('/api/contract/:address/call', authenticate, async (req, res) => {
    try {
        const { address } = req.params;
        const { abi, method, args, from } = req.body;
        
        const contract = new web3.eth.Contract(abi, address);
        const result = await contract.methods[method](...(args || [])).call({ from });
        
        res.json({ result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Start server
app.listen(port, () => {
    console.log(`Web3 API Gateway running on port ${port}`);
});
EOF
    
    # Create package.json for gateway
    cat > "$gateway_dir/package.json" << 'EOF'
{
  "name": "lomp-web3-gateway",
  "version": "1.0.0",
  "description": "LOMP Stack Web3 API Gateway",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.0.0",
    "web3": "^4.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  }
}
EOF
    
    # Install dependencies and start gateway
    cd "$gateway_dir" || return 1
    npm install
    
    # Create systemd service
    cat > /etc/systemd/system/web3-gateway.service << EOF
[Unit]
Description=Web3 API Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$gateway_dir
Environment=NODE_ENV=production
Environment=API_KEY=$(openssl rand -base64 32)
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable web3-gateway
    systemctl start web3-gateway
    
    log_message "INFO" "Web3 API Gateway setup completed"
}

# Monitor blockchain network
monitor_blockchain_network() {
    log_message "INFO" "Starting blockchain network monitoring..."
    
    # Create monitoring script
    cat > "$BLOCKCHAIN_DATA_DIR/monitor.sh" << 'EOF'
#!/bin/bash

LOGFILE="/var/log/blockchain_monitoring.log"

while true; do
    echo "$(date): === Blockchain Network Monitoring ===" >> "$LOGFILE"
    
    # Check if Geth is running
    if systemctl is-active --quiet geth; then
        echo "$(date): Geth Status: Running" >> "$LOGFILE"
        
        # Get latest block
        LATEST_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            http://localhost:8545 | jq -r '.result')
        echo "$(date): Latest Block: $LATEST_BLOCK" >> "$LOGFILE"
        
        # Get peer count
        PEER_COUNT=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
            http://localhost:8545 | jq -r '.result')
        echo "$(date): Peer Count: $PEER_COUNT" >> "$LOGFILE"
        
    else
        echo "$(date): Geth Status: Stopped" >> "$LOGFILE"
    fi
    
    # Check IPFS status
    if systemctl is-active --quiet ipfs; then
        echo "$(date): IPFS Status: Running" >> "$LOGFILE"
        IPFS_PEERS=$(ipfs swarm peers | wc -l)
        echo "$(date): IPFS Peers: $IPFS_PEERS" >> "$LOGFILE"
    else
        echo "$(date): IPFS Status: Stopped" >> "$LOGFILE"
    fi
    
    # Check Web3 Gateway
    if systemctl is-active --quiet web3-gateway; then
        echo "$(date): Web3 Gateway: Running" >> "$LOGFILE"
    else
        echo "$(date): Web3 Gateway: Stopped" >> "$LOGFILE"
    fi
    
    echo "$(date): ======================================" >> "$LOGFILE"
    
    sleep 300  # 5 minutes
done
EOF

    chmod +x "$BLOCKCHAIN_DATA_DIR/monitor.sh"
    nohup "$BLOCKCHAIN_DATA_DIR/monitor.sh" &
    
    log_message "INFO" "Blockchain network monitoring started"
}

# Show blockchain status
show_blockchain_status() {
    clear
    echo "==============================================="
    echo "        LOMP Blockchain & Web3 Status"
    echo "==============================================="
    echo
    
    # Service status
    echo "🔗 Blockchain Services:"
    services=("geth" "ipfs" "web3-gateway")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "  ✅ $service: Running"
        else
            echo "  ❌ $service: Stopped"
        fi
    done
    echo
    
    # Network information
    echo "🌐 Network Information:"
    if systemctl is-active --quiet geth; then
        latest_block=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            http://localhost:8545 2>/dev/null | jq -r '.result' 2>/dev/null)
        if [[ "$latest_block" != "null" && -n "$latest_block" ]]; then
            echo "  📦 Latest Block: $((16#${latest_block#0x}))"
        else
            echo "  📦 Latest Block: Unable to fetch"
        fi
        
        peer_count=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
            http://localhost:8545 2>/dev/null | jq -r '.result' 2>/dev/null)
        if [[ "$peer_count" != "null" && -n "$peer_count" ]]; then
            echo "  👥 Connected Peers: $((16#${peer_count#0x}))"
        else
            echo "  👥 Connected Peers: Unable to fetch"
        fi
    else
        echo "  📦 Latest Block: Node not running"
        echo "  👥 Connected Peers: Node not running"
    fi
    echo
    
    # Storage information
    echo "💾 Decentralized Storage:"
    if systemctl is-active --quiet ipfs; then
        if command -v ipfs &> /dev/null; then
            ipfs_peers=$(ipfs swarm peers 2>/dev/null | wc -l)
            echo "  🌍 IPFS Peers: $ipfs_peers"
        else
            echo "  🌍 IPFS: Running (peers unknown)"
        fi
    else
        echo "  ❌ IPFS: Not running"
    fi
    echo
    
    # Smart contracts
    echo "📋 Smart Contracts:"
    if [[ -d "$BLOCKCHAIN_CONTRACTS_DIR" ]]; then
        contract_count=$(find "$BLOCKCHAIN_CONTRACTS_DIR" -name "*.sol" 2>/dev/null | wc -l)
        echo "  📄 Deployed Contracts: $contract_count"
    else
        echo "  📄 Deployed Contracts: 0"
    fi
    echo
    
    # DApps
    echo "🚀 Decentralized Apps:"
    if [[ -d "$BLOCKCHAIN_DATA_DIR/dapps" ]]; then
        dapp_count=$(ls -1 "$BLOCKCHAIN_DATA_DIR/dapps" 2>/dev/null | wc -l)
        echo "  🎯 Active DApps: $dapp_count"
    else
        echo "  🎯 Active DApps: 0"
    fi
    echo
}

# Main blockchain menu
blockchain_web3_menu() {
    while true; do
        show_blockchain_status
        echo "==============================================="
        echo "        Blockchain & Web3 Manager"
        echo "==============================================="
        echo "1.  🚀 Initialize Blockchain Environment"
        echo "2.  📦 Install Dependencies"
        echo "3.  ⛓️  Setup Ethereum Node"
        echo "4.  💾 Setup IPFS Storage"
        echo "5.  📄 Deploy Smart Contract"
        echo "6.  🎯 Create DApp Template"
        echo "7.  🌐 Setup Web3 API Gateway"
        echo "8.  🔍 Monitor Network"
        echo "9.  💰 Wallet Management"
        echo "10. 🛡️  Security Configuration"
        echo "11. 📊 Analytics Dashboard"
        echo "12. 🔄 Node Synchronization"
        echo "13. 📋 Show Status"
        echo "0.  ← Return to Main Menu"
        echo "==============================================="
        
        read -p "Select option [0-13]: " choice
        
        case $choice in
            1)
                init_blockchain_environment
                read -p "Press Enter to continue..."
                ;;
            2)
                install_blockchain_dependencies
                read -p "Press Enter to continue..."
                ;;
            3)
                echo "Ethereum Node Types:"
                echo "1. Geth (Go Ethereum)"
                echo "2. Erigon"
                echo "3. Nethermind"
                read -p "Select node type [1-3]: " node_choice
                case $node_choice in
                    1) setup_ethereum_node "geth" ;;
                    2) setup_ethereum_node "erigon" ;;
                    3) setup_ethereum_node "nethermind" ;;
                    *) echo "Invalid choice" ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            4)
                setup_ipfs_storage
                read -p "Press Enter to continue..."
                ;;
            5)
                read -p "Enter contract name: " contract_name
                echo "Enter contract source code (end with 'END' on a new line):"
                contract_source=""
                while IFS= read -r line; do
                    [[ "$line" == "END" ]] && break
                    contract_source+="$line"$'\n'
                done
                deploy_smart_contract "$contract_name" "$contract_source"
                read -p "Press Enter to continue..."
                ;;
            6)
                read -p "Enter DApp name: " dapp_name
                create_dapp_template "$dapp_name"
                read -p "Press Enter to continue..."
                ;;
            7)
                setup_web3_gateway
                read -p "Press Enter to continue..."
                ;;
            8)
                monitor_blockchain_network
                read -p "Press Enter to continue..."
                ;;
            9)
                echo "Wallet Management - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            10)
                echo "Security Configuration - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "Analytics Dashboard - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            12)
                echo "Node Synchronization - Feature coming soon!"
                read -p "Press Enter to continue..."
                ;;
            13)
                show_blockchain_status
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
            init_blockchain_environment
            ;;
        "install")
            install_blockchain_dependencies
            ;;
        "node")
            setup_ethereum_node "${2:-geth}"
            ;;
        "ipfs")
            setup_ipfs_storage
            ;;
        "deploy")
            shift
            deploy_smart_contract "$@"
            ;;
        "dapp")
            create_dapp_template "$2"
            ;;
        "gateway")
            setup_web3_gateway
            ;;
        "monitor")
            monitor_blockchain_network
            ;;
        "status")
            show_blockchain_status
            ;;
        "menu"|*)
            blockchain_web3_menu
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
