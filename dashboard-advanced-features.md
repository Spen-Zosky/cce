# Advanced Dashboard Features - Implementation Instructions

## Overview
This guide implements 5 advanced features that will transform the CCE Dashboard into a top-grade professional development environment.

## Feature 1: Command Palette (Cmd+K)

### Step 1: Install Additional Dependencies
```bash
cd ~/.cce-universal/web/dashboard
npm install fuse.js react-hotkeys-hook @headlessui/react
```

### Step 2: Create Command Palette Component

Create `~/.cce-universal/web/dashboard/src/components/CommandPalette.tsx`:

```typescript
import React, { useState, useEffect, useMemo } from 'react';
import { useHotkeys } from 'react-hotkeys-hook';
import Fuse from 'fuse.js';
import { Transition } from '@headlessui/react';
import { useMutation } from '@tanstack/react-query';
import axios from 'axios';
import {
  Search,
  Plus,
  Bot,
  Terminal,
  FolderOpen,
  GitBranch,
  FileText,
  Settings,
  RefreshCw,
  Package,
  Code,
  Play,
  Hash,
  Command
} from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

interface CommandItem {
  id: string;
  title: string;
  description?: string;
  icon: any;
  category: string;
  shortcut?: string;
  action: () => void | Promise<void>;
}

interface CommandPaletteProps {
  onNavigate: (tab: string) => void;
}

export const CommandPalette: React.FC<CommandPaletteProps> = ({ onNavigate }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);

  // Hotkey to open/close
  useHotkeys('cmd+k, ctrl+k', (e) => {
    e.preventDefault();
    setIsOpen(!isOpen);
  }, { enableOnFormTags: true });

  // Close on Escape
  useHotkeys('esc', () => {
    if (isOpen) {
      setIsOpen(false);
      setSearch('');
    }
  }, { enableOnFormTags: true, enabled: isOpen });

  // Navigation with arrow keys
  useHotkeys('up', () => {
    setSelectedIndex(prev => Math.max(0, prev - 1));
  }, { enabled: isOpen });

  useHotkeys('down', () => {
    setSelectedIndex(prev => Math.min(filteredCommands.length - 1, prev + 1));
  }, { enabled: isOpen });

  // Execute on Enter
  useHotkeys('enter', () => {
    if (isOpen && filteredCommands[selectedIndex]) {
      executeCommand(filteredCommands[selectedIndex]);
    }
  }, { enabled: isOpen });

  // API Mutations
  const createProjectMutation = useMutation({
    mutationFn: async (type: string) => {
      const { data } = await axios.post(`${API_BASE}/projects/create`, {
        name: `project-${Date.now()}`,
        type
      });
      return data;
    }
  });

  const runAgentMutation = useMutation({
    mutationFn: async (agent: string) => {
      const { data } = await axios.post(`${API_BASE}/agents/execute`, {
        agent,
        args: ''
      });
      return data;
    }
  });

  // Command definitions
  const commands: CommandItem[] = useMemo(() => [
    // Navigation
    {
      id: 'nav-status',
      title: 'Go to System Status',
      icon: Hash,
      category: 'Navigation',
      shortcut: '1',
      action: () => {
        onNavigate('status');
        setIsOpen(false);
      }
    },
    {
      id: 'nav-mcp',
      title: 'Go to MCP Servers',
      icon: Package,
      category: 'Navigation',
      shortcut: '2',
      action: () => {
        onNavigate('mcp');
        setIsOpen(false);
      }
    },
    {
      id: 'nav-projects',
      title: 'Go to Projects',
      icon: FolderOpen,
      category: 'Navigation',
      shortcut: '3',
      action: () => {
        onNavigate('projects');
        setIsOpen(false);
      }
    },
    {
      id: 'nav-agents',
      title: 'Go to AI Agents',
      icon: Bot,
      category: 'Navigation',
      shortcut: '4',
      action: () => {
        onNavigate('agents');
        setIsOpen(false);
      }
    },
    
    // Project Actions
    {
      id: 'create-project',
      title: 'Create New Project',
      description: 'Create a new CCE project',
      icon: Plus,
      category: 'Projects',
      shortcut: 'cmd+n',
      action: async () => {
        await createProjectMutation.mutateAsync('basic');
        setIsOpen(false);
      }
    },
    {
      id: 'create-super-project',
      title: 'Create Super Project',
      description: 'Create a full-stack project with all features',
      icon: Plus,
      category: 'Projects',
      action: async () => {
        await createProjectMutation.mutateAsync('super');
        setIsOpen(false);
      }
    },
    
    // Agent Actions
    {
      id: 'run-coder',
      title: 'Run Coder Agent',
      description: 'Write code for a specific task',
      icon: Code,
      category: 'Agents',
      action: async () => {
        await runAgentMutation.mutateAsync('coder');
        setIsOpen(false);
      }
    },
    {
      id: 'run-reviewer',
      title: 'Run Code Review',
      description: 'Review current project code',
      icon: FileText,
      category: 'Agents',
      action: async () => {
        await runAgentMutation.mutateAsync('reviewer');
        setIsOpen(false);
      }
    },
    {
      id: 'run-tester',
      title: 'Run Test Generator',
      description: 'Generate tests for current project',
      icon: Play,
      category: 'Agents',
      action: async () => {
        await runAgentMutation.mutateAsync('tester');
        setIsOpen(false);
      }
    },
    {
      id: 'run-debugger',
      title: 'Run Debugger',
      description: 'Debug issues in current project',
      icon: Terminal,
      category: 'Agents',
      action: async () => {
        await runAgentMutation.mutateAsync('debugger');
        setIsOpen(false);
      }
    },
    
    // System Actions
    {
      id: 'refresh-dashboard',
      title: 'Refresh Dashboard',
      description: 'Reload all dashboard data',
      icon: RefreshCw,
      category: 'System',
      shortcut: 'cmd+r',
      action: () => {
        window.location.reload();
      }
    },
    {
      id: 'open-terminal',
      title: 'Open Terminal',
      description: 'Open web terminal',
      icon: Terminal,
      category: 'System',
      shortcut: 'cmd+`',
      action: () => {
        // Will be implemented with web terminal
        console.log('Opening terminal...');
        setIsOpen(false);
      }
    },
    {
      id: 'open-settings',
      title: 'Open Settings',
      icon: Settings,
      category: 'System',
      shortcut: 'cmd+,',
      action: () => {
        // Trigger settings modal
        setIsOpen(false);
      }
    },
    
    // Git Actions
    {
      id: 'git-status',
      title: 'Git Status',
      description: 'Check git status of current project',
      icon: GitBranch,
      category: 'Git',
      action: () => {
        console.log('Checking git status...');
        setIsOpen(false);
      }
    },
    {
      id: 'git-commit',
      title: 'Git Commit',
      description: 'Commit current changes',
      icon: GitBranch,
      category: 'Git',
      action: () => {
        console.log('Opening commit dialog...');
        setIsOpen(false);
      }
    }
  ], [onNavigate, createProjectMutation, runAgentMutation]);

  // Fuzzy search
  const fuse = useMemo(() => new Fuse(commands, {
    keys: ['title', 'description', 'category'],
    threshold: 0.3
  }), [commands]);

  const filteredCommands = useMemo(() => {
    if (!search) {
      return commands;
    }
    return fuse.search(search).map(result => result.item);
  }, [search, commands, fuse]);

  // Reset selected index when search changes
  useEffect(() => {
    setSelectedIndex(0);
  }, [search]);

  const executeCommand = (command: CommandItem) => {
    command.action();
  };

  return (
    <Transition show={isOpen} as={React.Fragment}>
      <div className="command-palette-overlay" onClick={() => setIsOpen(false)}>
        <Transition.Child
          as={React.Fragment}
          enter="ease-out duration-200"
          enterFrom="opacity-0 scale-95"
          enterTo="opacity-100 scale-100"
          leave="ease-in duration-150"
          leaveFrom="opacity-100 scale-100"
          leaveTo="opacity-0 scale-95"
        >
          <div 
            className="command-palette-container"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Search Input */}
            <div className="command-palette-header">
              <Search size={20} className="text-muted" />
              <input
                type="text"
                placeholder="Type a command or search..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="command-palette-input"
                autoFocus
              />
              <div className="command-palette-shortcut">
                <Command size={14} />
                <span>K</span>
              </div>
            </div>

            {/* Commands List */}
            <div className="command-palette-list">
              {filteredCommands.length === 0 ? (
                <div className="command-palette-empty">
                  No commands found for "{search}"
                </div>
              ) : (
                <>
                  {Object.entries(
                    filteredCommands.reduce((acc, cmd) => {
                      if (!acc[cmd.category]) acc[cmd.category] = [];
                      acc[cmd.category].push(cmd);
                      return acc;
                    }, {} as Record<string, CommandItem[]>)
                  ).map(([category, categoryCommands]) => (
                    <div key={category}>
                      <div className="command-palette-category">{category}</div>
                      {categoryCommands.map((command, index) => {
                        const Icon = command.icon;
                        const globalIndex = filteredCommands.indexOf(command);
                        return (
                          <button
                            key={command.id}
                            className={`command-palette-item ${
                              globalIndex === selectedIndex ? 'selected' : ''
                            }`}
                            onClick={() => executeCommand(command)}
                            onMouseEnter={() => setSelectedIndex(globalIndex)}
                          >
                            <Icon size={18} className="text-muted" />
                            <div className="command-palette-item-content">
                              <div className="command-palette-item-title">
                                {command.title}
                              </div>
                              {command.description && (
                                <div className="command-palette-item-description">
                                  {command.description}
                                </div>
                              )}
                            </div>
                            {command.shortcut && (
                              <div className="command-palette-shortcut small">
                                {command.shortcut}
                              </div>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  ))}
                </>
              )}
            </div>
          </div>
        </Transition.Child>
      </div>
    </Transition>
  );
};
```

### Step 3: Add Command Palette Styles

Add to `~/.cce-universal/web/dashboard/src/styles/tailwind-compat.css`:

```css
/* Command Palette Styles */
.command-palette-overlay {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 10vh;
  z-index: 1000;
}

.command-palette-container {
  width: 90%;
  max-width: 600px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 0.75rem;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  overflow: hidden;
}

.command-palette-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  border-bottom: 1px solid var(--color-border);
}

.command-palette-input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  font-size: 1rem;
  color: var(--color-text-primary);
}

.command-palette-shortcut {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.5rem;
  background-color: var(--color-surface-hover);
  border-radius: 0.25rem;
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.command-palette-list {
  max-height: 400px;
  overflow-y: auto;
  padding: 0.5rem;
}

.command-palette-category {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text-muted);
  padding: 0.5rem 0.75rem;
  margin-top: 0.5rem;
}

.command-palette-category:first-child {
  margin-top: 0;
}

.command-palette-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.75rem;
  border: none;
  background: transparent;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.15s;
  text-align: left;
}

.command-palette-item:hover,
.command-palette-item.selected {
  background-color: var(--color-surface-hover);
}

.command-palette-item.selected {
  box-shadow: inset 0 0 0 1px var(--color-primary);
}

.command-palette-item-content {
  flex: 1;
  min-width: 0;
}

.command-palette-item-title {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.command-palette-item-description {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.command-palette-empty {
  text-align: center;
  padding: 3rem;
  color: var(--color-text-muted);
}

.command-palette-shortcut.small {
  font-size: 0.6875rem;
  padding: 0.125rem 0.375rem;
}
```

## Feature 2: Web Terminal Integration

### Step 1: Install Terminal Dependencies
```bash
cd ~/.cce-universal/web/dashboard
npm install xterm xterm-addon-fit xterm-addon-web-links
```

### Step 2: Create Terminal Component

Create `~/.cce-universal/web/dashboard/src/components/Terminal.tsx`:

```typescript
import React, { useEffect, useRef, useState } from 'react';
import { Terminal as XTerm } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import { WebLinksAddon } from 'xterm-addon-web-links';
import { X, Maximize2, Minimize2, Terminal as TerminalIcon } from 'lucide-react';
import 'xterm/css/xterm.css';

interface TerminalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const Terminal: React.FC<TerminalProps> = ({ isOpen, onClose }) => {
  const terminalRef = useRef<HTMLDivElement>(null);
  const xtermRef = useRef<XTerm | null>(null);
  const fitAddonRef = useRef<FitAddon | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const [isMaximized, setIsMaximized] = useState(false);

  useEffect(() => {
    if (!isOpen || !terminalRef.current || xtermRef.current) return;

    // Create terminal instance
    const term = new XTerm({
      theme: {
        background: getComputedStyle(document.documentElement)
          .getPropertyValue('--color-background'),
        foreground: getComputedStyle(document.documentElement)
          .getPropertyValue('--color-text-primary'),
        cursor: getComputedStyle(document.documentElement)
          .getPropertyValue('--color-primary'),
        selection: getComputedStyle(document.documentElement)
          .getPropertyValue('--color-primary') + '40',
      },
      fontFamily: 'JetBrains Mono, Consolas, monospace',
      fontSize: 14,
      cursorBlink: true,
      convertEol: true,
    });

    // Add addons
    const fitAddon = new FitAddon();
    const webLinksAddon = new WebLinksAddon();
    
    term.loadAddon(fitAddon);
    term.loadAddon(webLinksAddon);
    
    // Open terminal in container
    term.open(terminalRef.current);
    fitAddon.fit();

    // Store references
    xtermRef.current = term;
    fitAddonRef.current = fitAddon;

    // Connect to WebSocket for terminal backend
    const ws = new WebSocket('ws://localhost:3456/terminal');
    wsRef.current = ws;

    ws.onopen = () => {
      term.writeln('Welcome to CCE Terminal');
      term.writeln('');
      term.write('$ ');
    };

    ws.onmessage = (event) => {
      term.write(event.data);
    };

    ws.onerror = (error) => {
      term.writeln('\r\nConnection error. Terminal backend not available.');
      term.writeln('Please ensure the terminal server is running.');
    };

    // Handle terminal input
    term.onData((data) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(data);
      }
    });

    // Handle resize
    const handleResize = () => {
      fitAddon.fit();
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'resize',
          cols: term.cols,
          rows: term.rows
        }));
      }
    };

    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      ws.close();
      term.dispose();
      xtermRef.current = null;
      fitAddonRef.current = null;
      wsRef.current = null;
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className={`terminal-container ${isMaximized ? 'maximized' : ''}`}>
      <div className="terminal-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <TerminalIcon size={16} />
          <span className="font-medium">Terminal</span>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button
            className="btn btn-ghost btn-icon"
            onClick={() => setIsMaximized(!isMaximized)}
          >
            {isMaximized ? <Minimize2 size={16} /> : <Maximize2 size={16} />}
          </button>
          <button
            className="btn btn-ghost btn-icon"
            onClick={onClose}
          >
            <X size={16} />
          </button>
        </div>
      </div>
      <div className="terminal-body" ref={terminalRef} />
    </div>
  );
};
```

### Step 3: Add Terminal Styles

Add to CSS:

```css
/* Terminal Styles */
.terminal-container {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 400px;
  background-color: var(--color-surface);
  border-top: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  z-index: 999;
  transition: all 0.2s;
}

