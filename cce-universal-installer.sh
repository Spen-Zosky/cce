#!/bin/bash
# CCE Universal Installer - Works on WSL, OCI VMs, and any Linux
# Architecture: AMD64/ARM64 agnostic
# Version: 1.0.0

set -e

# ============================================================================
# Environment Detection
# ============================================================================

detect_environment() {
    local ENV_TYPE="unknown"
    local ARCH=$(uname -m)
    local OS=$(uname -s)
    
    # Detect WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        ENV_TYPE="wsl"
    # Detect OCI/Cloud VM
    elif [ -f /sys/class/dmi/id/product_name ]; then
        local PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
        if [[ "$PRODUCT" == *"Virtual"* ]] || [[ "$PRODUCT" == *"KVM"* ]] || [[ "$PRODUCT" == *"Oracle"* ]]; then
            ENV_TYPE="vm"
        fi
    # Detect Docker/Container
    elif [ -f /.dockerenv ]; then
        ENV_TYPE="docker"
    # Native Linux
    else
        ENV_TYPE="native"
    fi
    
    # Architecture normalization
    case "$ARCH" in
        x86_64|amd64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) ARCH="unknown" ;;
    esac
    
    echo "$ENV_TYPE:$ARCH"
}

# ============================================================================
# Color Output Functions
# ============================================================================

