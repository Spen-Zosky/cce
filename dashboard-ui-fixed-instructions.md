# CCE Dashboard UI Fixed - Complete Instructions with Correct Tailwind Setup

## Context
Fixing Tailwind CSS configuration issues in the CCE Dashboard implementation. This version includes proper setup for Create React App with Tailwind CSS.

## Task 1: Backend API (Same as before)

Update `~/.cce-universal/web/server/index.js` with the same content as provided earlier.

## Task 2: Create React Dashboard with Correct Tailwind Setup

### Step 1: Create React App and Install Dependencies

```bash
cd ~/.cce-universal/web

# Create React app with TypeScript
npx create-react-app dashboard --template typescript

cd dashboard

# Install all dependencies including Tailwind and its requirements
npm install axios @tanstack/react-query
npm install -D tailwindcss postcss autoprefixer
npm install lucide-react clsx

# Initialize Tailwind with PostCSS config
npx tailwindcss init -p
```

### Step 2: Configure Tailwind Correctly

Update `~/.cce-universal/web/dashboard/tailwind.config.js`:

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
    },
  },
  plugins: [],
}
```

### Step 3: Create Proper CSS Setup

Replace entire content of `~/.cce-universal/web/dashboard/src/index.css`:

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

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

### Step 4: Update index.tsx to ensure CSS is imported

Update `~/.cce-universal/web/dashboard/src/index.tsx`:

```typescript
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';  // This MUST be here
import App from './App';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

### Step 5: Create Simplified Components (Without Complex Styling)

Create `~/.cce-universal/web/dashboard/src/App.tsx`:

```typescript
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import Dashboard from './components/Dashboard';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchInterval: 5000,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Dashboard />
    </QueryClientProvider>
  );
}

export default App;
```

Create `~/.cce-universal/web/dashboard/src/components/Dashboard.tsx`:

```typescript
import React, { useState } from 'react';
import SystemStatus from './SystemStatus';
import MCPServers from './MCPServers';
import Projects from './Projects';
import AgentRunner from './AgentRunner';
import { Home, Server, FolderOpen, Bot } from 'lucide-react';

const Dashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState('status');

  const tabs = [
    { id: 'status', label: 'System Status', icon: Home },
    { id: 'mcp', label: 'MCP Servers', icon: Server },
    { id: 'projects', label: 'Projects', icon: FolderOpen },
    { id: 'agents', label: 'Agents', icon: Bot },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="flex h-screen">
        {/* Sidebar */}
        <div className="w-64 bg-white border-r border-gray-200">
          <div className="p-6">
            <h1 className="text-2xl font-bold text-gray-900">CCE Dashboard</h1>
            <p className="text-sm text-gray-500 mt-1">v2.0.0</p>
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
                      ? 'bg-blue-600 text-white'
                      : 'hover:bg-gray-100 text-gray-700'
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
        <div className="flex-1 overflow-auto bg-gray-50">
          <div className="p-8">
            {activeTab === 'status' && <SystemStatus />}
            {activeTab === 'mcp' && <MCPServers />}
            {activeTab === 'projects' && <Projects />}
            {activeTab === 'agents' && <AgentRunner />}
          </div>
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
      <h2 className="text-3xl font-bold mb-6 text-gray-900">System Status</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* CCE Status */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold mb-4 text-gray-900">CCE Environment</h3>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-gray-600">Version</span>
              <span className="font-mono text-gray-900">{status?.cce?.version}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Environment</span>
              <span className="font-mono text-gray-900">{status?.cce?.environment}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Architecture</span>
              <span className="font-mono text-gray-900">{status?.cce?.architecture}</span>
            </div>
          </div>
        </div>

        {/* Claude Status */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold mb-4 text-gray-900">Claude CLI</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Installation</span>
              {status?.claude?.installed ? (
                <CheckCircle className="w-5 h-5 text-green-500" />
              ) : (
                <XCircle className="w-5 h-5 text-red-500" />
              )}
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-700">API Key</span>
              {status?.apiKey?.configured ? (
                <CheckCircle className="w-5 h-5 text-green-500" />
              ) : (
                <XCircle className="w-5 h-5 text-red-500" />
              )}
            </div>
          </div>
        </div>

        {/* System Resources */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold mb-4 text-gray-900">System Resources</h3>
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-gray-500" />
              <span className="text-sm text-gray-700">Uptime: {formatUptime(status?.uptime || 0)}</span>
            </div>
            <div className="flex items-center gap-2">
              <HardDrive className="w-4 h-4 text-gray-500" />
              <span className="text-sm text-gray-700">Memory: {formatMemory(status?.memory?.heapUsed || 0)}</span>
            </div>
            <div className="flex items-center gap-2">
              <Cpu className="w-4 h-4 text-gray-500" />
              <span className="text-sm text-gray-700">Node: {status?.node}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8">
        <h3 className="text-xl font-semibold mb-4 text-gray-900">Quick Actions</h3>
        <div className="flex gap-4">
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
            Create New Project
          </button>
          <button className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors">
            Run System Check
          </button>
          <button className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors">
            Update CCE
          </button>
        </div>
      </div>
    </div>
  );
};

export default SystemStatus;
```

