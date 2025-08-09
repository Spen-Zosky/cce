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