setup_colors() {
    if [ -t 1 ]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        YELLOW='\033[1;33m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        NC='\033[0m'
    else
        RED=''
        GREEN=''
        BLUE=''
        YELLOW=''
        CYAN=''
        BOLD=''
        NC=''
    fi
}

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_step() { echo -e "${CYAN}▶${NC} $1"; }

# ============================================================================
# Main Installation
# ============================================================================

main() {
    setup_colors
    
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║     CCE Universal Installer - Multi-Platform        ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Environment detection
    ENV_INFO=$(detect_environment)
    ENV_TYPE="${ENV_INFO%%:*}"
    ARCH="${ENV_INFO##*:}"
    
    log_info "Environment: ${BOLD}$ENV_TYPE${NC} ($ARCH)"
    
    # Prerequisite check
    log_step "Checking prerequisites..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js not found!"
        echo "    Install with:"
        echo "    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
        echo "    sudo apt-get install -y nodejs"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "Git not found!"
        echo "    Install with: sudo apt-get install git"
        exit 1
    fi
    
    log_success "Prerequisites OK (Node $(node -v), npm $(npm -v))"
    
    # Backup existing installations
    if [ -d ~/.claude ] || [ -d ~/.cce ]; then
        log_warning "Existing CCE installation found"
        BACKUP_DIR=~/.cce-backup-$(date +%Y%m%d-%H%M%S)
        mkdir -p "$BACKUP_DIR"
        [ -d ~/.claude ] && cp -r ~/.claude "$BACKUP_DIR/"
        [ -d ~/.cce ] && cp -r ~/.cce "$BACKUP_DIR/"
        log_success "Backup created: $BACKUP_DIR"
    fi
    
    # Install Claude Code if needed
    if ! command -v claude &> /dev/null; then
        log_step "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
        log_success "Claude Code installed"
    else
        log_success "Claude Code already installed ($(claude --version 2>/dev/null || echo 'version unknown'))"
    fi
    
    # Create CCE Universal structure
    log_step "Creating CCE Universal structure..."
    
    # Core directories
    mkdir -p ~/.cce-universal/{core,adapters,sync,scripts,templates,config}
    mkdir -p ~/.cce-universal/web/{server,client,api,dashboard,public,data}
    mkdir -p ~/.cce-universal/bin
    mkdir -p ~/.claude/{commands,hooks,templates}
    
    # ============================================================================
    # Core Configuration Files
    # ============================================================================
    
    # Main CCE config
    cat > ~/.cce-universal/config/cce.json << 'EOF'
{
  "version": "1.0.0",
  "type": "universal",
  "features": {
    "autoDetect": true,
    "crossPlatform": true,
    "syncEnabled": true
  },
  "environments": {
    "wsl": {
      "pathSeparator": "/",
      "lineEnding": "auto",
      "gitConfig": {
        "core.autocrlf": "input"
      }
    },
    "vm": {
      "pathSeparator": "/",
      "lineEnding": "lf"
    },
    "native": {
      "pathSeparator": "/",
      "lineEnding": "lf"
    }
  },
  "sync": {
    "method": "git",
    "remote": "",
    "autoSync": false
  }
}
EOF
    
    # Web module configuration
    cat > ~/.cce-universal/web/config.json << 'EOF'
{
  "server": {
    "port": "auto",
    "host": "localhost",
    "autoOpen": true,
    "cors": {
      "enabled": true,
      "origins": ["http://localhost:*"]
    }
  },
  "api": {
    "prefix": "/api/v1",
    "rateLimit": {
      "enabled": true,
      "windowMs": 900000,
      "max": 100
    }
  },
  "dashboard": {
    "enabled": true,
    "theme": "auto",
    "refreshInterval": 5000
  },
  "auth": {
    "enabled": false,
    "type": "token",
    "sessionDuration": "24h"
  },
  "database": {
    "type": "sqlite",
    "path": "~/.cce-universal/web/data/cce.db"
  },
  "features": {
    "projectManager": true,
    "configEditor": true,
    "logViewer": true,
    "metrics": true,
    "terminal": false
  }
}
EOF
    
    # Web server base
    cat > ~/.cce-universal/web/server/index.js << 'EOF'
#!/usr/bin/env node
/**
 * CCE Web Server
 * Provides web interface and API for CCE management
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs').promises;
const http = require('http');
const WebSocket = require('ws');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

class CCEWebServer {
  constructor(config = {}) {
    this.config = {
      port: process.env.CCE_WEB_PORT || config.port || 3456,
      host: process.env.CCE_WEB_HOST || config.host || 'localhost',
      ...config
    };
    
    this.app = express();
    this.server = http.createServer(this.app);
    this.wss = new WebSocket.Server({ server: this.server });
    
    this.setupMiddleware();
    this.setupRoutes();
    this.setupWebSocket();
  }
  
  setupMiddleware() {
    this.app.use(cors(this.config.cors || {}));
    this.app.use(express.json());
    this.app.use(express.static(path.join(__dirname, '../public')));
    
    // Logging middleware
    this.app.use((req, res, next) => {
      console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
      next();
    });
  }
  
  setupRoutes() {
    // API prefix
    const api = express.Router();
    
    // Health check
    api.get('/health', (req, res) => {
      res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
      });
    });
    
    // System info
    api.get('/system', async (req, res) => {
      try {
        const envInfo = await this.getEnvironmentInfo();
        res.json(envInfo);
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });
    
    // Projects list
    api.get('/projects', async (req, res) => {
      try {
        const projects = await this.getProjects();
        res.json(projects);
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });
    
    // Configuration
    api.get('/config', async (req, res) => {
      try {
        const config = await this.getConfiguration();
        res.json(config);
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });
    
    // Execute CCE command
    api.post('/execute', async (req, res) => {
      const { command, args, cwd } = req.body;
      try {
        const result = await this.executeCommand(command, args, cwd);
        res.json(result);
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });
    
    // Mount API routes
    this.app.use('/api/v1', api);
    
    // Dashboard route (SPA fallback)
    this.app.get('*', (req, res) => {
      res.sendFile(path.join(__dirname, '../public/index.html'));
    });
  }
  
  setupWebSocket() {
    this.wss.on('connection', (ws) => {
      console.log('WebSocket client connected');
      
      ws.on('message', async (message) => {
        try {
          const data = JSON.parse(message);
          await this.handleWebSocketMessage(ws, data);
        } catch (error) {
          ws.send(JSON.stringify({
            type: 'error',
            error: error.message
          }));
        }
      });
      
      ws.on('close', () => {
        console.log('WebSocket client disconnected');
      });
      
      // Send initial connection confirmation
      ws.send(JSON.stringify({
        type: 'connected',
        timestamp: new Date().toISOString()
      }));
    });
  }
  
  async handleWebSocketMessage(ws, data) {
    switch (data.type) {
      case 'subscribe':
        // Subscribe to live updates
        this.subscribeToUpdates(ws, data.channel);
        break;
      
      case 'command':
        // Execute command and stream output
        await this.streamCommand(ws, data.command, data.args);
        break;
      
      default:
        ws.send(JSON.stringify({
          type: 'error',
          error: 'Unknown message type'
        }));
    }
  }
  
  async getEnvironmentInfo() {
    const { stdout: envType } = await execAsync('~/.cce-universal/scripts/detect-env.sh');
    const { stdout: nodeVersion } = await execAsync('node -v');
    const { stdout: claudeVersion } = await execAsync('claude --version 2>/dev/null || echo "not installed"');
    
    return {
      environment: envType.trim(),
      node: nodeVersion.trim(),
      claude: claudeVersion.trim(),
      cceHome: process.env.HOME + '/.cce-universal',
      platform: process.platform,
      arch: process.arch
    };
  }
  
  async getProjects() {
    const homeDir = process.env.HOME;
    const projects = [];
    
    // Scan for projects with .claude directory
    const dirs = await fs.readdir(homeDir);
    
    for (const dir of dirs) {
      const fullPath = path.join(homeDir, dir);
      const claudePath = path.join(fullPath, '.claude');
      
      try {
        const stat = await fs.stat(claudePath);
        if (stat.isDirectory()) {
          const settings = await fs.readFile(
            path.join(claudePath, 'settings.json'),
            'utf8'
          ).catch(() => '{}');
          
          projects.push({
            name: dir,
            path: fullPath,
            settings: JSON.parse(settings)
          });
        }
      } catch (error) {
        // Skip if not accessible
      }
    }
    
    return projects;
  }
  
  async getConfiguration() {
    const configPaths = [
      '~/.cce-universal/config/cce.json',
      '~/.claude/settings.json'
    ].map(p => p.replace('~', process.env.HOME));
    
    const configs = {};
    
    for (const configPath of configPaths) {
      try {
        const content = await fs.readFile(configPath, 'utf8');
        configs[path.basename(configPath)] = JSON.parse(content);
      } catch (error) {
        // Skip if not found
      }
    }
    
    return configs;
  }
  
  async executeCommand(command, args = [], cwd = process.env.HOME) {
    const fullCommand = `${command} ${args.join(' ')}`;
    const { stdout, stderr } = await execAsync(fullCommand, { cwd });
    
    return {
      command: fullCommand,
      stdout: stdout.trim(),
      stderr: stderr.trim(),
      timestamp: new Date().toISOString()
    };
  }
  
  subscribeToUpdates(ws, channel) {
    // Implement subscription logic for live updates
    const interval = setInterval(() => {
      ws.send(JSON.stringify({
        type: 'update',
        channel,
        data: {
          timestamp: new Date().toISOString(),
          // Add relevant update data
        }
      }));
    }, 5000);
    
    ws.on('close', () => {
      clearInterval(interval);
    });
  }
  
  async streamCommand(ws, command, args = []) {
    // Implement command streaming
    const child = exec(`${command} ${args.join(' ')}`);
    
    child.stdout.on('data', (data) => {
      ws.send(JSON.stringify({
        type: 'output',
        stream: 'stdout',
        data: data.toString()
      }));
    });
    
    child.stderr.on('data', (data) => {
      ws.send(JSON.stringify({
        type: 'output',
        stream: 'stderr',
        data: data.toString()
      }));
    });
    
    child.on('exit', (code) => {
      ws.send(JSON.stringify({
        type: 'exit',
        code
      }));
    });
  }
  
  async start() {
    return new Promise((resolve) => {
      this.server.listen(this.config.port, this.config.host, () => {
        console.log(`CCE Web Server running at http://${this.config.host}:${this.config.port}`);
        resolve({
          url: `http://${this.config.host}:${this.config.port}`,
          port: this.config.port
        });
      });
    });
  }
  
  async stop() {
    return new Promise((resolve) => {
      this.wss.close();
      this.server.close(() => {
        console.log('CCE Web Server stopped');
        resolve();
      });
    });
  }
}

// Export for use as module
module.exports = CCEWebServer;

// Run if called directly
if (require.main === module) {
  const configPath = path.join(process.env.HOME, '.cce-universal/web/config.json');
  let config = {};
  
  try {
    config = require(configPath);
  } catch (error) {
    console.log('Using default configuration');
  }
  
  const server = new CCEWebServer(config.server);
  
  server.start().then(({ url }) => {
    console.log(`Dashboard available at: ${url}`);
    
    // Open browser if configured
    if (config.server?.autoOpen) {
      const opener = process.platform === 'darwin' ? 'open' :
                     process.platform === 'win32' ? 'start' :
                     'xdg-open';
      exec(`${opener} ${url}`);
    }
  });
  
  // Graceful shutdown
  process.on('SIGINT', async () => {
    console.log('\nShutting down...');
    await server.stop();
    process.exit(0);
  });
}
EOF
    
    # Package.json for web module
    cat > ~/.cce-universal/web/package.json << 'EOF'
{
  "name": "@cce/web",
  "version": "1.0.0",
  "description": "CCE Web Interface and API",
  "main": "server/index.js",
  "scripts": {
    "start": "node server/index.js",
    "dev": "nodemon server/index.js",
    "build": "echo 'Dashboard build will be implemented when UI is created'",
    "install-deps": "npm install"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "ws": "^8.14.2",
    "sqlite3": "^5.1.6",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
    
    # Basic HTML placeholder for dashboard
    cat > ~/.cce-universal/web/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CCE Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; opacity: 0.9; margin-bottom: 2rem; }
        .status { 
            padding: 1rem 2rem;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            margin-top: 1rem;
        }
        .badge {
            display: inline-block;
            padding: 0.3rem 0.8rem;
            background: #10b981;
            border-radius: 20px;
            font-size: 0.9rem;
            margin: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 CCE Dashboard</h1>
        <p>Web Interface Ready for Development</p>
        <div class="status">
            <div class="badge">✓ Server Running</div>
            <div class="badge">✓ API Ready</div>
            <div class="badge">✓ WebSocket Active</div>
        </div>
        <p style="margin-top: 2rem; font-size: 1rem; opacity: 0.7;">
            Dashboard UI will be implemented here.<br>
            Use the API at <code>/api/v1</code>
        </p>
    </div>
    
    <script>
        // WebSocket connection test
        const ws = new WebSocket(`ws://${window.location.host}`);
        
        ws.onopen = () => {
            console.log('WebSocket connected');
        };
        
        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            console.log('WebSocket message:', data);
        };
        
        // API test
        fetch('/api/v1/health')
            .then(res => res.json())
            .then(data => console.log('API Health:', data));
    </script>
</body>
</html>
EOF
    
    # CLI command for web management
    cat > ~/.cce-universal/bin/cce-web << 'EOF'
#!/usr/bin/env bash
# CCE Web Interface Manager

CCE_WEB_DIR=~/.cce-universal/web
PID_FILE="$CCE_WEB_DIR/server.pid"
LOG_FILE="$CCE_WEB_DIR/server.log"

# Detect if we're in WSL
is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

# Find free port
find_free_port() {
    local port=3456
    while lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; do
        port=$((port + 1))
    done
    echo $port
}

start_server() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "❌ Server already running (PID: $PID)"
            echo "   URL: http://localhost:$(get_port)"
            return 1
        fi
    fi
    
    # Check if dependencies are installed
    if [ ! -d "$CCE_WEB_DIR/node_modules" ]; then
        echo "📦 Installing dependencies..."
        cd "$CCE_WEB_DIR" && npm install --silent
    fi
    
    # Find free port
    PORT=$(find_free_port)
    export CCE_WEB_PORT=$PORT
    
    echo "🚀 Starting CCE Web Server..."
    cd "$CCE_WEB_DIR"
    nohup node server/index.js > "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    
    # Wait for server to start
    sleep 2
    
    if ps -p $PID > /dev/null; then
        URL="http://localhost:$PORT"
        echo "✅ Server started successfully"
        echo "   PID: $PID"
        echo "   URL: $URL"
        echo "   Logs: $LOG_FILE"
        
        # Open browser if in WSL
        if is_wsl && command -v cmd.exe >/dev/null; then
            echo "🌐 Opening browser..."
            cmd.exe /c start "$URL" 2>/dev/null
        elif command -v xdg-open >/dev/null; then
            xdg-open "$URL" 2>/dev/null
        fi
    else
        echo "❌ Failed to start server"
        echo "   Check logs: $LOG_FILE"
        rm -f "$PID_FILE"
        return 1
    fi
}

stop_server() {
    if [ ! -f "$PID_FILE" ]; then
        echo "❌ Server not running"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        echo "🛑 Stopping server (PID: $PID)..."
        kill $PID
        rm -f "$PID_FILE"
        echo "✅ Server stopped"
    else
        echo "⚠️  Server not running, cleaning up..."
        rm -f "$PID_FILE"
    fi
}

restart_server() {
    stop_server
    sleep 1
    start_server
}

server_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            PORT=$(get_port)
            echo "✅ Server is running"
            echo "   PID: $PID"
            echo "   URL: http://localhost:$PORT"
            echo "   Uptime: $(ps -o etime= -p $PID | xargs)"
            
            # Check API health
            if curl -s "http://localhost:$PORT/api/v1/health" > /dev/null; then
                echo "   API: ✓ Healthy"
            else
                echo "   API: ✗ Not responding"
            fi
        else
            echo "❌ Server not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ Server not running"
    fi
}

get_port() {
    # Try to get port from running process
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        PORT=$(lsof -p $PID -P -n 2>/dev/null | grep LISTEN | awk '{print $9}' | cut -d: -f2 | head -1)
        echo ${PORT:-3456}
    else
        echo "3456"
    fi
}

view_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        echo "❌ No log file found"
    fi
}

develop_mode() {
    echo "🔧 Starting in development mode..."
    cd "$CCE_WEB_DIR"
    
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing dependencies..."
        npm install
    fi
    
    # Install nodemon if not present
    if ! command -v nodemon >/dev/null 2>&1; then
        echo "📦 Installing nodemon..."
        npm install -g nodemon
    fi
    
    echo "👀 Watching for changes..."
    export CCE_WEB_PORT=$(find_free_port)
    nodemon server/index.js
}

case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        server_status
        ;;
    logs)
        view_logs
        ;;
    dev)
        develop_mode
        ;;
    *)
        echo "CCE Web Interface Manager"
        echo "========================"
        echo ""
        echo "Usage: cce-web {start|stop|restart|status|logs|dev}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the web server"
        echo "  stop     - Stop the web server"
        echo "  restart  - Restart the web server"
        echo "  status   - Check server status"
        echo "  logs     - View server logs"
        echo "  dev      - Start in development mode with auto-reload"
        echo ""
        echo "API Endpoints:"
        echo "  http://localhost:3456/api/v1/health  - Health check"
        echo "  http://localhost:3456/api/v1/system  - System info"
        echo "  http://localhost:3456/api/v1/projects - List projects"
        echo "  http://localhost:3456/api/v1/config  - Get configuration"
        ;;
esac
EOF
    chmod +x ~/.cce-universal/bin/cce-web
    
    # API client helper
    cat > ~/.cce-universal/scripts/api-client.sh << 'EOF'
#!/usr/bin/env bash
# CCE API Client Helper

API_BASE="http://localhost:3456/api/v1"

# Get current port if server is running
if [ -f ~/.cce-universal/web/server.pid ]; then
    PORT=$(lsof -p $(cat ~/.cce-universal/web/server.pid) -P -n 2>/dev/null | grep LISTEN | awk '{print $9}' | cut -d: -f2 | head -1)
    API_BASE="http://localhost:${PORT:-3456}/api/v1"
fi

call_api() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="$3"
    
    if [ "$method" = "GET" ]; then
        curl -s "$API_BASE/$endpoint" | jq '.' 2>/dev/null || curl -s "$API_BASE/$endpoint"
    else
        curl -s -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_BASE/$endpoint" | jq '.' 2>/dev/null || curl -s -X "$method" -H "Content-Type: application/json" -d "$data" "$API_BASE/$endpoint"
    fi
}

# Convenience functions
cce_api_health() {
    call_api "health"
}

cce_api_system() {
    call_api "system"
}

cce_api_projects() {
    call_api "projects"
}

cce_api_config() {
    call_api "config"
}

cce_api_execute() {
    local command="$1"
    shift
    local args="$*"
    call_api "execute" "POST" "{\"command\":\"$command\",\"args\":[\"$args\"]}"
}

# Export functions if sourced
export -f call_api cce_api_health cce_api_system cce_api_projects cce_api_config cce_api_execute
EOF
    chmod +x ~/.cce-universal/scripts/api-client.sh
    
    # Environment adapter
    cat > ~/.cce-universal/adapters/env-adapter.sh << 'EOF'
#!/bin/bash
# Environment-specific adaptations

get_home_dir() {
    echo "$HOME"
}

get_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/package.json" ] || [ -f "$dir/.git/config" ] || [ -f "$dir/.claude/settings.json" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

normalize_path() {
    local path="$1"
    # Convert Windows paths if in WSL
    if [[ "$path" =~ ^[A-Za-z]: ]]; then
        if command -v wslpath &> /dev/null; then
            wslpath -u "$path"
        else
            echo "$path"
        fi
    else
        echo "$path"
    fi
}

detect_line_ending() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "auto"  # Let git handle it
    else
        echo "lf"
    fi
}
EOF
    chmod +x ~/.cce-universal/adapters/env-adapter.sh
    
    # Universal CLAUDE.md
    cat > ~/.claude/CLAUDE.md << 'EOF'
# CCE Universal Context

## System Information
- Environment: Multi-Platform (WSL/VM/Native Linux)
- Architecture: Cross-Architecture (AMD64/ARM64)
- Mode: Universal Configuration

## Development Philosophy

### Portability First
- Write code that works everywhere
- Avoid platform-specific dependencies
- Use relative paths, not absolute
- Test on multiple environments

### Code Standards
- Clean, readable, maintainable code
- Comprehensive error handling
- Meaningful variable names
- Document complex logic

### Git Workflow
- Conventional commits (feat:, fix:, docs:)
- Branch protection for main
- PR reviews when possible
- Clean commit history

### Security
- Environment variables for secrets
- Never commit sensitive data
- Input validation always
- Principle of least privilege

## Cross-Platform Considerations
- Use `#!/usr/bin/env bash` not `#!/bin/bash`
- Handle both LF and CRLF line endings
- Path separators: always forward slash
- Case sensitivity: assume case-sensitive

## Available Tools
- `/help` - Show available commands
- `/sync` - Sync configuration across environments
- `/analyze` - Analyze project structure
- `/test` - Run tests appropriately

## Environment Variables
- `CCE_ENV` - Current environment type (wsl/vm/native)
- `CCE_ARCH` - Current architecture (amd64/arm64)
- `CCE_HOME` - CCE installation directory
EOF
    
    # Universal settings.json
    cat > ~/.claude/settings.json << 'EOF'
{
  "theme": "dark",
  "autoUpdaterStatus": "enabled",
  "defaultModel": "claude-3-7-sonnet-20250219",
  "telemetry": false,
  "verbose": false,
  "hooks": [
    {
      "matcher": "Edit",
      "hooks": [
        {
          "type": "command",
          "command": "~/.cce-universal/scripts/universal-format.sh \"$CLAUDE_FILE_PATHS\""
        }
      ]
    }
  ],
  "defaultPermissions": {
    "Bash": "allow",
    "Edit": "allow",
    "Write": "allow",
    "Read": "allow"
  },
  "environmentVariables": {
    "CCE_ENV": "${CCE_ENV}",
    "CCE_ARCH": "${CCE_ARCH}"
  }
}
EOF
    
    # Universal formatter
    cat > ~/.cce-universal/scripts/universal-format.sh << 'EOF'
#!/usr/bin/env bash
# Universal formatter - works across all platforms

FILE="$1"
[ ! -f "$FILE" ] && exit 0

# Source environment adapter
source ~/.cce-universal/adapters/env-adapter.sh

# Normalize path for cross-platform
FILE=$(normalize_path "$FILE")

# Get file extension
EXT="${FILE##*.}"
FILENAME=$(basename "$FILE")

# Detect and apply appropriate formatter
format_javascript() {
    if command -v prettier &> /dev/null; then
        prettier --write "$FILE" 2>/dev/null
    elif command -v npx &> /dev/null; then
        npx -y prettier --write "$FILE" 2>/dev/null
    fi
}

format_python() {
    if command -v black &> /dev/null; then
        black "$FILE" 2>/dev/null
    elif command -v autopep8 &> /dev/null; then
        autopep8 --in-place "$FILE" 2>/dev/null
    elif command -v ruff &> /dev/null; then
        ruff format "$FILE" 2>/dev/null
    fi
}

format_rust() {
    if command -v rustfmt &> /dev/null; then
        rustfmt "$FILE" 2>/dev/null
    fi
}

format_go() {
    if command -v gofmt &> /dev/null; then
        gofmt -w "$FILE" 2>/dev/null
    elif command -v goimports &> /dev/null; then
        goimports -w "$FILE" 2>/dev/null
    fi
}

# Apply formatting based on extension
case "$EXT" in
    js|jsx|ts|tsx|json|md|mdx|yaml|yml)
        format_javascript ;;
    py|pyw)
        format_python ;;
    rs)
        format_rust ;;
    go)
        format_go ;;
    sh|bash)
        if command -v shfmt &> /dev/null; then
            shfmt -w "$FILE" 2>/dev/null
        fi ;;
esac

# TypeScript type checking
if [[ "$EXT" =~ ^(ts|tsx)$ ]]; then
    if [ -f "tsconfig.json" ] && command -v npx &> /dev/null; then
        npx -y tsc --noEmit --skipLibCheck "$FILE" 2>/dev/null || true
    fi
fi
EOF
    chmod +x ~/.cce-universal/scripts/universal-format.sh
    
    # Project initializer
    cat > ~/.cce-universal/scripts/init-project.sh << 'EOF'
#!/usr/bin/env bash
# Universal project initializer

source ~/.cce-universal/adapters/env-adapter.sh

PROJECT_DIR="${1:-$(get_project_root)}"
cd "$PROJECT_DIR" || exit 1

echo "🚀 Initializing CCE Universal in $(basename "$PROJECT_DIR")"

# Create .claude directory
mkdir -p .claude/{commands,hooks,config}

# Detect project type
detect_project_type() {
    local type="generic"
    
    # Node/JavaScript/TypeScript
    if [ -f "package.json" ]; then
        type="node"
        if grep -q '"react"' package.json 2>/dev/null; then
            type="react"
        elif grep -q '"vue"' package.json 2>/dev/null; then
            type="vue"
        elif grep -q '"@angular/core"' package.json 2>/dev/null; then
            type="angular"
        elif grep -q '"next"' package.json 2>/dev/null; then
            type="nextjs"
        fi
    # Python
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
        type="python"
        if [ -f "pyproject.toml" ] && grep -q "django" pyproject.toml 2>/dev/null; then
            type="django"
        elif [ -f "requirements.txt" ] && grep -q "flask" requirements.txt 2>/dev/null; then
            type="flask"
        fi
    # Rust
    elif [ -f "Cargo.toml" ]; then
        type="rust"
    # Go
    elif [ -f "go.mod" ]; then
        type="go"
    # Ruby
    elif [ -f "Gemfile" ]; then
        type="ruby"
    # Java
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        type="java"
    fi
    
    echo "$type"
}

PROJECT_TYPE=$(detect_project_type)
echo "📦 Detected project type: $PROJECT_TYPE"

# Get environment info
ENV_INFO=$(~/.cce-universal/scripts/detect-env.sh 2>/dev/null || echo "unknown:unknown")
ENV_TYPE="${ENV_INFO%%:*}"
ARCH="${ENV_INFO##*:}"

# Create project CLAUDE.md
cat > .claude/CLAUDE.md << EOF
# Project: $(basename "$PROJECT_DIR")
# Type: $PROJECT_TYPE
# Environment: $ENV_TYPE ($ARCH)
# Initialized: $(date -u +"%Y-%m-%d %H:%M UTC")

## Project Context
@include ~/.claude/CLAUDE.md

## Project Configuration
- Type: $PROJECT_TYPE
- Path: $PROJECT_DIR
- VCS: $([ -d .git ] && echo "Git" || echo "None")

## Project Specific Information
[TODO: Add project description]

### Architecture
[TODO: Describe system architecture]

### Key Features
[TODO: List main features]

### Dependencies
$(if [ -f "package.json" ]; then
    echo "See package.json for dependencies"
elif [ -f "requirements.txt" ]; then
    echo "See requirements.txt for dependencies"
elif [ -f "go.mod" ]; then
    echo "See go.mod for dependencies"
else
    echo "[TODO: List key dependencies]"
fi)

### Development Workflow
[TODO: Describe development process]

### Testing Strategy
[TODO: Describe testing approach]

## Important Notes
- This project uses CCE Universal for cross-platform compatibility
- Configuration syncs across WSL, VMs, and native Linux
- Environment: $ENV_TYPE, Architecture: $ARCH
EOF

# Create project settings
cat > .claude/settings.json << EOF
{
  "extends": "~/.claude/settings.json",
  "projectType": "$PROJECT_TYPE",
  "projectName": "$(basename "$PROJECT_DIR")",
  "environment": {
    "type": "$ENV_TYPE",
    "arch": "$ARCH"
  },
  "sync": {
    "enabled": true,
    "exclude": ["node_modules", ".git", "dist", "build", "target"]
  }
}
EOF

# Add project-specific commands
case "$PROJECT_TYPE" in
    node|react|vue|angular|nextjs)
        cat > .claude/commands/dev.md << 'CMDEOF'
Start development server
Usage: /dev
Execute: npm run dev || npm start
CMDEOF
        
        cat > .claude/commands/test.md << 'CMDEOF'
Run tests
Usage: /test [pattern]
Execute: npm test $ARGUMENTS
CMDEOF
        
        cat > .claude/commands/build.md << 'CMDEOF'
Build for production
Usage: /build
Execute: npm run build
CMDEOF
        ;;
    
    python|django|flask)
        cat > .claude/commands/test.md << 'CMDEOF'
Run Python tests
Usage: /test [pattern]
Execute: pytest $ARGUMENTS || python -m pytest $ARGUMENTS
CMDEOF
        
        if [ "$PROJECT_TYPE" = "django" ]; then
            cat > .claude/commands/runserver.md << 'CMDEOF'
Start Django development server
Usage: /runserver [port]
Execute: python manage.py runserver ${ARGUMENTS:-8000}
CMDEOF
        fi
        ;;
    
    rust)
        cat > .claude/commands/build.md << 'CMDEOF'
Build Rust project
Usage: /build [--release]
Execute: cargo build $ARGUMENTS
CMDEOF
        
        cat > .claude/commands/test.md << 'CMDEOF'
Run Rust tests
Usage: /test
Execute: cargo test
CMDEOF
        ;;
    
    go)
        cat > .claude/commands/run.md << 'CMDEOF'
Run Go application
Usage: /run
Execute: go run .
CMDEOF
        
        cat > .claude/commands/test.md << 'CMDEOF'
Run Go tests
Usage: /test
Execute: go test ./...
CMDEOF
        ;;
esac

# Create .gitignore if not exists
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'GITEOF'
# CCE
.claude/settings.local.json
.claude/.cache/
.cce-sync/

# Environment
.env
.env.local
*.env

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db
GITEOF
fi

echo "✅ CCE Universal initialized for $PROJECT_TYPE project!"
echo ""
echo "Next steps:"
echo "1. Edit .claude/CLAUDE.md with project details"
echo "2. Run 'cce' or 'claude' to start"
echo "3. Use 'cce-sync' to sync across environments"
EOF
    chmod +x ~/.cce-universal/scripts/init-project.sh
    
    # Environment detector script
    cat > ~/.cce-universal/scripts/detect-env.sh << 'EOF'
#!/usr/bin/env bash
# Detect current environment

ENV_TYPE="unknown"
ARCH=$(uname -m)

# Normalize architecture
case "$ARCH" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
esac

# Detect environment type
if grep -qi microsoft /proc/version 2>/dev/null; then
    ENV_TYPE="wsl"
elif [ -f /.dockerenv ]; then
    ENV_TYPE="docker"
elif [ -f /sys/class/dmi/id/product_name ] 2>/dev/null; then
    PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
    if [[ "$PRODUCT" == *"Virtual"* ]] || [[ "$PRODUCT" == *"VM"* ]]; then
        ENV_TYPE="vm"
    else
        ENV_TYPE="native"
    fi
else
    ENV_TYPE="native"
fi

echo "$ENV_TYPE:$ARCH"
EOF
    chmod +x ~/.cce-universal/scripts/detect-env.sh
    
    # Sync utility
    cat > ~/.cce-universal/scripts/sync.sh << 'EOF'
#!/usr/bin/env bash
# Sync CCE configuration across environments

SYNC_REPO="${CCE_SYNC_REPO:-}"
SYNC_BRANCH="${CCE_SYNC_BRANCH:-main}"

sync_push() {
    if [ -z "$SYNC_REPO" ]; then
        echo "❌ No sync repository configured"
        echo "Set CCE_SYNC_REPO environment variable"
        return 1
    fi
    
    echo "📤 Pushing CCE configuration..."
    
    # Create temporary sync directory
    SYNC_DIR=$(mktemp -d)
    cd "$SYNC_DIR" || exit 1
    
    # Initialize git repo
    git init
    git remote add origin "$SYNC_REPO"
    
    # Copy configuration files
    cp -r ~/.claude .claude
    cp -r ~/.cce-universal .cce-universal
    
    # Create sync manifest
    cat > sync-manifest.json << MANIFEST
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": "$(~/.cce-universal/scripts/detect-env.sh)",
  "hostname": "$(hostname)",
  "version": "1.0.0"
}
MANIFEST
    
    # Commit and push
    git add .
    git commit -m "CCE sync from $(hostname) at $(date -u +"%Y-%m-%d %H:%M UTC")"
    git push -u origin "$SYNC_BRANCH" --force
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$SYNC_DIR"
    
    echo "✅ Configuration synced"
}

sync_pull() {
    if [ -z "$SYNC_REPO" ]; then
        echo "❌ No sync repository configured"
        return 1
    fi
    
    echo "📥 Pulling CCE configuration..."
    
    # Backup current config
    BACKUP_DIR=~/.cce-backup-$(date +%Y%m%d-%H%M%S)
    mkdir -p "$BACKUP_DIR"
    [ -d ~/.claude ] && cp -r ~/.claude "$BACKUP_DIR/"
    [ -d ~/.cce-universal ] && cp -r ~/.cce-universal "$BACKUP_DIR/"
    
    # Pull configuration
    SYNC_DIR=$(mktemp -d)
    cd "$SYNC_DIR" || exit 1
    
    git clone "$SYNC_REPO" . --branch "$SYNC_BRANCH" --depth 1
    
    # Apply configuration
    [ -d .claude ] && cp -r .claude ~/
    [ -d .cce-universal ] && cp -r .cce-universal ~/
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$SYNC_DIR"
    
    echo "✅ Configuration pulled"
    echo "📁 Backup saved to: $BACKUP_DIR"
}

case "${1:-}" in
    push) sync_push ;;
    pull) sync_pull ;;
    *)
        echo "Usage: $0 {push|pull}"
        echo ""
        echo "Configure with:"
        echo "  export CCE_SYNC_REPO='git@github.com:username/cce-config.git'"
        echo "  export CCE_SYNC_BRANCH='main'"
        ;;
esac
EOF
    chmod +x ~/.cce-universal/scripts/sync.sh
    
    # Bash aliases and functions
    cat > ~/.cce-universal/aliases.sh << 'EOF'
#!/usr/bin/env bash
# CCE Universal aliases and functions

# Environment detection
export CCE_ENV=$(~/.cce-universal/scripts/detect-env.sh 2>/dev/null | cut -d: -f1)
export CCE_ARCH=$(~/.cce-universal/scripts/detect-env.sh 2>/dev/null | cut -d: -f2)
export CCE_HOME=~/.cce-universal
export PATH="$PATH:$CCE_HOME/bin"

# Quick Claude commands
alias cc='claude'
alias ccp='claude -p'
alias ccr='claude --resume'
alias ccc='claude --continue'

# Web interface commands
alias cce-web='~/.cce-universal/bin/cce-web'
alias cce-api='source ~/.cce-universal/scripts/api-client.sh'

# Initialize project
cce-init() {
    ~/.cce-universal/scripts/init-project.sh "$@"
}

# Sync configuration
cce-sync() {
    ~/.cce-universal/scripts/sync.sh "$@"
}

# Quick analysis
cce-analyze() {
    claude -p "Analyze this project structure, dependencies, and architecture. Provide insights about code organization, potential improvements, and best practices applicable to this codebase."
}

# Generate tests
cce-test() {
    local file="${1}"
    if [ -z "$file" ]; then
        echo "Usage: cce-test <file>"
        return 1
    fi
    claude -p "Generate comprehensive tests for $file using the appropriate testing framework for this project. Include edge cases and error handling."
}

# Code review
cce-review() {
    local files="${1:-$(git diff --name-only HEAD 2>/dev/null || echo "all files")}"
    claude -p "Review the following files for code quality, bugs, security issues, and improvements: $files"
}

# Fix error
cce-fix() {
    if [ -z "$1" ]; then
        echo "Usage: cce-fix <error-message>"
        return 1
    fi
    claude -p "I'm getting this error: $* 
Please help me understand and fix it."
}

# Dashboard shortcut
cce-dashboard() {
    ~/.cce-universal/bin/cce-web start
    echo ""
    echo "📊 Dashboard starting..."
    echo "   Use 'cce-web status' to check"
    echo "   Use 'cce-web stop' to shutdown"
}

# Environment info
cce-info() {
    echo "CCE Universal Status"
    echo "===================="
    echo "Environment: $CCE_ENV"
    echo "Architecture: $CCE_ARCH"
    echo "CCE Home: $CCE_HOME"
    echo "Claude: $(command -v claude &>/dev/null && echo '✓ installed' || echo '✗ not found')"
    echo "Node: $(node -v 2>/dev/null || echo 'not found')"
    echo "NPM: $(npm -v 2>/dev/null || echo 'not found')"
    
    # Check web server
    if [ -f ~/.cce-universal/web/server.pid ]; then
        PID=$(cat ~/.cce-universal/web/server.pid)
        if ps -p $PID > /dev/null 2>&1; then
            echo "Web Server: ✓ running (PID: $PID)"
        else
            echo "Web Server: ✗ not running"
        fi
    else
        echo "Web Server: ✗ not running"
    fi
    
    if [ -d .claude ]; then
        echo ""
        echo "Project Status"
        echo "=============="
        if [ -f .claude/settings.json ]; then
            echo "Type: $(grep projectType .claude/settings.json | cut -d'"' -f4)"
            echo "Name: $(grep projectName .claude/settings.json | cut -d'"' -f4)"
        fi
        echo "CCE: ✓ initialized"
    else
        echo ""
        echo "Project: not initialized (run cce-init)"
    fi
    
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo ""
        echo "API Key: ✓ configured"
    else
        echo ""
        echo "API Key: ✗ not configured"
        echo "Run: export ANTHROPIC_API_KEY='sk-ant-...'"
    fi
}

# Quick help
cce-help() {
    cat << 'HELP'
CCE Universal Commands
======================
Core Commands:
  cce-init        Initialize CCE in current project
  cce-sync        Sync configuration across environments
  cce-analyze     Analyze project structure
  cce-test        Generate tests for a file
  cce-review      Review code changes
  cce-fix         Get help with errors
  cce-info        Show CCE status
  cce-help        Show this help

Web Interface:
  cce-dashboard   Start web dashboard
  cce-web start   Start web server
  cce-web stop    Stop web server
  cce-web status  Check server status
  cce-web dev     Development mode with auto-reload
  cce-api         Load API client functions

Claude Commands:
  cc              Start Claude interactive
  ccp "query"     Claude print mode (quick questions)
  ccr             Resume last session
  ccc             Continue conversation

API Endpoints (when server running):
  http://localhost:3456/              Dashboard UI
  http://localhost:3456/api/v1/health System health
  http://localhost:3456/api/v1/system System info
  http://localhost:3456/api/v1/projects List projects
  http://localhost:3456/api/v1/config Get configuration

Environment Variables:
  CCE_ENV         Current environment (wsl/vm/native)
  CCE_ARCH        Current architecture (amd64/arm64)
  CCE_SYNC_REPO   Git repo for config sync
  CCE_WEB_PORT    Web server port (default: 3456)
  CCE_WEB_HOST    Web server host (default: localhost)
HELP
}

# Export functions
export -f cce-init cce-sync cce-analyze cce-test cce-review cce-fix cce-info cce-help cce-dashboard
EOF
    
    # Add to bashrc if not present
    if ! grep -q "cce-universal/aliases.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# CCE Universal" >> ~/.bashrc
        echo "[ -f ~/.cce-universal/aliases.sh ] && source ~/.cce-universal/aliases.sh" >> ~/.bashrc
    fi
    
    # ============================================================================
    # Final Setup
    # ============================================================================
    
    # Set permissions
    chmod +x ~/.cce-universal/scripts/*.sh
    chmod +x ~/.cce-universal/adapters/*.sh
    
    # Create API key helper
    cat > ~/.claude/api-key-helper.sh << 'EOF'
#!/usr/bin/env bash
# Universal API key helper

# Try environment variable first
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "$ANTHROPIC_API_KEY"
    exit 0
fi

# Try various config files
for config_file in ~/.env ~/.anthropic_key ~/.config/anthropic/key; do
    if [ -f "$config_file" ]; then
        # Source .env files
        if [[ "$config_file" == *.env ]]; then
            source "$config_file" 2>/dev/null
            [ -n "$ANTHROPIC_API_KEY" ] && echo "$ANTHROPIC_API_KEY" && exit 0
        else
            # Read key files
            cat "$config_file" 2>/dev/null && exit 0
        fi
    fi
done

# Error if no key found
echo "ERROR: ANTHROPIC_API_KEY not found" >&2
echo "Set with: export ANTHROPIC_API_KEY='sk-ant-...'" >&2
exit 1
EOF
    chmod +x ~/.claude/api-key-helper.sh
    
    # Update settings to use API key helper
    if command -v jq &> /dev/null; then
        jq '.apiKeyHelper = "~/.claude/api-key-helper.sh"' ~/.claude/settings.json > ~/.claude/settings.json.tmp
        mv ~/.claude/settings.json.tmp ~/.claude/settings.json
    fi
    
    # ============================================================================
    # Completion Message
    # ============================================================================
    
    echo ""
    log_success "${BOLD}CCE Universal installation complete!${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Quick Start:${NC}"
    echo -e "  1. ${YELLOW}source ~/.bashrc${NC}"
    echo -e "  2. ${YELLOW}export ANTHROPIC_API_KEY='sk-ant-...'${NC}"
    echo -e "  3. ${YELLOW}cd your-project && cce-init${NC}"
    echo -e "  4. ${YELLOW}cc${NC} (start Claude)"
    echo ""
    echo -e "${BOLD}Web Interface:${NC}"
    echo -e "  • ${GREEN}cce-dashboard${NC} - Launch web dashboard"
    echo -e "  • ${GREEN}cce-web start${NC} - Start server manually"
    echo -e "  • ${GREEN}cce-web dev${NC} - Development mode"
    echo ""
    echo -e "${BOLD}Key Features:${NC}"
    echo -e "  • Works on: WSL, OCI VMs, Native Linux"
    echo -e "  • Supports: AMD64 and ARM64"
    echo -e "  • Auto-detects: Project type and environment"
    echo -e "  • Syncs: Configuration across machines"
    echo -e "  • Web UI: Dashboard and API ready"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo -e "  ${GREEN}cce-help${NC} - Show all commands"
    echo -e "  ${GREEN}cce-info${NC} - Check status"
    echo -e "  ${GREEN}cce-sync${NC} - Sync across environments"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Environment-specific notes
    case "$ENV_TYPE" in
        wsl)
            log_info "WSL detected - Line endings set to 'auto'"
            log_info "Access Windows files: /mnt/c/..."
            ;;
        vm)
            log_info "VM detected - Optimized for cloud environment"
            log_info "Consider setting up CCE_SYNC_REPO for multi-VM sync"
            ;;
    esac
}

# Run main installation
main "$@"