## Task 3: Alternative - Simple HTML/CSS Dashboard (No Build Issues)

If Tailwind continues to cause issues, create a simple dashboard without build tools:

Create `~/.cce-universal/web/dashboard-simple/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CCE Dashboard</title>
    <script src="https://unpkg.com/axios/dist/axios.min.js"></script>
    <script src="https://unpkg.com/alpinejs@3/dist/cdn.min.js" defer></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            color: #333;
        }
        
        .container {
            display: flex;
            height: 100vh;
        }
        
        .sidebar {
            width: 250px;
            background: white;
            border-right: 1px solid #e0e0e0;
            padding: 20px;
        }
        
        .sidebar h1 {
            font-size: 24px;
            margin-bottom: 5px;
        }
        
        .sidebar .version {
            color: #666;
            font-size: 14px;
            margin-bottom: 30px;
        }
        
        .nav-item {
            display: block;
            width: 100%;
            padding: 12px 16px;
            margin-bottom: 5px;
            border: none;
            background: transparent;
            text-align: left;
            cursor: pointer;
            border-radius: 8px;
            transition: all 0.2s;
        }
        
        .nav-item:hover {
            background: #f0f0f0;
        }
        
        .nav-item.active {
            background: #3b82f6;
            color: white;
        }
        
        .main {
            flex: 1;
            padding: 30px;
            overflow-y: auto;
        }
        
        .card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        
        .status-badge.success {
            color: #10b981;
        }
        
        .status-badge.error {
            color: #ef4444;
        }
        
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            transition: opacity 0.2s;
        }
        
        .btn:hover {
            opacity: 0.9;
        }
        
        .btn-primary {
            background: #3b82f6;
            color: white;
        }
        
        .btn-secondary {
            background: #e5e7eb;
            color: #374151;
        }
        
        h2 {
            margin-bottom: 20px;
            font-size: 28px;
        }
        
        h3 {
            margin-bottom: 15px;
            font-size: 18px;
        }
        
        .loading {
            color: #666;
            padding: 20px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container" x-data="dashboard()">
        <!-- Sidebar -->
        <div class="sidebar">
            <h1>CCE Dashboard</h1>
            <p class="version">v2.0.0</p>
            
            <nav>
                <button class="nav-item" :class="{ active: activeTab === 'status' }" @click="activeTab = 'status'">
                    System Status
                </button>
                <button class="nav-item" :class="{ active: activeTab === 'mcp' }" @click="activeTab = 'mcp'">
                    MCP Servers
                </button>
                <button class="nav-item" :class="{ active: activeTab === 'projects' }" @click="activeTab = 'projects'">
                    Projects
                </button>
                <button class="nav-item" :class="{ active: activeTab === 'agents' }" @click="activeTab = 'agents'">
                    Agents
                </button>
            </nav>
        </div>
        
        <!-- Main Content -->
        <div class="main">
            <!-- System Status Tab -->
            <div x-show="activeTab === 'status'">
                <h2>System Status</h2>
                
                <div class="grid">
                    <div class="card">
                        <h3>CCE Environment</h3>
                        <div x-show="!loading.status" x-html="renderStatus()"></div>
                        <div x-show="loading.status" class="loading">Loading...</div>
                    </div>
                    
                    <div class="card">
                        <h3>Claude CLI</h3>
                        <div x-show="!loading.status" x-html="renderClaude()"></div>
                        <div x-show="loading.status" class="loading">Loading...</div>
                    </div>
                    
                    <div class="card">
                        <h3>System Resources</h3>
                        <div x-show="!loading.status" x-html="renderResources()"></div>
                        <div x-show="loading.status" class="loading">Loading...</div>
                    </div>
                </div>
                
                <div class="card">
                    <h3>Quick Actions</h3>
                    <div style="display: flex; gap: 10px;">
                        <button class="btn btn-primary">Create New Project</button>
                        <button class="btn btn-secondary" @click="loadStatus()">Refresh Status</button>
                        <button class="btn btn-secondary">Update CCE</button>
                    </div>
                </div>
            </div>
            
            <!-- MCP Servers Tab -->
            <div x-show="activeTab === 'mcp'">
                <h2>MCP Servers</h2>
                <div x-show="!loading.mcp" x-html="renderMCPServers()"></div>
                <div x-show="loading.mcp" class="loading">Loading MCP servers...</div>
            </div>
            
            <!-- Projects Tab -->
            <div x-show="activeTab === 'projects'">
                <h2>Projects</h2>
                <div x-show="!loading.projects" x-html="renderProjects()"></div>
                <div x-show="loading.projects" class="loading">Loading projects...</div>
            </div>
            
            <!-- Agents Tab -->
            <div x-show="activeTab === 'agents'">
                <h2>AI Agents</h2>
                <div class="card">
                    <h3>Execute Agent</h3>
                    <div style="margin-bottom: 15px;">
                        <label style="display: block; margin-bottom: 5px;">Select Agent:</label>
                        <select x-model="selectedAgent" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;">
                            <option value="coder">Coder - Write code</option>
                            <option value="reviewer">Reviewer - Review code</option>
                            <option value="tester">Tester - Generate tests</option>
                            <option value="documenter">Documenter - Create docs</option>
                            <option value="debugger">Debugger - Fix bugs</option>
                            <option value="deployer">Deployer - Setup deployment</option>
                            <option value="analyzer">Analyzer - Code analysis</option>
                        </select>
                    </div>
                    
                    <div style="margin-bottom: 15px;">
                        <label style="display: block; margin-bottom: 5px;">Arguments:</label>
                        <textarea x-model="agentArgs" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; height: 100px;"></textarea>
                    </div>
                    
                    <button class="btn btn-primary" @click="executeAgent()" :disabled="executing">
                        <span x-show="!executing">Execute Agent</span>
                        <span x-show="executing">Executing...</span>
                    </button>
                    
                    <div x-show="agentOutput" style="margin-top: 20px;">
                        <h4 style="margin-bottom: 10px;">Output:</h4>
                        <pre style="background: #f5f5f5; padding: 15px; border-radius: 4px; overflow-x: auto;" x-text="agentOutput"></pre>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        function dashboard() {
            return {
                activeTab: 'status',
                apiBase: 'http://localhost:3456/api/v1',
                loading: {
                    status: true,
                    mcp: true,
                    projects: true
                },
                data: {
                    status: null,
                    mcp: null,
                    projects: null
                },
                selectedAgent: 'coder',
                agentArgs: '',
                agentOutput: '',
                executing: false,
                
                init() {
                    this.loadStatus();
                    this.loadMCP();
                    this.loadProjects();
                    
                    // Auto-refresh
                    setInterval(() => {
                        if (this.activeTab === 'status') this.loadStatus();
                    }, 5000);
                },
                
                async loadStatus() {
                    try {
                        const response = await axios.get(`${this.apiBase}/status`);
                        this.data.status = response.data;
                        this.loading.status = false;
                    } catch (error) {
                        console.error('Failed to load status:', error);
                    }
                },
                
                async loadMCP() {
                    try {
                        const response = await axios.get(`${this.apiBase}/mcp/servers`);
                        this.data.mcp = response.data;
                        this.loading.mcp = false;
                    } catch (error) {
                        console.error('Failed to load MCP servers:', error);
                    }
                },
                
                async loadProjects() {
                    try {
                        const response = await axios.get(`${this.apiBase}/projects`);
                        this.data.projects = response.data;
                        this.loading.projects = false;
                    } catch (error) {
                        console.error('Failed to load projects:', error);
                    }
                },
                
                async executeAgent() {
                    this.executing = true;
                    this.agentOutput = '';
                    
                    try {
                        const response = await axios.post(`${this.apiBase}/agents/execute`, {
                            agent: this.selectedAgent,
                            args: this.agentArgs
                        });
                        this.agentOutput = response.data.stdout || response.data.error || 'No output';
                    } catch (error) {
                        this.agentOutput = `Error: ${error.message}`;
                    } finally {
                        this.executing = false;
                    }
                },
                
                renderStatus() {
                    if (!this.data.status) return '';
                    const s = this.data.status;
                    return `
                        <div>Version: <strong>${s.cce?.version || 'N/A'}</strong></div>
                        <div>Environment: <strong>${s.cce?.environment || 'N/A'}</strong></div>
                        <div>Architecture: <strong>${s.cce?.architecture || 'N/A'}</strong></div>
                    `;
                },
                
                renderClaude() {
                    if (!this.data.status) return '';
                    const s = this.data.status;
                    return `
                        <div class="status-badge ${s.claude?.installed ? 'success' : 'error'}">
                            Installation: ${s.claude?.installed ? '✓ Installed' : '✗ Not installed'}
                        </div>
                        <br>
                        <div class="status-badge ${s.apiKey?.configured ? 'success' : 'error'}">
                            API Key: ${s.apiKey?.configured ? '✓ Configured' : '✗ Not configured'}
                        </div>
                    `;
                },
                
                renderResources() {
                    if (!this.data.status) return '';
                    const s = this.data.status;
                    const uptime = Math.floor((s.uptime || 0) / 60);
                    const memory = Math.round((s.memory?.heapUsed || 0) / 1024 / 1024);
                    return `
                        <div>Uptime: <strong>${uptime} minutes</strong></div>
                        <div>Memory: <strong>${memory} MB</strong></div>
                        <div>Node: <strong>${s.node || 'N/A'}</strong></div>
                    `;
                },
                
                renderMCPServers() {
                    if (!this.data.mcp?.servers) return '<div class="card">No servers found</div>';
                    
                    return this.data.mcp.servers.map(server => `
                        <div class="card">
                            <h3>${server.name}</h3>
                            <div class="status-badge ${server.installed ? 'success' : 'error'}">
                                ${server.installed ? '✓ Installed' : '✗ Not installed'}
                            </div>
                            <div style="margin-top: 10px;">
                                <code style="font-size: 12px; color: #666;">${server.package}</code>
                            </div>
                            ${server.installed ? 
                                '<button class="btn btn-secondary" style="margin-top: 10px;">Test</button>' : 
                                '<button class="btn btn-primary" style="margin-top: 10px;">Install</button>'
                            }
                        </div>
                    `).join('');
                },
                
                renderProjects() {
                    if (!this.data.projects?.projects) return '<div class="card">No projects found</div>';
                    
                    return '<div class="grid">' + this.data.projects.projects.map(project => `
                        <div class="card">
                            <h3>${project.name}</h3>
                            ${project.description ? `<p style="color: #666; margin-bottom: 10px;">${project.description}</p>` : ''}
                            <div style="margin-top: 10px;">
                                ${project.hasClaude ? '<span class="status-badge success">✓ CCE</span>' : ''}
                                ${project.hasPackageJson ? '<span class="status-badge success">📦 Node</span>' : ''}
                            </div>
                            <div style="margin-top: 15px;">
                                <button class="btn btn-primary">Open</button>
                                <button class="btn btn-secondary" style="margin-left: 5px;">Run Agent</button>
                            </div>
                        </div>
                    `).join('') + '</div>';
                }
            }
        }
    </script>
</body>
</html>
```