.terminal-container.maximized {
  height: calc(100vh - 60px);
  top: 60px;
}

.terminal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--color-border);
  background-color: var(--color-surface-hover);
}

.terminal-body {
  flex: 1;
  padding: 0.5rem;
  overflow: hidden;
}

.terminal-body .xterm {
  height: 100%;
}
```

### Step 4: Update Server for Terminal Support

Add to `~/.cce-universal/web/server/index.js`:

```javascript
const pty = require('node-pty');

// Terminal WebSocket handler
wss.on('connection', (ws, request) => {
  if (request.url === '/terminal') {
    const shell = process.env.SHELL || 'bash';
    const ptyProcess = pty.spawn(shell, [], {
      name: 'xterm-color',
      cols: 80,
      rows: 30,
      cwd: process.env.HOME,
      env: process.env
    });

    ptyProcess.on('data', (data) => {
      ws.send(data);
    });

    ws.on('message', (msg) => {
      try {
        const data = JSON.parse(msg);
        if (data.type === 'resize') {
          ptyProcess.resize(data.cols, data.rows);
        }
      } catch {
        ptyProcess.write(msg);
      }
    });

    ws.on('close', () => {
      ptyProcess.kill();
    });
  }
});
```

## Feature 3: AI Assistant Panel

### Step 1: Create AI Assistant Component

Create `~/.cce-universal/web/dashboard/src/components/AIAssistant.tsx`:

```typescript
import React, { useState, useRef, useEffect } from 'react';
import { useMutation } from '@tanstack/react-query';
import axios from 'axios';
import { Send, Bot, User, Loader, X, Maximize2, Minimize2 } from 'lucide-react';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface AIAssistantProps {
  isOpen: boolean;
  onClose: () => void;
  context?: any;
}

