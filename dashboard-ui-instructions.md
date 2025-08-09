# CCE Dashboard UI - Complete Implementation Instructions

## Context
You are implementing a modern web dashboard for CCE (Claude Code Ecosystem). The dashboard will provide real-time monitoring, system status, project management, and agent execution logs. An Express.js API server structure already exists at `~/.cce-universal/web/`.

## Architecture Overview
- **Backend**: Existing Express.js API (enhance it)
- **Frontend**: New React app with modern UI
- **Styling**: Tailwind CSS + shadcn/ui components
- **Real-time**: WebSocket for live updates
- **State**: React Query for data fetching

## Task 1: Enhance Express.js API Backend

Update `~/.cce-universal/web/server/index.js`:

```javascript
const express = require('express');
const cors = require('cors');
const WebSocket = require('ws');
const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const util = require('util');

const execPromise = util.promisify(exec);
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../dashboard/build')));

// WebSocket server
const wss = new WebSocket.Server({ noServer: true });

// Broadcast to all connected clients
const broadcast = (data) => {
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
};

// API Routes

// System Status
app.get('/api/v1/status', async (req, res) => {
  try {
    const status = {
      cce: {
        version: '2.0.0',
        home: process.env.CCE_HOME || path.join(process.env.HOME, '.cce-universal'),
        environment: process.env.CCE_ENV || 'unknown',
        architecture: process.env.CCE_ARCH || process.arch
      },
      node: process.version,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      timestamp: new Date().toISOString()
    };
    
    // Check Claude CLI
    try {
      await execPromise('which claude');
      status.claude = { installed: true };
    } catch {
      status.claude = { installed: false };
    }
    
    // Check API key
    status.apiKey = {
      configured: !!process.env.ANTHROPIC_API_KEY
    };
    
    res.json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// MCP Servers Status
app.get('/api/v1/mcp/servers', async (req, res) => {
  try {
    const mcp_servers = [
      { name: 'filesystem', package: '@modelcontextprotocol/server-filesystem' },
      { name: 'github', package: '@modelcontextprotocol/server-github' },
      { name: 'postgresql', package: 'postgres-mcp-server' },
      { name: 'fetch', package: '@mokei/mcp-fetch' },
      { name: 'memory', package: '@modelcontextprotocol/server-memory' },
      { name: 'everything', package: '@modelcontextprotocol/server-everything' },
      { name: 'sequential-thinking', package: '@modelcontextprotocol/server-sequential-thinking' },
      { name: 'sentry', package: '@sentry/mcp-server' },
      { name: 'firecrawl', package: 'firecrawl-mcp' }
    ];
    
    const servers = await Promise.all(mcp_servers.map(async (server) => {
      const installed = await fs.access(
        path.join(process.env.HOME, '.cce-universal/mcp-servers/node_modules', server.package)
      ).then(() => true).catch(() => false);
      
      return {
        ...server,
        installed,
        status: installed ? 'ready' : 'not_installed'
      };
    }));
    
    res.json({ servers });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Projects List
app.get('/api/v1/projects', async (req, res) => {
  try {
    const homeDir = process.env.HOME;
    const entries = await fs.readdir(homeDir, { withFileTypes: true });
    
    const projects = await Promise.all(
      entries
        .filter(entry => entry.isDirectory() && !entry.name.startsWith('.'))
        .map(async (entry) => {
          const projectPath = path.join(homeDir, entry.name);
          const hasClaude = await fs.access(path.join(projectPath, '.claude')).then(() => true).catch(() => false);
          const hasPackageJson = await fs.access(path.join(projectPath, 'package.json')).then(() => true).catch(() => false);
          
          if (hasClaude || hasPackageJson) {
            let packageInfo = {};
            if (hasPackageJson) {
              try {
                const pkg = JSON.parse(await fs.readFile(path.join(projectPath, 'package.json'), 'utf8'));
                packageInfo = {
                  name: pkg.name,
                  version: pkg.version,
                  description: pkg.description
                };
              } catch {}
            }
            
            return {
              name: entry.name,
              path: projectPath,
              hasClaude,
              hasPackageJson,
              ...packageInfo
            };
          }
          return null;
        })
    );
    
    res.json({ projects: projects.filter(p => p !== null) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Agent Execution
app.post('/api/v1/agents/execute', async (req, res) => {
  const { agent, args } = req.body;
  
  if (!agent) {
    return res.status(400).json({ error: 'Agent name required' });
  }
  
  try {
    const command = `cce-agent ${agent} ${args || ''}`;
    
    // Send start event
    broadcast({ 
      type: 'agent_start', 
      agent, 
      args,
      timestamp: new Date().toISOString() 
    });
    
    const { stdout, stderr } = await execPromise(command, {
      env: { ...process.env },
      timeout: 300000 // 5 minutes timeout
    });
    
    const result = {
      agent,
      args,
      stdout,
      stderr,
      success: !stderr || stderr.length === 0,
      timestamp: new Date().toISOString()
    };
    
    // Send completion event
    broadcast({ 
      type: 'agent_complete',
      ...result
    });
    
    res.json(result);
  } catch (error) {
    const errorResult = {
      agent,
      args,
      error: error.message,
      success: false,
      timestamp: new Date().toISOString()
    };
    
    broadcast({ 
      type: 'agent_error',
      ...errorResult
    });
    
    res.status(500).json(errorResult);
  }
});

// Logs Endpoint
app.get('/api/v1/logs', async (req, res) => {
  try {
    const logsPath = path.join(process.env.HOME, '.cce-universal/logs');
    await fs.mkdir(logsPath, { recursive: true });
    
    const files = await fs.readdir(logsPath);
    const logs = await Promise.all(
      files
        .filter(f => f.endsWith('.log'))
        .slice(-10) // Last 10 log files
        .map(async (file) => {
          const content = await fs.readFile(path.join(logsPath, file), 'utf8');
          return {
            file,
            content: content.split('\n').slice(-100) // Last 100 lines
          };
        })
    );
    
    res.json({ logs });
  } catch (error) {
    res.json({ logs: [] });
  }
});

// Health check
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Serve React app for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../dashboard/build/index.html'));
});

// Start server
const PORT = process.env.PORT || 3456;
const server = app.listen(PORT, () => {
  console.log(`🚀 CCE Dashboard API running on http://localhost:${PORT}`);
});

