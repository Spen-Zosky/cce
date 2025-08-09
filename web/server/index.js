const express = require('express');
const cors = require('cors');
const WebSocket = require('ws');
const fs = require('fs').promises;
const path = require('path');
const { exec, spawn } = require('child_process');
const util = require('util');
const pty = require('node-pty');

const execPromise = util.promisify(exec);
const app = express();

// Configuration
const PORT = process.env.PORT || 3456;
const CCE_HOME = process.env.CCE_HOME || path.join(process.env.HOME, '.cce-universal');
const LOGS_DIR = path.join(CCE_HOME, 'logs');
const PROJECTS_DIR = process.env.HOME;

// Ensure logs directory exists
fs.mkdir(LOGS_DIR, { recursive: true }).catch(console.error);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../dashboard/build')));

// WebSocket server
const server = app.listen(PORT, () => {
  console.log(`🚀 CCE Dashboard API running on http://localhost:${PORT}`);
});

const wss = new WebSocket.Server({ noServer: true });

// Terminal sessions
const terminalSessions = new Map();

// Broadcast to all WebSocket clients
const broadcast = (data) => {
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
};

// Log execution to file
const logExecution = async (type, data) => {
  const logFile = path.join(LOGS_DIR, `${type}-${new Date().toISOString().split('T')[0]}.log`);
  const logEntry = {
    timestamp: new Date().toISOString(),
    ...data
  };
  
  try {
    let logs = [];
    try {
      const existing = await fs.readFile(logFile, 'utf8');
      logs = JSON.parse(existing);
    } catch {}
    
    logs.push(logEntry);
    await fs.writeFile(logFile, JSON.stringify(logs, null, 2));
  } catch (error) {
    console.error('Failed to log execution:', error);
  }
};

// API Routes

