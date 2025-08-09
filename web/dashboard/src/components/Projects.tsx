import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { 
  FolderOpen, 
  Package, 
  GitBranch,
  Plus,
  ExternalLink,
  Terminal,
  Code,
  FileText,
  Settings,
  Play,
  X,
  Loader
} from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

interface Project {
  name: string;
  path: string;
  hasClaude: boolean;
  hasPackageJson: boolean;
  description?: string;
  version?: string;
  gitStatus?: {
    hasChanges: boolean;
    changeCount: number;
  };
}

const Projects: React.FC = () => {
  const queryClient = useQueryClient();
  const [selectedProject, setSelectedProject] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newProjectName, setNewProjectName] = useState('');
  const [newProjectType, setNewProjectType] = useState('basic');
  const [gitOutput, setGitOutput] = useState<Record<string, string>>({});

  const { data, isLoading } = useQuery({
    queryKey: ['projects'],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/projects`);
      return data;
    },
  });

  const openProjectMutation = useMutation({
    mutationFn: async (projectPath: string) => {
      const { data } = await axios.post(`${API_BASE}/projects/open`, { path: projectPath });
      return data;
    },
    onSuccess: (data) => {
      console.log('Project opened:', data);
    }
  });

  const createProjectMutation = useMutation({
    mutationFn: async ({ name, type }: { name: string; type: string }) => {
      const { data } = await axios.post(`${API_BASE}/projects/create`, { name, type });
      return data;
    },
    onSuccess: () => {
      setShowCreateModal(false);
      setNewProjectName('');
      setNewProjectType('basic');
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    }
  });

  const runAgentMutation = useMutation({
    mutationFn: async ({ project, agent }: { project: string; agent: string }) => {
      const { data } = await axios.post(`${API_BASE}/agents/execute`, {
        agent,
        args: '',
        project
      });
      return data;
    }
  });

  const gitCommandMutation = useMutation({
    mutationFn: async ({ path, command }: { path: string; command: string }) => {
      const { data } = await axios.post(`${API_BASE}/projects/git`, { path, command });
      return data;
    },
    onSuccess: (data, variables) => {
      setGitOutput(prev => ({
        ...prev,
        [variables.path]: data.output
      }));
    }
  });

  const handleCreateProject = () => {
    if (newProjectName.trim()) {
      createProjectMutation.mutate({ 
        name: newProjectName.trim(), 
        type: newProjectType 
      });
    }
  };

  const handleOpenProject = (projectPath: string) => {
    openProjectMutation.mutate(projectPath);
  };

  const handleRunAgent = (projectPath: string, agent: string) => {
    runAgentMutation.mutate({ project: projectPath, agent });
  };

  const handleGitCommand = (projectPath: string, command: string) => {
    gitCommandMutation.mutate({ path: projectPath, command });
  };

  const CreateProjectModal = () => (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.5)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 1000
    }}>
      <div className="card" style={{
        width: '90%',
        maxWidth: '500px',
        padding: '2rem'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
          <h2 className="text-xl font-semibold">Create New Project</h2>
          <button 
            className="btn btn-ghost btn-icon" 
            onClick={() => setShowCreateModal(false)}
          >
            <X size={20} />
          </button>
        </div>

        <div style={{ marginBottom: '1.5rem' }}>
          <label className="text-sm font-medium text-secondary" style={{ display: 'block', marginBottom: '0.5rem' }}>
            Project Name
          </label>
          <input
            type="text"
            value={newProjectName}
            onChange={(e) => setNewProjectName(e.target.value)}
            placeholder="my-awesome-project"
            className="input"
            autoFocus
          />
        </div>

        <div style={{ marginBottom: '1.5rem' }}>
          <label className="text-sm font-medium text-secondary" style={{ display: 'block', marginBottom: '0.5rem' }}>
            Project Type
          </label>
          <div style={{ display: 'flex', gap: '1rem' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <input
                type="radio"
                value="basic"
                checked={newProjectType === 'basic'}
                onChange={(e) => setNewProjectType(e.target.value)}
              />
              <span>Basic</span>
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <input
                type="radio"
                value="super"
                checked={newProjectType === 'super'}
                onChange={(e) => setNewProjectType(e.target.value)}
              />
              <span>Super (Full-stack)</span>
            </label>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '1rem', justifyContent: 'flex-end' }}>
          <button 
            className="btn btn-secondary" 
            onClick={() => setShowCreateModal(false)}
          >
            Cancel
          </button>
          <button 
            className="btn btn-primary" 
            onClick={handleCreateProject}
            disabled={!newProjectName.trim() || createProjectMutation.isPending}
          >
            {createProjectMutation.isPending ? (
              <>
                <Loader size={16} className="animate-spin" />
                Creating...
              </>
            ) : (
              'Create Project'
            )}
          </button>
        </div>
      </div>
    </div>
  );

  if (isLoading) {
    return (
      <div>
        <h2 className="text-primary font-semibold mb-6" style={{ fontSize: '1.875rem' }}>
          Projects
        </h2>
        <div className="grid gap-4 lg:grid-cols-3 md:grid-cols-2">
          {[1, 2, 3].map(i => (
            <div key={i} className="card skeleton" style={{ height: '180px' }} />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <h2 className="text-primary font-semibold mb-2" style={{ fontSize: '1.875rem' }}>
          Projects
        </h2>
        <p className="text-secondary">
          Manage your CCE-enabled projects and quickly access development tools
        </p>
      </div>

      {/* Project Grid */}
      <div className="grid gap-4 lg:grid-cols-3 md:grid-cols-2">
        {/* Create New Project Card */}
        <button
          className="card"
          onClick={() => setShowCreateModal(true)}
          style={{
            border: '2px dashed var(--color-border)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '200px',
            cursor: 'pointer',
            transition: 'all 0.2s'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.borderColor = 'var(--color-primary)';
            e.currentTarget.style.backgroundColor = 'var(--color-surface-hover)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.borderColor = 'var(--color-border)';
            e.currentTarget.style.backgroundColor = 'var(--color-surface)';
          }}
        >
          <div style={{
            width: '48px',
            height: '48px',
            borderRadius: '50%',
            backgroundColor: 'var(--color-primary)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: '1rem'
          }}>
            <Plus size={24} color="white" strokeWidth={2} />
          </div>
          <p className="font-semibold text-primary">Create New Project</p>
          <p className="text-sm text-muted" style={{ marginTop: '0.5rem' }}>
            Start a new CCE project
          </p>
        </button>

        {/* Existing Projects */}
        {data?.projects?.map((project: Project) => (
          <div key={project.name} className="card" style={{ position: 'relative' }}>
            {/* Status Indicators */}
            <div style={{
              position: 'absolute',
              top: '1rem',
              right: '1rem',
              display: 'flex',
              gap: '0.5rem',
              alignItems: 'center'
            }}>
              {project.hasClaude && (
                <div 
                  className="status-dot status-success" 
                  title="CCE Enabled"
                  style={{ width: '8px', height: '8px' }}
                />
              )}
              {project.hasPackageJson && (
                <div title="Node.js Project">
                  <Package size={16} className="text-muted" />
                </div>
              )}
              {project.gitStatus?.hasChanges && (
                <div style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '0.25rem',
                  fontSize: '0.75rem',
                  color: 'var(--color-warning)'
                }}>
                  <GitBranch size={14} />
                  <span>{project.gitStatus.changeCount}</span>
                </div>
              )}
            </div>

            {/* Project Icon */}
            <div style={{
              width: '40px',
              height: '40px',
              borderRadius: '0.5rem',
              backgroundColor: 'var(--color-surface-hover)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '1rem'
            }}>
              <FolderOpen size={20} className="text-primary" strokeWidth={1.5} />
            </div>

            {/* Project Info */}
            <h3 className="font-semibold text-primary" style={{ marginBottom: '0.5rem' }}>
              {project.name}
            </h3>
            {project.description && (
              <p className="text-sm text-secondary" style={{ marginBottom: '1rem' }}>
                {project.description}
              </p>
            )}
            {project.version && (
              <p className="text-xs text-muted" style={{ marginBottom: '1rem' }}>
                v{project.version}
              </p>
            )}

            {/* Action Buttons */}
            <div style={{ display: 'flex', gap: '0.5rem', marginTop: 'auto' }}>
              <button
                className="btn btn-primary btn-sm"
                onClick={() => handleOpenProject(project.path)}
                style={{ flex: 1 }}
                disabled={openProjectMutation.isPending}
              >
                <ExternalLink size={14} />
                Open
              </button>
              
              <div style={{ position: 'relative' }}>
                <button
                  className="btn btn-secondary btn-icon"
                  onClick={() => setSelectedProject(
                    selectedProject === project.name ? null : project.name
                  )}
                  title="More actions"
                >
                  <Settings size={14} />
                </button>
                
                {/* Dropdown Menu */}
                {selectedProject === project.name && (
                  <div style={{
                    position: 'absolute',
                    top: '100%',
                    right: 0,
                    marginTop: '0.25rem',
                    backgroundColor: 'var(--color-surface)',
                    border: '1px solid var(--color-border)',
                    borderRadius: '0.5rem',
                    boxShadow: '0 4px 6px var(--color-shadow)',
                    minWidth: '160px',
                    zIndex: 10
                  }}>
                    <button
                      className="dropdown-item"
                      onClick={() => handleRunAgent(project.path, 'coder')}
                      disabled={runAgentMutation.isPending}
                    >
                      <Code size={14} />
                      Run Coder
                    </button>
                    <button
                      className="dropdown-item"
                      onClick={() => handleRunAgent(project.path, 'reviewer')}
                      disabled={runAgentMutation.isPending}
                    >
                      <FileText size={14} />
                      Run Review
                    </button>
                    <button
                      className="dropdown-item"
                      onClick={() => handleRunAgent(project.path, 'tester')}
                      disabled={runAgentMutation.isPending}
                    >
                      <Play size={14} />
                      Run Tests
                    </button>
                    <div style={{ 
                      height: '1px', 
                      backgroundColor: 'var(--color-border)',
                      margin: '0.25rem 0'
                    }} />
                    <button
                      className="dropdown-item"
                      onClick={() => {
                        const terminalCommand = process.platform === 'win32' 
                          ? `start cmd /k "cd /d ${project.path}"` 
                          : `gnome-terminal --working-directory="${project.path}"`;
                        
                        // Use the terminal in dashboard instead
                        console.log('Open terminal in:', project.path);
                      }}
                    >
                      <Terminal size={14} />
                      Open Terminal
                    </button>
                    <button
                      className="dropdown-item"
                      onClick={() => handleGitCommand(project.path, 'status')}
                    >
                      <GitBranch size={14} />
                      Git Status
                    </button>
                  </div>
                )}
              </div>
            </div>

            {/* Git Output */}
            {gitOutput[project.path] && (
              <div style={{
                marginTop: '1rem',
                padding: '0.75rem',
                backgroundColor: 'var(--color-surface-hover)',
                borderRadius: '0.375rem',
                fontSize: '0.75rem',
                fontFamily: 'monospace',
                maxHeight: '100px',
                overflowY: 'auto'
              }}>
                <pre style={{ margin: 0 }}>{gitOutput[project.path]}</pre>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Create Project Modal */}
      {showCreateModal && <CreateProjectModal />}
    </div>
  );
};

// Add dropdown item styles
const styles = `
.dropdown-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
  padding: 0.5rem 0.75rem;
  border: none;
  background: transparent;
  color: var(--color-text-secondary);
  font-size: 0.875rem;
  text-align: left;
  cursor: pointer;
  transition: all 0.2s;
}

.dropdown-item:hover {
  background-color: var(--color-surface-hover);
  color: var(--color-text-primary);
}

.dropdown-item:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-sm {
  padding: 0.375rem 0.75rem;
  font-size: 0.8125rem;
}

.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
`;

// Add styles to document
if (typeof document !== 'undefined') {
  const styleSheet = document.createElement('style');
  styleSheet.textContent = styles;
  document.head.appendChild(styleSheet);
}

export default Projects;