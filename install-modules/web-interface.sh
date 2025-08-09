#!/bin/bash
# CCE Web Interface Module
# Handles web server, API, and dashboard setup

setup_web_configuration() {
    log_step "Setting up web interface configuration..."
    
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
    
    log_success "Web configuration created"
}

setup_web_server() {
    log_step "Installing web server..."
    
    # Web server base (simplified version focusing on existing dashboard integration)
    cat > ~/.cce-universal/web/server/index.js << 'EOF'
#!/usr/bin/env node
/**
 * CCE Web Server - Simplified Bootstrap
 * This server points to the existing full-featured dashboard
 */

const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.CCE_WEB_PORT || 3456;

// Check if full dashboard exists
const dashboardPath = path.join(process.env.HOME, '.cce-universal/web/dashboard/build');
const hasFullDashboard = fs.existsSync(dashboardPath);

if (hasFullDashboard) {
    // Serve full dashboard if available
    app.use(express.static(dashboardPath));
    
    app.get('*', (req, res) => {
        res.sendFile(path.join(dashboardPath, 'index.html'));
    });
    
    console.log(`🚀 CCE Full Dashboard running at http://localhost:${PORT}`);
} else {
    // Serve basic placeholder
    app.get('/', (req, res) => {
        res.send(`
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
        <p>Web Interface Ready</p>
        <div class="status">
            <div class="badge">✓ Server Running</div>
            <div class="badge">✓ Core Installed</div>
        </div>
        <p style="margin-top: 2rem; font-size: 1rem; opacity: 0.7;">
            Full dashboard available when web components are built.<br>
            Run <code>cce-web dev</code> for development mode.
        </p>
    </div>
</body>
</html>
        `);
    });
    
    console.log(`🚀 CCE Basic Dashboard running at http://localhost:${PORT}`);
    console.log('💡 Install full dashboard with: cce-install --with-web');
}

app.listen(PORT, () => {
    console.log(`✅ Web server ready at http://localhost:${PORT}`);
});
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
    "dev": "nodemon server/index.js || node server/index.js",
    "install-deps": "npm install"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
    
    log_success "Web server installed"
}

setup_web_management() {
    log_step "Installing web management tools..."
    
    # CLI command for web management (simplified version)
    cat > ~/.cce-universal/bin/cce-web << 'EOF'
#!/usr/bin/env bash
# CCE Web Interface Manager

CCE_WEB_DIR=~/.cce-universal/web
PID_FILE="$CCE_WEB_DIR/server.pid"
LOG_FILE="$CCE_WEB_DIR/server.log"

# Check if full dashboard server exists
FULL_SERVER="$HOME/.cce-universal/web/server/index.js"

if [ -f "$FULL_SERVER" ] && grep -q "CCE Web Server" "$FULL_SERVER" 2>/dev/null; then
    # Use full dashboard server
    cd "$HOME/.cce-universal/web" && CCE_HOME="$HOME/.cce-universal" npm start
else
    # Use basic server
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
                return 1
            fi
        fi
        
        # Check if dependencies are installed
        if [ ! -d "$CCE_WEB_DIR/node_modules" ]; then
            echo "📦 Installing dependencies..."
            cd "$CCE_WEB_DIR" && npm install --silent
        fi
        
        # Find free port and start
        PORT=$(find_free_port)
        export CCE_WEB_PORT=$PORT
        
        echo "🚀 Starting CCE Web Server..."
        cd "$CCE_WEB_DIR"
        nohup node server/index.js > "$LOG_FILE" 2>&1 &
        PID=$!
        echo $PID > "$PID_FILE"
        
        sleep 2
        if ps -p $PID > /dev/null; then
            URL="http://localhost:$PORT"
            echo "✅ Server started successfully"
            echo "   URL: $URL"
            
            # Open browser if possible
            if command -v xdg-open >/dev/null; then
                xdg-open "$URL" 2>/dev/null &
            fi
        else
            echo "❌ Failed to start server"
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

    case "$1" in
        start) start_server ;;
        stop) stop_server ;;
        restart) stop_server; sleep 1; start_server ;;
        *)
            echo "Usage: cce-web {start|stop|restart}"
            echo "Web Interface Manager"
            ;;
    esac
fi
EOF
    chmod +x ~/.cce-universal/bin/cce-web
    
    log_success "Web management tools installed"
}

# Main function for web interface setup
setup_web_interface() {
    setup_web_configuration
    setup_web_server
    setup_web_management
}