export const AIAssistant: React.FC<AIAssistantProps> = ({ isOpen, onClose, context }) => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isMinimized, setIsMinimized] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessageMutation = useMutation({
    mutationFn: async (message: string) => {
      const { data } = await axios.post('/api/v1/ai/chat', {
        message,
        context,
        history: messages
      });
      return data;
    },
    onSuccess: (data) => {
      setMessages(prev => [...prev, {
        id: Date.now().toString(),
        role: 'assistant',
        content: data.response,
        timestamp: new Date()
      }]);
    }
  });

  const handleSend = () => {
    if (!input.trim() || sendMessageMutation.isPending) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    sendMessageMutation.mutate(input);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  if (!isOpen) return null;

  return (
    <div className={`ai-assistant-container ${isMinimized ? 'minimized' : ''}`}>
      <div className="ai-assistant-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Bot size={18} />
          <span className="font-medium">Claude Assistant</span>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button
            className="btn btn-ghost btn-icon"
            onClick={() => setIsMinimized(!isMinimized)}
          >
            {isMinimized ? <Maximize2 size={16} /> : <Minimize2 size={16} />}
          </button>
          <button
            className="btn btn-ghost btn-icon"
            onClick={onClose}
          >
            <X size={16} />
          </button>
        </div>
      </div>

      {!isMinimized && (
        <>
          <div className="ai-assistant-messages">
            {messages.length === 0 ? (
              <div className="ai-assistant-empty">
                <Bot size={48} className="text-muted" style={{ marginBottom: '1rem' }} />
                <p className="text-muted">Hi! I'm Claude, your AI assistant.</p>
                <p className="text-muted text-sm">Ask me anything about your projects or development tasks.</p>
              </div>
            ) : (
              messages.map((message) => (
                <div
                  key={message.id}
                  className={`ai-assistant-message ${message.role}`}
                >
                  <div className="ai-assistant-message-icon">
                    {message.role === 'user' ? (
                      <User size={16} />
                    ) : (
                      <Bot size={16} />
                    )}
                  </div>
                  <div className="ai-assistant-message-content">
                    <div className="ai-assistant-message-text">
                      {message.content}
                    </div>
                    <div className="ai-assistant-message-time">
                      {message.timestamp.toLocaleTimeString()}
                    </div>
                  </div>
                </div>
              ))
            )}
            {sendMessageMutation.isPending && (
              <div className="ai-assistant-message assistant">
                <div className="ai-assistant-message-icon">
                  <Bot size={16} />
                </div>
                <div className="ai-assistant-message-content">
                  <Loader size={16} className="animate-spin" />
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <div className="ai-assistant-input">
            <textarea
              ref={inputRef}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Ask me anything..."
              className="ai-assistant-textarea"
              rows={2}
            />
            <button
              className="btn btn-primary btn-icon"
              onClick={handleSend}
              disabled={!input.trim() || sendMessageMutation.isPending}
            >
              <Send size={18} />
            </button>
          </div>
        </>
      )}
    </div>
  );
};
```

### Step 2: Add AI Assistant Styles

```css
/* AI Assistant Styles */
.ai-assistant-container {
  position: fixed;
  right: 1rem;
  bottom: 1rem;
  width: 400px;
  height: 600px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 0.75rem;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  z-index: 998;
  transition: all 0.2s;
}

.ai-assistant-container.minimized {
  height: auto;
}

.ai-assistant-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem;
  border-bottom: 1px solid var(--color-border);
}

.ai-assistant-messages {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
}

.ai-assistant-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  text-align: center;
  padding: 2rem;
}