// WebSocket upgrade
server.on('upgrade', (request, socket, head) => {
  wss.handleUpgrade(request, socket, head, (ws) => {
    wss.emit('connection', ws, request);
  });
});

// WebSocket connection handler
wss.on('connection', (ws) => {
  console.log('New WebSocket connection');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      // Handle incoming messages if needed
    } catch (error) {
      console.error('WebSocket message error:', error);
    }
  });
  
  // Send initial status
  ws.send(JSON.stringify({ 
    type: 'connected', 
    timestamp: new Date().toISOString() 
  }));
});
```

## Task 2: Create React Dashboard Frontend

Create the React app structure:

```bash
cd ~/.cce-universal/web
npx create-react-app dashboard --template typescript
cd dashboard
npm install axios react-query @tanstack/react-query tailwindcss @radix-ui/react-icons lucide-react clsx
npm install -D @types/react @types/react-dom
npx tailwindcss init -p
```

Update `~/.cce-universal/web/dashboard/tailwind.config.js`:

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

Update `~/.cce-universal/web/dashboard/src/index.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }
 
  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}
```

Create `~/.cce-universal/web/dashboard/src/App.tsx`:

```typescript
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import Dashboard from './components/Dashboard';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchInterval: 5000, // Refresh every 5 seconds
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="min-h-screen bg-background text-foreground">
        <Dashboard />
      </div>
    </QueryClientProvider>
  );
}

export default App;
```

Create `~/.cce-universal/web/dashboard/src/components/Dashboard.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import SystemStatus from './SystemStatus';
import MCPServers from './MCPServers';
import Projects from './Projects';
import AgentRunner from './AgentRunner';
import Logs from './Logs';
import { Home, Server, FolderOpen, Bot, FileText, Settings } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

const Dashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState('status');
  const [ws, setWs] = useState<WebSocket | null>(null);

  // WebSocket connection
  useEffect(() => {
    const websocket = new WebSocket('ws://localhost:3456');
    
    websocket.onopen = () => {
      console.log('WebSocket connected');
    };

    websocket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      console.log('WebSocket message:', data);
      // Handle real-time updates
    };

    setWs(websocket);

    return () => {
      websocket.close();
    };
  }, []);

  const tabs = [
    { id: 'status', label: 'System Status', icon: Home },
    { id: 'mcp', label: 'MCP Servers', icon: Server },
    { id: 'projects', label: 'Projects', icon: FolderOpen },
    { id: 'agents', label: 'Agents', icon: Bot },
    { id: 'logs', label: 'Logs', icon: FileText },
  ];

  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <div className="w-64 bg-card border-r">
        <div className="p-6">
          <h1 className="text-2xl font-bold">CCE Dashboard</h1>
          <p className="text-sm text-muted-foreground mt-1">v2.0.0</p>
        </div>
        
        <nav className="px-4">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg mb-1 transition-colors ${
                  activeTab === tab.id
                    ? 'bg-primary text-primary-foreground'
                    : 'hover:bg-accent'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        <div className="p-8">
          {activeTab === 'status' && <SystemStatus />}
          {activeTab === 'mcp' && <MCPServers />}
          {activeTab === 'projects' && <Projects />}
          {activeTab === 'agents' && <AgentRunner />}
          {activeTab === 'logs' && <Logs />}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
```

Create `~/.cce-universal/web/dashboard/src/components/SystemStatus.tsx`:

```typescript
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { CheckCircle, XCircle, Clock, Cpu, HardDrive } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

const SystemStatus: React.FC = () => {
  const { data: status, isLoading } = useQuery({
    queryKey: ['status'],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/status`);
      return data;
    },
  });

  if (isLoading) {
    return <div className="animate-pulse">Loading system status...</div>;
  }

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${days}d ${hours}h ${minutes}m`;
  };

  const formatMemory = (bytes: number) => {
    return `${Math.round(bytes / 1024 / 1024)} MB`;
  };

  return (
    <div>
      <h2 className="text-3xl font-bold mb-6">System Status</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* CCE Status */}
        <div className="bg-card p-6 rounded-lg border">
          <h3 className="text-lg font-semibold mb-4">CCE Environment</h3>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Version</span>
              <span className="font-mono">{status?.cce?.version}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Environment</span>
              <span className="font-mono">{status?.cce?.environment}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Architecture</span>
              <span className="font-mono">{status?.cce?.architecture}</span>
            </div>
          </div>
        </div>

        {/* Claude Status */}
        <div className="bg-card p-6 rounded-lg border">
          <h3 className="text-lg font-semibold mb-4">Claude CLI</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span>Installation</span>
              {status?.claude?.installed ? (
                <CheckCircle className="w-5 h-5 text-green-500" />
              ) : (
                <XCircle className="w-5 h-5 text-red-500" />
              )}
            </div>
            <div className="flex items-center justify-between">
              <span>API Key</span>
              {status?.apiKey?.configured ? (
                <CheckCircle className="w-5 h-5 text-green-500" />
              ) : (
                <XCircle className="w-5 h-5 text-red-500" />
              )}
            </div>
          </div>
        </div>

        {/* System Resources */}
        <div className="bg-card p-6 rounded-lg border">
          <h3 className="text-lg font-semibold mb-4">System Resources</h3>
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-muted-foreground" />
              <span className="text-sm">Uptime: {formatUptime(status?.uptime || 0)}</span>
            </div>
            <div className="flex items-center gap-2">
              <HardDrive className="w-4 h-4 text-muted-foreground" />
              <span className="text-sm">Memory: {formatMemory(status?.memory?.heapUsed || 0)}</span>
            </div>
            <div className="flex items-center gap-2">
              <Cpu className="w-4 h-4 text-muted-foreground" />
              <span className="text-sm">Node: {status?.node}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8">
        <h3 className="text-xl font-semibold mb-4">Quick Actions</h3>
        <div className="flex gap-4">
          <button className="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:opacity-90">
            Create New Project
          </button>
          <button className="px-4 py-2 bg-secondary text-secondary-foreground rounded-lg hover:opacity-90">
            Run System Check
          </button>
          <button className="px-4 py-2 bg-secondary text-secondary-foreground rounded-lg hover:opacity-90">
            Update CCE
          </button>
        </div>
      </div>
    </div>
  );
};

export default SystemStatus;
```

Create `~/.cce-universal/web/dashboard/src/components/MCPServers.tsx`:

```typescript
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { CheckCircle, XCircle, AlertCircle } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

const MCPServers: React.FC = () => {
  const { data, isLoading } = useQuery({
    queryKey: ['mcp-servers'],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/mcp/servers`);
      return data;
    },
  });

  if (isLoading) {
    return <div className="animate-pulse">Loading MCP servers...</div>;
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'ready':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'not_installed':
        return <XCircle className="w-5 h-5 text-red-500" />;
      default:
        return <AlertCircle className="w-5 h-5 text-yellow-500" />;
    }
  };

  const getServerDescription = (name: string) => {
    const descriptions: Record<string, string> = {
      filesystem: 'File system operations and code manipulation',
      github: 'GitHub API integration for repos, issues, and PRs',
      postgresql: 'PostgreSQL database queries and management',
      fetch: 'Web scraping and HTTP requests',
      memory: 'Persistent memory storage across sessions',
      everything: 'Comprehensive toolkit for various operations',
      'sequential-thinking': 'Step-by-step reasoning for complex problems',
      sentry: 'Error tracking and monitoring',
      firecrawl: 'Advanced web scraping with JavaScript support',
    };
    return descriptions[name] || 'MCP server';
  };

  return (
    <div>
      <h2 className="text-3xl font-bold mb-6">MCP Servers</h2>
      
      <div className="grid gap-4">
        {data?.servers?.map((server: any) => (
          <div key={server.name} className="bg-card p-6 rounded-lg border">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <h3 className="text-lg font-semibold">{server.name}</h3>
                  {getStatusIcon(server.status)}
                </div>
                <p className="text-sm text-muted-foreground mb-2">
                  {getServerDescription(server.name)}
                </p>
                <code className="text-xs font-mono text-muted-foreground">
                  {server.package}
                </code>
              </div>
              
              <div className="ml-4">
                {!server.installed && (
                  <button className="px-3 py-1 text-sm bg-primary text-primary-foreground rounded hover:opacity-90">
                    Install
                  </button>
                )}
                {server.installed && (
                  <button className="px-3 py-1 text-sm bg-secondary text-secondary-foreground rounded hover:opacity-90">
                    Test
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-8 p-4 bg-muted rounded-lg">
        <h3 className="font-semibold mb-2">Quick Test Commands</h3>
        <div className="space-y-1 font-mono text-sm">
          <div>cce-mcp-test filesystem</div>
          <div>cce-mcp-test fetch</div>
          <div>cce-mcp-all -p "Using memory MCP, what do you remember?"</div>
        </div>
      </div>
    </div>
  );
};

export default MCPServers;
```

## Task 3: Create Additional Components

Create `~/.cce-universal/web/dashboard/src/components/Projects.tsx`:

```typescript
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { FolderOpen, Package, GitBranch } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

const Projects: React.FC = () => {
  const { data, isLoading } = useQuery({
    queryKey: ['projects'],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/projects`);
      return data;
    },
  });

  if (isLoading) {
    return <div className="animate-pulse">Loading projects...</div>;
  }

  return (
    <div>
      <h2 className="text-3xl font-bold mb-6">Projects</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {data?.projects?.map((project: any) => (
          <div key={project.name} className="bg-card p-6 rounded-lg border hover:border-primary transition-colors">
            <div className="flex items-start justify-between mb-3">
              <FolderOpen className="w-8 h-8 text-primary" />
              <div className="flex gap-2">
                {project.hasClaude && (
                  <div className="w-2 h-2 bg-green-500 rounded-full" title="CCE Enabled" />
                )}
                {project.hasPackageJson && (
                  <Package className="w-4 h-4 text-muted-foreground" />
                )}
              </div>
            </div>
            
            <h3 className="font-semibold text-lg mb-1">{project.name}</h3>
            {project.description && (
              <p className="text-sm text-muted-foreground mb-3">{project.description}</p>
            )}
            
            <div className="flex gap-2 mt-4">
              <button className="text-sm px-3 py-1 bg-primary text-primary-foreground rounded hover:opacity-90">
                Open
              </button>
              <button className="text-sm px-3 py-1 bg-secondary text-secondary-foreground rounded hover:opacity-90">
                Run Agent
              </button>
            </div>
          </div>
        ))}
        
        {/* New Project Card */}
        <div className="bg-card p-6 rounded-lg border-2 border-dashed hover:border-primary transition-colors cursor-pointer flex items-center justify-center">
          <div className="text-center">
            <div className="w-12 h-12 bg-muted rounded-full flex items-center justify-center mx-auto mb-3">
              <span className="text-2xl">+</span>
            </div>
            <p className="font-semibold">Create New Project</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Projects;
```

Create `~/.cce-universal/web/dashboard/src/components/AgentRunner.tsx`:

```typescript
import React, { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import axios from 'axios';
import { Play, Loader } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

const AgentRunner: React.FC = () => {
  const [selectedAgent, setSelectedAgent] = useState('coder');
  const [args, setArgs] = useState('');
  const [output, setOutput] = useState('');

  const agents = [
    { id: 'coder', name: 'Coder', description: 'Write code for specific tasks' },
    { id: 'reviewer', name: 'Reviewer', description: 'Review code quality and security' },
    { id: 'tester', name: 'Tester', description: 'Generate comprehensive tests' },
    { id: 'documenter', name: 'Documenter', description: 'Create documentation' },
    { id: 'debugger', name: 'Debugger', description: 'Find and fix bugs' },
    { id: 'deployer', name: 'Deployer', description: 'Setup deployment configs' },
    { id: 'analyzer', name: 'Analyzer', description: 'Deep code analysis' },
  ];

  const executeMutation = useMutation({
    mutationFn: async ({ agent, args }: { agent: string; args: string }) => {
      const { data } = await axios.post(`${API_BASE}/agents/execute`, { agent, args });
      return data;
    },
    onSuccess: (data) => {
      setOutput(data.stdout || data.error || 'No output');
    },
  });

  const handleExecute = () => {
    executeMutation.mutate({ agent: selectedAgent, args });
  };

  return (
    <div>
      <h2 className="text-3xl font-bold mb-6">AI Agents</h2>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Agent Selection */}
        <div>
          <h3 className="text-lg font-semibold mb-4">Select Agent</h3>
          <div className="space-y-2">
            {agents.map((agent) => (
              <div
                key={agent.id}
                className={`p-4 rounded-lg border cursor-pointer transition-colors ${
                  selectedAgent === agent.id
                    ? 'border-primary bg-primary/10'
                    : 'border-border hover:border-primary/50'
                }`}
                onClick={() => setSelectedAgent(agent.id)}
              >
                <h4 className="font-semibold">{agent.name}</h4>
                <p className="text-sm text-muted-foreground">{agent.description}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Agent Execution */}
        <div>
          <h3 className="text-lg font-semibold mb-4">Execute Agent</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-2">Arguments (optional)</label>
              <textarea
                className="w-full p-3 rounded-lg border bg-background"
                rows={4}
                value={args}
                onChange={(e) => setArgs(e.target.value)}
                placeholder="Enter task description or arguments..."
              />
            </div>
            
            <button
              onClick={handleExecute}
              disabled={executeMutation.isPending}
              className="w-full py-3 bg-primary text-primary-foreground rounded-lg hover:opacity-90 flex items-center justify-center gap-2"
            >
              {executeMutation.isPending ? (
                <>
                  <Loader className="w-4 h-4 animate-spin" />
                  Running...
                </>
              ) : (
                <>
                  <Play className="w-4 h-4" />
                  Execute {agents.find(a => a.id === selectedAgent)?.name} Agent
                </>
              )}
            </button>
          </div>

          {output && (
            <div className="mt-6">
              <h3 className="text-lg font-semibold mb-2">Output</h3>
              <pre className="p-4 bg-muted rounded-lg overflow-auto max-h-96 text-sm">
                {output}
              </pre>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AgentRunner;
```

Create `~/.cce-universal/web/dashboard/src/components/Logs.tsx`:

```typescript
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { FileText, RefreshCw } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

const Logs: React.FC = () => {
  const { data, isLoading, refetch } = useQuery({
    queryKey: ['logs'],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/logs`);
      return data;
    },
  });

  if (isLoading) {
    return <div className="animate-pulse">Loading logs...</div>;
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-3xl font-bold">System Logs</h2>
        <button
          onClick={() => refetch()}
          className="p-2 rounded-lg bg-secondary hover:opacity-90"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>
      
      {data?.logs?.length === 0 ? (
        <div className="bg-card p-8 rounded-lg border text-center">
          <FileText className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
          <p className="text-muted-foreground">No logs available</p>
        </div>
      ) : (
        <div className="space-y-4">
          {data?.logs?.map((log: any, index: number) => (
            <div key={index} className="bg-card p-4 rounded-lg border">
              <h3 className="font-semibold mb-2">{log.file}</h3>
              <pre className="text-sm bg-muted p-3 rounded overflow-auto max-h-64">
                {log.content.join('\n')}
              </pre>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Logs;
```

## Task 4: Create Start Script

Create `~/.cce-universal/web/start-dashboard.sh`:

```bash
#!/bin/bash
# Start CCE Dashboard

echo "🚀 Starting CCE Dashboard..."

# Check if dependencies are installed
if [ ! -d "$HOME/.cce-universal/web/node_modules" ]; then
    echo "📦 Installing backend dependencies..."
    cd ~/.cce-universal/web
    npm install
fi

if [ ! -d "$HOME/.cce-universal/web/dashboard/node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    cd ~/.cce-universal/web/dashboard
    npm install
fi

# Build frontend if not built
if [ ! -d "$HOME/.cce-universal/web/dashboard/build" ]; then
    echo "🔨 Building frontend..."
    cd ~/.cce-universal/web/dashboard
    npm run build
fi

# Start the server
cd ~/.cce-universal/web
echo "🌐 Starting server on http://localhost:3456"
npm start &

# Save PID
echo $! > ~/.cce-universal/web/server.pid

echo "✅ Dashboard running at http://localhost:3456"
echo "Press Ctrl+C to stop"

# Wait
wait
```

Make it executable:
```bash
chmod +x ~/.cce-universal/web/start-dashboard.sh
```

## Task 5: Add Package Scripts

Update `~/.cce-universal/web/package.json`:

```json
{
  "name": "@cce/web",
  "version": "1.0.0",
  "description": "CCE Web Interface and API",
  "main": "server/index.js",
  "scripts": {
    "start": "node server/index.js",
    "dev": "nodemon server/index.js",
    "build": "cd dashboard && npm run build",
    "install-all": "npm install && cd dashboard && npm install",
    "dashboard": "./start-dashboard.sh"
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
```

## Task 6: Update Aliases

Add to `~/.cce-universal/aliases.sh`:

```bash
# Dashboard commands
alias cce-dashboard='~/.cce-universal/web/start-dashboard.sh'
alias cce-dash='cce-dashboard'

# Stop dashboard
cce-dashboard-stop() {
    if [ -f ~/.cce-universal/web/server.pid ]; then
        kill $(cat ~/.cce-universal/web/server.pid)
        rm ~/.cce-universal/web/server.pid
        echo "✅ Dashboard stopped"
    else
        echo "❌ Dashboard not running"
    fi
}
```

## Task 7: Create Development Mode Script

Create `~/.cce-universal/web/dev-dashboard.sh`:

```bash
#!/bin/bash
# Run dashboard in development mode

echo "🔧 Starting CCE Dashboard in development mode..."

# Terminal 1: Backend
gnome-terminal --tab --title="CCE API" -- bash -c "cd ~/.cce-universal/web && npm run dev; exec bash"

# Terminal 2: Frontend
gnome-terminal --tab --title="CCE Frontend" -- bash -c "cd ~/.cce-universal/web/dashboard && npm start; exec bash"

echo "✅ Development servers starting..."
echo "   API: http://localhost:3456"
echo "   Frontend: http://localhost:3000"
```

Make it executable:
```bash
chmod +x ~/.cce-universal/web/dev-dashboard.sh
```

## Final Steps

1. Install dependencies:
   ```bash
   cd ~/.cce-universal/web
   npm install
   cd dashboard
   npm install
   ```

2. Build the dashboard:
   ```bash
   cd ~/.cce-universal/web/dashboard
   npm run build
   ```

3. Start the dashboard:
   ```bash
   cce-dashboard
   ```

4. Access at: http://localhost:3456

## Expected Results

After implementation:
- ✅ Modern React dashboard with Tailwind CSS
- ✅ Real-time updates via WebSocket
- ✅ System status monitoring
- ✅ MCP server management
- ✅ Project browser
- ✅ Agent execution interface
- ✅ Log viewer
- ✅ Dark/light theme support

## Features Implemented

1. **System Overview**: Real-time system status, Claude CLI status, resource usage
2. **MCP Management**: View all servers, installation status, quick test buttons
3. **Project Browser**: List all projects, CCE status, quick actions
4. **Agent Runner**: Execute agents with arguments, real-time output
5. **Log Viewer**: System logs with auto-refresh
6. **WebSocket**: Real-time updates for agent execution