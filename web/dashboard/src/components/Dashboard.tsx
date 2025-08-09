import React, { useState, useEffect } from 'react';
import SystemStatus from './SystemStatus';
import MCPServers from './MCPServers';
import Projects from './Projects';
import AgentRunner from './AgentRunner';
import Logs from './Logs';
import Settings from './Settings';
import { CommandPalette } from './CommandPalette';
import { Terminal } from './Terminal';
import { AIAssistant } from './AIAssistant';
import { Analytics } from './Analytics';
import { WorkflowDesigner } from './WorkflowDesigner';
import { Home, Server, FolderOpen, Bot, FileText, Moon, Sun, Settings as SettingsIcon, BarChart3, GitBranch, Terminal as TerminalIcon } from 'lucide-react';
import { useTheme } from '../contexts/ThemeContext';

const Dashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState('status');
  const [showSettings, setShowSettings] = useState(false);
  const [showTerminal, setShowTerminal] = useState(false);
  const [showAIAssistant, setShowAIAssistant] = useState(false);
  const [showCommandPalette, setShowCommandPalette] = useState(false);
  const { theme, toggleTheme } = useTheme();

  // Add keyboard shortcut for terminal
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === '`') {
        e.preventDefault();
        setShowTerminal(!showTerminal);
      }
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setShowCommandPalette(!showCommandPalette);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showTerminal, showCommandPalette]);

  // WebSocket connection
  useEffect(() => {
    const websocket = new WebSocket('ws://localhost:3456');
    
    websocket.onopen = () => {
      console.log('WebSocket connected');
    };

    websocket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      console.log('WebSocket message:', data);
    };

    websocket.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    return () => {
      websocket.close();
    };
  }, []);

  const tabs = [
    { id: 'status', label: 'System Status', icon: Home },
    { id: 'mcp', label: 'MCP Servers', icon: Server },
    { id: 'projects', label: 'Projects', icon: FolderOpen },
    { id: 'agents', label: 'Agents', icon: Bot },
    { id: 'analytics', label: 'Analytics', icon: BarChart3 },
    { id: 'workflow', label: 'Workflows', icon: GitBranch },
    { id: 'logs', label: 'Logs', icon: FileText },
  ];

  return (
    <div className="min-h-screen bg-secondary">
      {/* Theme Toggle */}
      <button
        onClick={toggleTheme}
        className="theme-toggle"
        aria-label="Toggle theme"
      >
        {theme === 'light' ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
      </button>

      <div className="flex h-screen">
        {/* Sidebar */}
        <div className="sidebar w-64">
          <div className="p-6">
            <h1 className="text-2xl font-bold text-primary">CCE Dashboard</h1>
            <p className="text-sm text-muted mt-1">v2.0.0 Pro</p>
          </div>
          
          <nav className="px-4">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`sidebar-nav-item w-full ${
                    activeTab === tab.id ? 'active' : ''
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
            
            {/* Quick Actions */}
            <div className="mt-6 pt-4 border-t border-primary">
              <button
                onClick={() => setShowTerminal(true)}
                className="sidebar-nav-item w-full mb-2"
              >
                <TerminalIcon className="w-5 h-5" />
                <span>Terminal</span>
              </button>
              <button
                onClick={() => setShowAIAssistant(true)}
                className="sidebar-nav-item w-full mb-2"
              >
                <Bot className="w-5 h-5" />
                <span>AI Assistant</span>
              </button>
            </div>
            
            {/* Settings Button */}
            <button
              onClick={() => setShowSettings(true)}
              className="sidebar-nav-item w-full mt-4"
            >
              <SettingsIcon className="w-5 h-5" />
              <span>Settings</span>
            </button>
          </nav>
        </div>

        {/* Main Content */}
        <div className="flex-1 overflow-auto bg-secondary">
          <div className="p-8">
            {activeTab === 'status' && <SystemStatus />}
            {activeTab === 'mcp' && <MCPServers />}
            {activeTab === 'projects' && <Projects />}
            {activeTab === 'agents' && <AgentRunner />}
            {activeTab === 'analytics' && <Analytics />}
            {activeTab === 'workflow' && <WorkflowDesigner />}
            {activeTab === 'logs' && <Logs />}
            
            {/* Settings Modal */}
            {showSettings && (
              <Settings 
                isOpen={showSettings}
                onClose={() => setShowSettings(false)}
              />
            )}
            
            {/* Advanced Features */}
            <CommandPalette onNavigate={(tab) => setActiveTab(tab)} />
            <Terminal isOpen={showTerminal} onClose={() => setShowTerminal(false)} />
            <AIAssistant 
              isOpen={showAIAssistant} 
              onClose={() => setShowAIAssistant(false)}
              context={{ activeTab, currentProject: null }}
            />
          </div>
        </div>
      </div>

      {/* Add floating buttons for Terminal and AI Assistant */}
      <div style={{
        position: 'fixed',
        bottom: '2rem',
        right: '2rem',
        display: 'flex',
        flexDirection: 'column',
        gap: '1rem',
        zIndex: 997
      }}>
        <button
          className="btn btn-primary"
          onClick={() => setShowAIAssistant(!showAIAssistant)}
          style={{
            width: '56px',
            height: '56px',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 6px var(--color-shadow)'
          }}
        >
          <Bot size={24} />
        </button>
        
        <button
          className="btn btn-primary"
          onClick={() => setShowTerminal(!showTerminal)}
          style={{
            width: '56px',
            height: '56px',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 6px var(--color-shadow)'
          }}
        >
          <TerminalIcon size={24} />
        </button>
      </div>
    </div>
  );
};

export default Dashboard;