.ai-assistant-message {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.ai-assistant-message.user {
  flex-direction: row-reverse;
}

.ai-assistant-message-icon {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.ai-assistant-message.user .ai-assistant-message-icon {
  background-color: var(--color-primary);
  color: white;
}

.ai-assistant-message.assistant .ai-assistant-message-icon {
  background-color: var(--color-surface-hover);
  color: var(--color-text-primary);
}

.ai-assistant-message-content {
  max-width: 80%;
}

.ai-assistant-message-text {
  background-color: var(--color-surface-hover);
  padding: 0.75rem 1rem;
  border-radius: 0.75rem;
  font-size: 0.875rem;
  line-height: 1.5;
}

.ai-assistant-message.user .ai-assistant-message-text {
  background-color: var(--color-primary);
  color: white;
}

.ai-assistant-message-time {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.25rem;
  text-align: right;
}

.ai-assistant-message.assistant .ai-assistant-message-time {
  text-align: left;
}

.ai-assistant-input {
  display: flex;
  gap: 0.75rem;
  padding: 1rem;
  border-top: 1px solid var(--color-border);
}

.ai-assistant-textarea {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid var(--color-border);
  border-radius: 0.5rem;
  background-color: var(--color-background);
  color: var(--color-text-primary);
  font-size: 0.875rem;
  resize: none;
  outline: none;
}

.ai-assistant-textarea:focus {
  border-color: var(--color-primary);
}
```

## Feature 4: Analytics Dashboard

### Step 1: Create Analytics Component

Create `~/.cce-universal/web/dashboard/src/components/Analytics.tsx`:

```typescript
import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import {
  Activity,
  TrendingUp,
  Clock,
  BarChart3,
  PieChart,
  Calendar,
  Target,
  Zap
} from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

export const Analytics: React.FC = () => {
  const [timeRange, setTimeRange] = useState('week');

  const { data: analyticsData, isLoading } = useQuery({
    queryKey: ['analytics', timeRange],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/analytics`, {
        params: { range: timeRange }
      });
      return data;
    }
  });

  const { data: performanceData } = useQuery({
    queryKey: ['performance', timeRange],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/analytics/performance`, {
        params: { range: timeRange }
      });
      return data;
    }
  });

  if (isLoading) {
    return <div>Loading analytics...</div>;
  }

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <h2 className="text-primary font-semibold mb-2" style={{ fontSize: '1.875rem' }}>
          Analytics & Insights
        </h2>
        <p className="text-secondary">
          Track your development productivity and system performance
        </p>
      </div>

      {/* Time Range Selector */}
      <div style={{ 
        display: 'flex', 
        gap: '0.5rem', 
        marginBottom: '2rem',
        padding: '0.25rem',
        backgroundColor: 'var(--color-surface)',
        borderRadius: '0.5rem',
        width: 'fit-content'
      }}>
        {['day', 'week', 'month', 'year'].map(range => (
          <button
            key={range}
            className={`btn ${timeRange === range ? 'btn-primary' : 'btn-ghost'}`}
            onClick={() => setTimeRange(range)}
            style={{ textTransform: 'capitalize' }}
          >
            {range}
          </button>
        ))}
      </div>

      {/* Key Metrics */}
      <div className="grid gap-6 lg:grid-cols-4 md:grid-cols-2 mb-6">
        <MetricCard
          icon={Zap}
          label="Agent Executions"
          value={analyticsData?.agentExecutions || 0}
          change={`+${analyticsData?.agentExecutionsChange || 0}%`}
          trend="up"
        />
        <MetricCard
          icon={Clock}
          label="Avg Execution Time"
          value={`${analyticsData?.avgExecutionTime || 0}s`}
          change={`${analyticsData?.executionTimeChange || 0}%`}
          trend={analyticsData?.executionTimeChange < 0 ? 'up' : 'down'}
        />
        <MetricCard
          icon={Target}
          label="Success Rate"
          value={`${analyticsData?.successRate || 0}%`}
          change={`+${analyticsData?.successRateChange || 0}%`}
          trend="up"
        />
        <MetricCard
          icon={Activity}
          label="Active Projects"
          value={analyticsData?.activeProjects || 0}
          change={`${analyticsData?.activeProjectsChange || 0}`}
          trend="neutral"
        />
      </div>

      {/* Charts Grid */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Agent Usage Chart */}
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Agent Usage</h3>
            <BarChart3 size={20} className="text-muted" />
          </div>
          <div style={{ height: '300px', padding: '1rem' }}>
            {/* Chart implementation would go here */}
            <div className="chart-placeholder">
              <BarChart3 size={48} className="text-muted" />
              <p className="text-muted text-sm">Agent usage chart</p>
            </div>
          </div>
        </div>

        {/* Performance Trends */}
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Performance Trends</h3>
            <TrendingUp size={20} className="text-muted" />
          </div>
          <div style={{ height: '300px', padding: '1rem' }}>
            <div className="chart-placeholder">
              <TrendingUp size={48} className="text-muted" />
              <p className="text-muted text-sm">Performance trends</p>
            </div>
          </div>
        </div>

        {/* Project Activity */}
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Project Activity</h3>
            <Calendar size={20} className="text-muted" />
          </div>
          <div style={{ height: '300px', padding: '1rem' }}>
            <div className="chart-placeholder">
              <Calendar size={48} className="text-muted" />
              <p className="text-muted text-sm">Activity heatmap</p>
            </div>
          </div>
        </div>

        {/* Resource Usage */}
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Resource Usage</h3>
            <PieChart size={20} className="text-muted" />
          </div>
          <div style={{ height: '300px', padding: '1rem' }}>
            <div className="chart-placeholder">
              <PieChart size={48} className="text-muted" />
              <p className="text-muted text-sm">CPU, Memory, Disk usage</p>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity Table */}
      <div className="card" style={{ marginTop: '1.5rem' }}>
        <div className="card-header">
          <h3 className="card-title">Recent Activity</h3>
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table className="analytics-table">
            <thead>
              <tr>
                <th>Time</th>
                <th>Agent</th>
                <th>Project</th>
                <th>Duration</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {analyticsData?.recentActivity?.map((activity: any, index: number) => (
                <tr key={index}>
                  <td>{new Date(activity.timestamp).toLocaleString()}</td>
                  <td>{activity.agent}</td>
                  <td>{activity.project}</td>
                  <td>{activity.duration}s</td>
                  <td>
                    <span className={`status-badge ${activity.status}`}>
                      {activity.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

const MetricCard: React.FC<{
  icon: any;
  label: string;
  value: string | number;
  change: string;
  trend: 'up' | 'down' | 'neutral';
}> = ({ icon: Icon, label, value, change, trend }) => {
  const trendColor = trend === 'up' ? 'var(--color-success)' : 
                     trend === 'down' ? 'var(--color-error)' : 
                     'var(--color-text-muted)';

  return (
    <div className="metric-card">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Icon className="text-muted" size={20} strokeWidth={1.5} />
        <Activity size={16} className="text-muted" />
      </div>
      <div className="metric-value">{value}</div>
      <div className="metric-label">{label}</div>
      <div style={{ color: trendColor, fontSize: '0.875rem', fontWeight: 500 }}>
        {change}
      </div>
    </div>
  );
};
```

### Step 5: Add Analytics Styles

```css
/* Analytics Styles */
.chart-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--color-text-muted);
}

.analytics-table {
  width: 100%;
  border-collapse: collapse;
}

.analytics-table th {
  text-align: left;
  padding: 0.75rem 1rem;
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  border-bottom: 1px solid var(--color-border);
}

.analytics-table td {
  padding: 0.75rem 1rem;
  font-size: 0.875rem;
  border-bottom: 1px solid var(--color-border);
}

.analytics-table tr:hover {
  background-color: var(--color-surface-hover);
}

.status-badge {
  display: inline-flex;
  align-items: center;
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 500;
}

.status-badge.success {
  background-color: var(--color-success) + '20';
  color: var(--color-success);
}

.status-badge.error {
  background-color: var(--color-error) + '20';
  color: var(--color-error);
}

.status-badge.pending {
  background-color: var(--color-warning) + '20';
  color: var(--color-warning);
}
```

## Feature 5: Visual Workflow Designer

### Step 1: Install Flow Dependencies
```bash
cd ~/.cce-universal/web/dashboard
npm install reactflow
```

### Step 2: Create Workflow Designer Component

Create `~/.cce-universal/web/dashboard/src/components/WorkflowDesigner.tsx`:

```typescript
import React, { useCallback, useState } from 'react';
import ReactFlow, {
  Node,
  Edge,
  addEdge,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
  Handle,
  Position,
  NodeProps,
} from 'reactflow';
import 'reactflow/dist/style.css';
import { Play, Save, Plus, Bot, Code, FileText, Bug, Package } from 'lucide-react';

const nodeTypes = {
  agent: AgentNode,
};

function AgentNode({ data }: NodeProps) {
  const getIcon = () => {
    switch (data.agentType) {
      case 'coder': return <Code size={20} />;
      case 'reviewer': return <FileText size={20} />;
      case 'tester': return <Play size={20} />;
      case 'debugger': return <Bug size={20} />;
      case 'deployer': return <Package size={20} />;
      default: return <Bot size={20} />;
    }
  };

  return (
    <div className="workflow-node">
      <Handle type="target" position={Position.Top} />
      <div className="workflow-node-content">
        <div className="workflow-node-icon">
          {getIcon()}
        </div>
        <div className="workflow-node-info">
          <div className="workflow-node-title">{data.label}</div>
          <div className="workflow-node-type">{data.agentType}</div>
        </div>
      </div>
      <Handle type="source" position={Position.Bottom} />
    </div>
  );
}

const initialNodes: Node[] = [
  {
    id: '1',
    type: 'agent',
    position: { x: 250, y: 0 },
    data: { label: 'Code Analysis', agentType: 'reviewer' },
  },
  {
    id: '2',
    type: 'agent',
    position: { x: 100, y: 100 },
    data: { label: 'Fix Issues', agentType: 'coder' },
  },
  {
    id: '3',
    type: 'agent',
    position: { x: 400, y: 100 },
    data: { label: 'Generate Tests', agentType: 'tester' },
  },
];

const initialEdges: Edge[] = [
  { id: 'e1-2', source: '1', target: '2' },
  { id: 'e1-3', source: '1', target: '3' },
];

export const WorkflowDesigner: React.FC = () => {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);
  const [selectedNode, setSelectedNode] = useState<Node | null>(null);

  const onConnect = useCallback(
    (params: any) => setEdges((eds) => addEdge(params, eds)),
    [setEdges]
  );

  const onNodeClick = useCallback((event: any, node: Node) => {
    setSelectedNode(node);
  }, []);

  const addNode = (agentType: string) => {
    const newNode: Node = {
      id: `${nodes.length + 1}`,
      type: 'agent',
      position: { x: 250, y: nodes.length * 100 },
      data: { label: `New ${agentType}`, agentType },
    };
    setNodes((nds) => nds.concat(newNode));
  };

  const runWorkflow = async () => {
    console.log('Running workflow:', { nodes, edges });
    // Implementation would execute agents in order based on edges
  };

  const saveWorkflow = () => {
    const workflow = { nodes, edges };
    localStorage.setItem('workflow', JSON.stringify(workflow));
  };

  return (
    <div style={{ height: '600px' }}>
      <div className="workflow-toolbar">
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button className="btn btn-primary" onClick={runWorkflow}>
            <Play size={16} />
            Run Workflow
          </button>
          <button className="btn btn-secondary" onClick={saveWorkflow}>
            <Save size={16} />
            Save
          </button>
        </div>
        
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button className="btn btn-ghost" onClick={() => addNode('coder')}>
            <Plus size={16} />
            Add Coder
          </button>
          <button className="btn btn-ghost" onClick={() => addNode('reviewer')}>
            <Plus size={16} />
            Add Reviewer
          </button>
          <button className="btn btn-ghost" onClick={() => addNode('tester')}>
            <Plus size={16} />
            Add Tester
          </button>
        </div>
      </div>

      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onNodeClick={onNodeClick}
        nodeTypes={nodeTypes}
        fitView
      >
        <Background />
        <Controls />
        <MiniMap />
      </ReactFlow>

      {selectedNode && (
        <div className="workflow-sidebar">
          <h3>Node Configuration</h3>
          <p>Type: {selectedNode.data.agentType}</p>
          <input
            type="text"
            value={selectedNode.data.label}
            onChange={(e) => {
              setNodes((nds) =>
                nds.map((node) =>
                  node.id === selectedNode.id
                    ? { ...node, data: { ...node.data, label: e.target.value } }
                    : node
                )
              );
            }}
            className="input"
            placeholder="Node label"
          />
        </div>
      )}
    </div>
  );
};
```

### Step 3: Add Workflow Styles

```css
/* Workflow Designer Styles */
.workflow-toolbar {
  display: flex;
  justify-content: space-between;
  padding: 1rem;
  background-color: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
}

.workflow-node {
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 0.5rem;
  padding: 0.75rem;
  min-width: 150px;
  box-shadow: 0 2px 4px var(--color-shadow);
}

.workflow-node-content {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.workflow-node-icon {
  width: 40px;
  height: 40px;
  border-radius: 0.375rem;
  background-color: var(--color-primary);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
}

.workflow-node-info {
  flex: 1;
}

.workflow-node-title {
  font-weight: 600;
  color: var(--color-text-primary);
}

.workflow-node-type {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.workflow-sidebar {
  position: absolute;
  right: 0;
  top: 0;
  width: 300px;
  height: 100%;
  background-color: var(--color-surface);
  border-left: 1px solid var(--color-border);
  padding: 1.5rem;
}
```

## Implementation Steps

1. **Update Dashboard Component** to include new features:

```typescript
// Add to Dashboard.tsx
import { CommandPalette } from './CommandPalette';
import { Terminal } from './Terminal';
import { AIAssistant } from './AIAssistant';
import { Analytics } from './Analytics';
import { WorkflowDesigner } from './WorkflowDesigner';

// Add state
const [showTerminal, setShowTerminal] = useState(false);
const [showAIAssistant, setShowAIAssistant] = useState(false);

// Add new tabs
const tabs = [
  // ... existing tabs
  { id: 'analytics', label: 'Analytics', icon: BarChart3 },
  { id: 'workflow', label: 'Workflows', icon: GitBranch },
];

// Add components
return (
  <>
    <CommandPalette onNavigate={setActiveTab} />
    <Terminal isOpen={showTerminal} onClose={() => setShowTerminal(false)} />
    <AIAssistant isOpen={showAIAssistant} onClose={() => setShowAIAssistant(false)} />
    
    {/* In main content */}
    {activeTab === 'analytics' && <Analytics />}
    {activeTab === 'workflow' && <WorkflowDesigner />}
  </>
);
```

2. **Add API endpoints** for new features
3. **Test each feature** individually
4. **Integrate with existing functionality**

## Benefits

1. **Command Palette**: 10x faster navigation and actions
2. **Web Terminal**: No need to switch to terminal app
3. **AI Assistant**: Context-aware help always available
4. **Analytics**: Data-driven development insights
5. **Workflow Designer**: Visual automation creation

These features transform the dashboard into a complete development command center!