// System Status
app.get('/api/v1/status', async (req, res) => {
  try {
    const status = {
      cce: {
        version: '2.0.0',
        home: CCE_HOME,
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
      
      // Check Claude version
      try {
        const { stdout } = await execPromise('claude --version');
        status.claude.version = stdout.trim();
      } catch {}
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
        path.join(CCE_HOME, 'mcp-servers/node_modules', server.package)
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

// Test MCP Server
app.post('/api/v1/mcp/test', async (req, res) => {
  const { server } = req.body;
  
  try {
    const testCommand = `cd ${CCE_HOME} && bash -c "source ~/.bashrc && cce-mcp-test ${server}"`;
    const { stdout, stderr } = await execPromise(testCommand, {
      env: { ...process.env, HOME: process.env.HOME }
    });
    
    res.json({ 
      success: true, 
      output: stdout || stderr || 'Test completed' 
    });
  } catch (error) {
    res.json({ 
      success: false, 
      output: error.message 
    });
  }
});

// Install MCP Server
app.post('/api/v1/mcp/install', async (req, res) => {
  const { server } = req.body;
  
  broadcast({ type: 'mcp_install_start', server });
  
  try {
    const installCommand = `cd ${path.join(CCE_HOME, 'mcp-servers')} && npm install ${server}`;
    const { stdout, stderr } = await execPromise(installCommand);
    
    broadcast({ type: 'mcp_install_complete', server, success: true });
    res.json({ success: true, output: stdout });
  } catch (error) {
    broadcast({ type: 'mcp_install_complete', server, success: false });
    res.status(500).json({ error: error.message });
  }
});

// Projects List
app.get('/api/v1/projects', async (req, res) => {
  try {
    const entries = await fs.readdir(PROJECTS_DIR, { withFileTypes: true });
    
    const projects = await Promise.all(
      entries
        .filter(entry => entry.isDirectory() && !entry.name.startsWith('.'))
        .map(async (entry) => {
          const projectPath = path.join(PROJECTS_DIR, entry.name);
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
            
            // Get git status
            let gitStatus = null;
            try {
              const { stdout } = await execPromise('git status --porcelain', { cwd: projectPath });
              gitStatus = {
                hasChanges: stdout.trim().length > 0,
                changeCount: stdout.trim().split('\n').filter(l => l).length
              };
            } catch {}
            
            return {
              name: entry.name,
              path: projectPath,
              hasClaude,
              hasPackageJson,
              gitStatus,
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

// Open project
app.post('/api/v1/projects/open', async (req, res) => {
  const { path: projectPath } = req.body;
  
  try {
    // Try VS Code first
    try {
      await execPromise(`code "${projectPath}"`);
      res.json({ success: true, method: 'vscode' });
    } catch {
      // Try system file manager
      const opener = process.platform === 'darwin' ? 'open' : 'xdg-open';
      await execPromise(`${opener} "${projectPath}"`);
      res.json({ success: true, method: 'filemanager' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new project
app.post('/api/v1/projects/create', async (req, res) => {
  const { name, type = 'basic' } = req.body;
  
  if (!name || !name.match(/^[a-zA-Z0-9-_]+$/)) {
    return res.status(400).json({ error: 'Invalid project name' });
  }
  
  broadcast({ type: 'project_create_start', name, projectType: type });
  
  try {
    const projectPath = path.join(PROJECTS_DIR, name);
    
    // Check if exists
    try {
      await fs.access(projectPath);
      return res.status(400).json({ error: 'Project already exists' });
    } catch {}
    
    // Create project using CCE commands
    const command = type === 'super' 
      ? `cd ${PROJECTS_DIR} && bash -c "source ~/.bashrc && cce-super ${name}"`
      : `cd ${PROJECTS_DIR} && bash -c "source ~/.bashrc && cce-create ${name}"`;
    
    const { stdout, stderr } = await execPromise(command, {
      env: { ...process.env }
    });
    
    await logExecution('project-create', {
      name,
      type,
      path: projectPath,
      success: true
    });
    
    broadcast({
      type: 'project_created',
      name,
      path: projectPath,
      timestamp: new Date().toISOString()
    });
    
    res.json({ 
      success: true, 
      path: projectPath,
      output: stdout
    });
  } catch (error) {
    broadcast({ type: 'project_create_error', name, error: error.message });
    res.status(500).json({ error: error.message });
  }
});

// Git operations
app.post('/api/v1/projects/git', async (req, res) => {
  const { path: projectPath, command } = req.body;
  
  const allowedCommands = ['status', 'log --oneline -10', 'diff', 'branch'];
  if (!allowedCommands.includes(command)) {
    return res.status(400).json({ error: 'Command not allowed' });
  }
  
  try {
    const { stdout, stderr } = await execPromise(`git ${command}`, { cwd: projectPath });
    res.json({ output: stdout || stderr });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Agent Execution
app.post('/api/v1/agents/execute', async (req, res) => {
  const { agent, args, project } = req.body;
  
  if (!agent) {
    return res.status(400).json({ error: 'Agent name required' });
  }
  
  const executionId = Date.now().toString();
  
  broadcast({ 
    type: 'agent_start', 
    agent, 
    args,
    project,
    executionId,
    timestamp: new Date().toISOString() 
  });
  
  try {
    // Build command
    let command = `bash -c "source ~/.bashrc && cce-agent ${agent}`;
    if (args) command += ` '${args.replace(/'/g, "'\"'\"'")}'`;
    command += '"';
    
    // Execute in project directory if specified
    const options = {
      env: { ...process.env },
      maxBuffer: 1024 * 1024 * 10 // 10MB buffer
    };
    
    if (project) {
      options.cwd = project;
    }
    
    const { stdout, stderr } = await execPromise(command, options);
    
    const result = {
      agent,
      args,
      project,
      stdout,
      stderr,
      success: !stderr || stderr.length === 0,
      timestamp: new Date().toISOString(),
      executionId
    };
    
    await logExecution('agent', result);
    
    broadcast({ 
      type: 'agent_complete',
      ...result
    });
    
    res.json(result);
  } catch (error) {
    const errorResult = {
      agent,
      args,
      project,
      error: error.message,
      success: false,
      timestamp: new Date().toISOString(),
      executionId
    };
    
    await logExecution('agent', errorResult);
    
    broadcast({ 
      type: 'agent_error',
      ...errorResult
    });
    
    res.status(500).json(errorResult);
  }
});

// Get agent execution history
app.get('/api/v1/agents/history', async (req, res) => {
  try {
    const files = await fs.readdir(LOGS_DIR);
    const agentLogs = files.filter(f => f.startsWith('agent-'));
    
    let history = [];
    for (const file of agentLogs.slice(-5)) { // Last 5 days
      try {
        const content = await fs.readFile(path.join(LOGS_DIR, file), 'utf8');
        const logs = JSON.parse(content);
        history = history.concat(logs);
      } catch {}
    }
    
    // Sort by timestamp and get last 50
    history.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    res.json({ history: history.slice(0, 50) });
  } catch (error) {
    res.json({ history: [] });
  }
});

// AI Chat endpoint
app.post('/api/v1/ai/chat', async (req, res) => {
  const { message, context, history } = req.body;
  
  try {
    // Build context-aware prompt
    let prompt = message;
    if (context) {
      prompt = `Context: ${JSON.stringify(context)}\n\nUser: ${message}`;
    }
    
    // Use Claude CLI
    const command = `claude -p "${prompt.replace(/"/g, '\\"')}"`;
    const { stdout, stderr } = await execPromise(command, {
      env: { ...process.env },
      maxBuffer: 1024 * 1024 * 5
    });
    
    res.json({ 
      response: stdout || stderr || 'No response',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Analytics endpoints
app.get('/api/v1/analytics', async (req, res) => {
  const { range = 'week' } = req.query;
  
  try {
    // Get agent execution stats
    const files = await fs.readdir(LOGS_DIR);
    const agentLogs = files.filter(f => f.startsWith('agent-'));
    
    let executions = [];
    for (const file of agentLogs) {
      try {
        const content = await fs.readFile(path.join(LOGS_DIR, file), 'utf8');
        const logs = JSON.parse(content);
        executions = executions.concat(logs);
      } catch {}
    }
    
    // Calculate metrics
    const now = new Date();
    const rangeMs = {
      day: 24 * 60 * 60 * 1000,
      week: 7 * 24 * 60 * 60 * 1000,
      month: 30 * 24 * 60 * 60 * 1000,
      year: 365 * 24 * 60 * 60 * 1000
    };
    
    const cutoff = new Date(now - rangeMs[range]);
    const filtered = executions.filter(e => new Date(e.timestamp) > cutoff);
    
    const successCount = filtered.filter(e => e.success).length;
    const totalCount = filtered.length;
    
    // Get unique projects
    const projects = await fs.readdir(PROJECTS_DIR, { withFileTypes: true });
    const projectCount = projects.filter(p => p.isDirectory() && !p.name.startsWith('.')).length;
    
    res.json({
      agentExecutions: totalCount,
      agentExecutionsChange: 12, // Mock data
      avgExecutionTime: filtered.length > 0 ? 3.2 : 0,
      executionTimeChange: -5,
      successRate: totalCount > 0 ? Math.round((successCount / totalCount) * 100) : 100,
      successRateChange: 3,
      activeProjects: projectCount,
      activeProjectsChange: 1,
      recentActivity: filtered.slice(0, 10).map(e => ({
        timestamp: e.timestamp,
        agent: e.agent,
        project: e.project || 'N/A',
        duration: Math.random() * 10 + 1,
        status: e.success ? 'success' : 'error'
      }))
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// System resources monitoring
app.get('/api/v1/system/resources', async (req, res) => {
  try {
    const { stdout: cpu } = await execPromise("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1");
    const { stdout: memory } = await execPromise("free | grep Mem | awk '{print ($2-$7)/$2 * 100.0}'");
    const { stdout: disk } = await execPromise("df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1");
    
    res.json({
      cpu: parseFloat(cpu) || 0,
      memory: parseFloat(memory) || 0,
      disk: parseFloat(disk) || 0,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.json({ cpu: 0, memory: 0, disk: 0 });
  }
});

// Logs Endpoint
app.get('/api/v1/logs', async (req, res) => {
  try {
    await fs.mkdir(LOGS_DIR, { recursive: true });
    
    const files = await fs.readdir(LOGS_DIR);
    const logs = await Promise.all(
      files
        .filter(f => f.endsWith('.log'))
        .slice(-10) // Last 10 log files
        .map(async (file) => {
          try {
            const content = await fs.readFile(path.join(LOGS_DIR, file), 'utf8');
            // Try to parse as JSON first
            try {
              const jsonLogs = JSON.parse(content);
              return {
                file,
                content: jsonLogs.slice(-50).map(log => JSON.stringify(log))
              };
            } catch {
              // If not JSON, treat as plain text
              return {
                file,
                content: content.split('\n').slice(-100).filter(line => line.trim())
              };
            }
          } catch {
            return { file, content: [] };
          }
        })
    );
    
    res.json({ logs: logs.filter(l => l.content.length > 0) });
  } catch (error) {
    res.json({ logs: [] });
  }
});

// Health check
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Workflow Templates (must be before generic /workflows route)
app.get('/api/v1/workflows/templates', async (req, res) => {
  try {
    const templates = {
      fullstack: {
        id: 'template-fullstack',
        name: 'Full-Stack Development',
        description: 'Complete application development workflow',
        nodes: [
          { id: '1', type: 'agent', position: { x: 250, y: 0 }, data: { label: 'Project Analysis', agentType: 'analyzer', description: 'Analyze requirements and plan architecture' }},
          { id: '2', type: 'agent', position: { x: 100, y: 120 }, data: { label: 'Backend API', agentType: 'coder', description: 'Develop API endpoints and database' }},
          { id: '3', type: 'agent', position: { x: 400, y: 120 }, data: { label: 'Frontend UI', agentType: 'coder', description: 'Create React components and pages' }},
          { id: '4', type: 'agent', position: { x: 250, y: 240 }, data: { label: 'Testing Suite', agentType: 'tester', description: 'Generate comprehensive tests' }},
          { id: '5', type: 'agent', position: { x: 250, y: 360 }, data: { label: 'Documentation', agentType: 'documenter', description: 'Create project documentation' }},
        ],
        edges: [
          { id: 'e1-2', source: '1', target: '2' },
          { id: 'e1-3', source: '1', target: '3' },
          { id: 'e2-4', source: '2', target: '4' },
          { id: 'e3-4', source: '3', target: '4' },
          { id: 'e4-5', source: '4', target: '5' },
        ]
      },
      debug: {
        id: 'template-debug',
        name: 'Debug Investigation',
        description: 'Systematic bug investigation and resolution',
        nodes: [
          { id: '1', type: 'agent', position: { x: 250, y: 0 }, data: { label: 'Issue Analysis', agentType: 'debugger', description: 'Analyze the reported issue' }},
          { id: '2', type: 'agent', position: { x: 100, y: 120 }, data: { label: 'Root Cause', agentType: 'analyzer', description: 'Find root cause of the issue' }},
          { id: '3', type: 'agent', position: { x: 400, y: 120 }, data: { label: 'Fix Implementation', agentType: 'coder', description: 'Implement the fix' }},
          { id: '4', type: 'agent', position: { x: 250, y: 240 }, data: { label: 'Verify Fix', agentType: 'tester', description: 'Test the fix thoroughly' }},
        ],
        edges: [
          { id: 'e1-2', source: '1', target: '2' },
          { id: 'e2-3', source: '2', target: '3' },
          { id: 'e3-4', source: '3', target: '4' },
        ]
      },
      optimize: {
        id: 'template-optimize',
        name: 'Performance Optimization',
        description: 'Systematic performance optimization workflow',
        nodes: [
          { id: '1', type: 'agent', position: { x: 250, y: 0 }, data: { label: 'Performance Analysis', agentType: 'analyzer', description: 'Analyze current performance bottlenecks' }},
          { id: '2', type: 'agent', position: { x: 250, y: 120 }, data: { label: 'Code Optimization', agentType: 'coder', description: 'Implement performance improvements' }},
          { id: '3', type: 'agent', position: { x: 100, y: 240 }, data: { label: 'Testing', agentType: 'tester', description: 'Test performance improvements' }},
          { id: '4', type: 'agent', position: { x: 400, y: 240 }, data: { label: 'Documentation', agentType: 'documenter', description: 'Document optimizations' }},
        ],
        edges: [
          { id: 'e1-2', source: '1', target: '2' },
          { id: 'e2-3', source: '2', target: '3' },
          { id: 'e2-4', source: '2', target: '4' },
        ]
      }
    };
    
    res.json({ templates });
  } catch (error) {
    console.error('Failed to get workflow templates:', error);
    res.status(500).json({ error: 'Failed to get workflow templates' });
  }
});

// Workflow Management
app.get('/api/v1/workflows', async (req, res) => {
  try {
    const workflowsDir = path.join(CCE_HOME, 'workflows');
    
    try {
      await fs.mkdir(workflowsDir, { recursive: true });
      const files = await fs.readdir(workflowsDir);
      const workflows = [];
      
      for (const file of files) {
        if (file.endsWith('.json')) {
          try {
            const content = await fs.readFile(path.join(workflowsDir, file), 'utf8');
            const workflow = JSON.parse(content);
            workflows.push(workflow);
          } catch (error) {
            console.error(`Failed to read workflow ${file}:`, error);
          }
        }
      }
      
      res.json({ workflows: workflows.sort((a, b) => new Date(b.modified) - new Date(a.modified)) });
    } catch (error) {
      res.json({ workflows: [] });
    }
  } catch (error) {
    console.error('Failed to get workflows:', error);
    res.status(500).json({ error: 'Failed to get workflows' });
  }
});

app.post('/api/v1/workflows', async (req, res) => {
  try {
    const { name, description, nodes, edges } = req.body;
    
    if (!name || !nodes || !edges) {
      return res.status(400).json({ error: 'Name, nodes, and edges are required' });
    }
    
    const workflow = {
      id: `workflow-${Date.now()}`,
      name,
      description: description || '',
      nodes,
      edges,
      created: new Date().toISOString(),
      modified: new Date().toISOString(),
      executions: 0
    };
    
    const workflowsDir = path.join(CCE_HOME, 'workflows');
    await fs.mkdir(workflowsDir, { recursive: true });
    
    const filename = `${workflow.id}.json`;
    await fs.writeFile(path.join(workflowsDir, filename), JSON.stringify(workflow, null, 2));
    
    broadcast({
      type: 'workflow_saved',
      workflow
    });
    
    res.json({ workflow });
  } catch (error) {
    console.error('Failed to save workflow:', error);
    res.status(500).json({ error: 'Failed to save workflow' });
  }
});

app.get('/api/v1/workflows/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const workflowFile = path.join(CCE_HOME, 'workflows', `${id}.json`);
    
    const content = await fs.readFile(workflowFile, 'utf8');
    const workflow = JSON.parse(content);
    
    res.json({ workflow });
  } catch (error) {
    console.error('Failed to get workflow:', error);
    res.status(404).json({ error: 'Workflow not found' });
  }
});

app.put('/api/v1/workflows/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, nodes, edges } = req.body;
    const workflowFile = path.join(CCE_HOME, 'workflows', `${id}.json`);
    
    // Read existing workflow
    const content = await fs.readFile(workflowFile, 'utf8');
    const existingWorkflow = JSON.parse(content);
    
    // Update workflow
    const updatedWorkflow = {
      ...existingWorkflow,
      name: name || existingWorkflow.name,
      description: description !== undefined ? description : existingWorkflow.description,
      nodes: nodes || existingWorkflow.nodes,
      edges: edges || existingWorkflow.edges,
      modified: new Date().toISOString()
    };
    
    await fs.writeFile(workflowFile, JSON.stringify(updatedWorkflow, null, 2));
    
    broadcast({
      type: 'workflow_updated',
      workflow: updatedWorkflow
    });
    
    res.json({ workflow: updatedWorkflow });
  } catch (error) {
    console.error('Failed to update workflow:', error);
    res.status(500).json({ error: 'Failed to update workflow' });
  }
});

app.delete('/api/v1/workflows/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const workflowFile = path.join(CCE_HOME, 'workflows', `${id}.json`);
    
    await fs.unlink(workflowFile);
    
    broadcast({
      type: 'workflow_deleted',
      workflowId: id
    });
    
    res.json({ success: true });
  } catch (error) {
    console.error('Failed to delete workflow:', error);
    res.status(500).json({ error: 'Failed to delete workflow' });
  }
});

app.post('/api/v1/workflows/:id/execute', async (req, res) => {
  try {
    const { id } = req.params;
    const { project } = req.body;
    
    const workflowFile = path.join(CCE_HOME, 'workflows', `${id}.json`);
    const content = await fs.readFile(workflowFile, 'utf8');
    const workflow = JSON.parse(content);
    
    const executionId = `exec-${Date.now()}`;
    
    broadcast({
      type: 'workflow_execution_start',
      executionId,
      workflowId: id,
      workflowName: workflow.name
    });
    
    // Execute workflow (simplified version - in reality would need topological sorting)
    const results = {};
    let hasError = false;
    
    for (const node of workflow.nodes) {
      if (hasError) break;
      
      try {
        broadcast({
          type: 'workflow_node_start',
          executionId,
          nodeId: node.id,
          agentType: node.data.agentType
        });
        
        const startTime = Date.now();
        
        // Execute agent
        const { stdout, stderr } = await execPromise(
          `cd "${CCE_HOME}" && bash -c "source ~/.bashrc && cce-agent ${node.data.agentType} '${node.data.args || ''}'"`,
          { 
            cwd: project || process.env.HOME,
            env: { ...process.env, CCE_HOME }
          }
        );
        
        const executionTime = (Date.now() - startTime) / 1000;
        
        results[node.id] = {
          success: true,
          stdout,
          stderr,
          executionTime
        };
        
        broadcast({
          type: 'workflow_node_complete',
          executionId,
          nodeId: node.id,
          success: true,
          executionTime
        });
        
      } catch (error) {
        hasError = true;
        results[node.id] = {
          success: false,
          error: error.message,
          stderr: error.stderr || error.message
        };
        
        broadcast({
          type: 'workflow_node_error',
          executionId,
          nodeId: node.id,
          error: error.message
        });
      }
    }
    
    // Update workflow execution count
    workflow.executions = (workflow.executions || 0) + 1;
    workflow.lastExecuted = new Date().toISOString();
    await fs.writeFile(workflowFile, JSON.stringify(workflow, null, 2));
    
    const execution = {
      id: executionId,
      workflowId: id,
      workflowName: workflow.name,
      status: hasError ? 'error' : 'completed',
      startTime: new Date().toISOString(),
      endTime: new Date().toISOString(),
      results
    };
    
    // Log execution
    await logExecution('workflow', execution);
    
    broadcast({
      type: 'workflow_execution_complete',
      execution
    });
    
    res.json({ execution });
    
  } catch (error) {
    console.error('Failed to execute workflow:', error);
    
    broadcast({
      type: 'workflow_execution_error',
      executionId: req.params.id,
      error: error.message
    });
    
    res.status(500).json({ error: 'Failed to execute workflow' });
  }
});

app.get('/api/v1/workflows/:id/executions', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get execution history from logs
    const files = await fs.readdir(LOGS_DIR);
    const workflowLogs = files.filter(f => f.startsWith('workflow-'));
    
    let executions = [];
    for (const file of workflowLogs.slice(-30)) { // Last 30 days
      try {
        const content = await fs.readFile(path.join(LOGS_DIR, file), 'utf8');
        const logs = JSON.parse(content);
        const workflowExecutions = logs.filter(log => log.workflowId === id);
        executions.push(...workflowExecutions);
      } catch (error) {
        // Skip invalid log files
      }
    }
    
    executions.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    res.json({ executions: executions.slice(0, 50) }); // Last 50 executions
  } catch (error) {
    console.error('Failed to get workflow executions:', error);
    res.status(500).json({ error: 'Failed to get workflow executions' });
  }
});


// Serve React app for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../dashboard/build/index.html'));
});

// WebSocket upgrade
server.on('upgrade', (request, socket, head) => {
  const pathname = new URL(request.url, `http://${request.headers.host}`).pathname;
  
  if (pathname === '/terminal') {
    wss.handleUpgrade(request, socket, head, (ws) => {
      handleTerminalConnection(ws, request);
    });
  } else {
    wss.handleUpgrade(request, socket, head, (ws) => {
      wss.emit('connection', ws, request);
    });
  }
});

// Terminal WebSocket handler
function handleTerminalConnection(ws, request) {
  const sessionId = Date.now().toString();
  const shell = process.env.SHELL || 'bash';
  
  const ptyProcess = pty.spawn(shell, [], {
    name: 'xterm-color',
    cols: 80,
    rows: 30,
    cwd: process.env.HOME,
    env: { ...process.env, TERM: 'xterm-color' }
  });
  
  terminalSessions.set(sessionId, ptyProcess);
  
  console.log(`Terminal session ${sessionId} started`);
  
  // Send data from pty to client
  ptyProcess.onData((data) => {
    ws.send(data);
  });
  
  // Handle client messages
  ws.on('message', (msg) => {
    try {
      const message = msg.toString();
      // Check if it's a resize command
      if (message.startsWith('{')) {
        try {
          const data = JSON.parse(message);
          if (data.type === 'resize' && data.cols && data.rows) {
            ptyProcess.resize(data.cols, data.rows);
          }
        } catch {
          // Not JSON, treat as terminal input
          ptyProcess.write(message);
        }
      } else {
        ptyProcess.write(message);
      }
    } catch (error) {
      console.error('Terminal error:', error);
    }
  });
  
  // Clean up on disconnect
  ws.on('close', () => {
    console.log(`Terminal session ${sessionId} closed`);
    ptyProcess.kill();
    terminalSessions.delete(sessionId);
  });
  
  ws.on('error', (error) => {
    console.error(`Terminal session ${sessionId} error:`, error);
    ptyProcess.kill();
    terminalSessions.delete(sessionId);
  });
}

// General WebSocket connection handler
wss.on('connection', (ws) => {
  console.log('New WebSocket connection');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      // Handle incoming messages if needed
      console.log('WebSocket message:', data);
    } catch (error) {
      console.error('WebSocket message error:', error);
    }
  });
  
  // Send initial status
  ws.send(JSON.stringify({ 
    type: 'connected', 
    timestamp: new Date().toISOString() 
  }));
  
  // Keep alive
  const interval = setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'ping', timestamp: new Date().toISOString() }));
    }
  }, 30000);
  
  ws.on('close', () => {
    clearInterval(interval);
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  
  // Kill all terminal sessions
  terminalSessions.forEach((pty, id) => {
    pty.kill();
  });
  
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});