## Task 4: Update Server to Serve Simple Dashboard

Update the Express server to serve the simple dashboard:

```javascript
// Add this to server/index.js
app.use(express.static(path.join(__dirname, '../dashboard-simple')));

// Update the catch-all route
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../dashboard-simple/index.html'));
});
```

## Troubleshooting Steps

1. **For React + Tailwind issues:**
   ```bash
   cd ~/.cce-universal/web/dashboard
   rm -rf node_modules package-lock.json
   npm install
   npm run build
   ```

2. **Check PostCSS config exists:**
   ```bash
   cat ~/.cce-universal/web/dashboard/postcss.config.js
   ```
   Should contain:
   ```javascript
   module.exports = {
     plugins: {
       tailwindcss: {},
       autoprefixer: {},
     },
   }
   ```

3. **Use the simple dashboard instead:**
   ```bash
   cd ~/.cce-universal/web
   mkdir dashboard-simple
   # Create the HTML file above
   # Update server to use dashboard-simple
   ```

## Quick Solution

Se Tailwind continua a dare problemi, usa la **dashboard semplice** (Task 3) che:
- Non richiede build
- Funziona immediatamente
- Ha tutte le funzionalità
- Usa Alpine.js per interattività
- Nessuna dipendenza da compilare

Fammi sapere quale approccio preferisci!