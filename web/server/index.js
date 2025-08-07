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
