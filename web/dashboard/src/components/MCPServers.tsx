import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { 
  Server,
  Play,
  Download,
  CheckCircle,
  XCircle,
  AlertCircle,
  Terminal,
  RefreshCw,
  Loader
} from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

interface MCPServer {
  name: string;
  package: string;
  installed: boolean;
  status: string;
  description?: string;
}

const MCPServers: React.FC = () => {
  const queryClient = useQueryClient();
  const [selectedServer, setSelectedServer] = useState<string | null>(null);
  const [testOutput, setTestOutput] = useState<Record<string, string>>({});
  const [installingServers, setInstallingServers] = useState<Set<string>>(new Set());

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['mcp-servers'],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/mcp/servers`);
      return data;
    },
  });

  const testMutation = useMutation({
    mutationFn: async (serverName: string) => {
      const { data } = await axios.post(`${API_BASE}/mcp/test`, {
        server: serverName
      });
      return data;
    },
    onSuccess: (data, serverName) => {
      setTestOutput(prev => ({
        ...prev,
        [serverName]: data.output || 'Test completed'
      }));
    },
    onError: (error: any, serverName) => {
      setTestOutput(prev => ({
        ...prev,
        [serverName]: `Error: ${error.response?.data?.error || error.message}`
      }));
    }
  });

  const installMutation = useMutation({
    mutationFn: async (server: MCPServer) => {
      setInstallingServers(prev => new Set(prev).add(server.name));
      const { data } = await axios.post(`${API_BASE}/mcp/install`, {
        server: server.package
      });
      return data;
    },
    onSuccess: (data, server) => {
      setInstallingServers(prev => {
        const next = new Set(prev);
        next.delete(server.name);
        return next;
      });
      queryClient.invalidateQueries({ queryKey: ['mcp-servers'] });
    },
    onError: (error: any, server) => {
      setInstallingServers(prev => {
        const next = new Set(prev);
        next.delete(server.name);
        return next;
      });
      console.error('Install failed:', error);
    }
  });

  const getServerIcon = (status: string) => {
    switch (status) {
      case 'ready':
        return <CheckCircle size={20} style={{ color: 'var(--color-success)' }} />;
      case 'not_installed':
        return <XCircle size={20} style={{ color: 'var(--color-error)' }} />;
      default:
        return <AlertCircle size={20} style={{ color: 'var(--color-warning)' }} />;
    }
  };

  const getServerDescription = (name: string): string => {
    const descriptions: Record<string, string> = {
      filesystem: 'Access and manipulate files and directories on your system',
      github: 'Integrate with GitHub repositories, issues, and pull requests',
      postgresql: 'Query and manage PostgreSQL databases',
      fetch: 'Make HTTP requests and scrape web content',
      memory: 'Persistent memory storage across Claude sessions',
      everything: 'Comprehensive toolkit for various operations',
      'sequential-thinking': 'Step-by-step reasoning for complex problem solving',
      sentry: 'Monitor and track application errors',
      firecrawl: 'Advanced web scraping with JavaScript rendering support',
    };
    return descriptions[name] || 'MCP server for extended functionality';
  };

  const handleTest = (serverName: string) => {
    setSelectedServer(serverName);
    setTestOutput(prev => ({ ...prev, [serverName]: 'Running test...' }));
    testMutation.mutate(serverName);
  };

  const handleInstall = (server: MCPServer) => {
    installMutation.mutate(server);
  };

  if (isLoading) {
    return (
      <div>
        <h2 className="text-primary font-semibold mb-6" style={{ fontSize: '1.875rem' }}>
          MCP Servers
        </h2>
        <div className="grid gap-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="card skeleton" style={{ height: '100px' }} />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
          <h2 className="text-primary font-semibold" style={{ fontSize: '1.875rem' }}>
            MCP Servers
          </h2>
          <button 
            className="btn btn-ghost btn-icon" 
            onClick={() => refetch()}
            title="Refresh"
          >
            <RefreshCw size={18} strokeWidth={1.5} />
          </button>
        </div>
        <p className="text-secondary">
          Manage Model Context Protocol servers that extend Claude's capabilities
        </p>
      </div>

      {/* Summary Stats */}
      <div className="grid gap-4 lg:grid-cols-3 mb-6">
        <div className="metric-card">
          <div className="metric-value">{data?.servers?.length || 0}</div>
          <div className="metric-label">Total Servers</div>
        </div>
        <div className="metric-card">
          <div className="metric-value">
            {data?.servers?.filter((s: MCPServer) => s.installed).length || 0}
          </div>
          <div className="metric-label">Installed</div>
        </div>
        <div className="metric-card">
          <div className="metric-value">
            {data?.servers?.filter((s: MCPServer) => !s.installed).length || 0}
          </div>
          <div className="metric-label">Available</div>
        </div>
      </div>

      {/* Server Grid */}
      <div className="grid gap-4">
        {data?.servers?.map((server: MCPServer) => (
          <div key={server.name} className="card">
            <div className="card-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <Server className="text-muted" size={24} strokeWidth={1.5} />
                <div style={{ flex: 1 }}>
                  <h3 className="font-semibold text-primary" style={{ marginBottom: '0.25rem' }}>
                    {server.name}
                  </h3>
                  <p className="text-sm text-secondary">
                    {getServerDescription(server.name)}
                  </p>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                {getServerIcon(server.status)}
                {server.installed ? (
                  <button
                    className="btn btn-primary"
                    onClick={() => handleTest(server.name)}
                    disabled={testMutation.isPending && selectedServer === server.name}
                  >
                    {testMutation.isPending && selectedServer === server.name ? (
                      <>
                        <RefreshCw size={14} className="animate-spin" />
                        Testing...
                      </>
                    ) : (
                      <>
                        <Play size={14} />
                        Test
                      </>
                    )}
                  </button>
                ) : (
                  <button 
                    className="btn btn-secondary"
                    onClick={() => handleInstall(server)}
                    disabled={installingServers.has(server.name)}
                  >
                    {installingServers.has(server.name) ? (
                      <>
                        <Loader size={14} className="animate-spin" />
                        Installing...
                      </>
                    ) : (
                      <>
                        <Download size={14} />
                        Install
                      </>
                    )}
                  </button>
                )}
              </div>
            </div>

            {/* Package Info */}
            <div style={{ 
              marginTop: '1rem', 
              padding: '0.75rem', 
              backgroundColor: 'var(--color-surface-hover)',
              borderRadius: '0.375rem',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}>
              <Terminal size={14} className="text-muted" />
              <code className="text-xs text-muted">{server.package}</code>
            </div>

            {/* Test Output */}
            {testOutput[server.name] && (
              <div style={{ 
                marginTop: '1rem',
                padding: '1rem',
                backgroundColor: 'var(--color-background)',
                border: '1px solid var(--color-border)',
                borderRadius: '0.375rem',
                fontFamily: 'monospace',
                fontSize: '0.75rem',
                maxHeight: '150px',
                overflowY: 'auto'
              }}>
                <pre style={{ margin: 0, whiteSpace: 'pre-wrap' }}>
                  {testOutput[server.name]}
                </pre>
              </div>
            )}

            {/* Quick Commands */}
            {server.installed && (
              <div style={{ marginTop: '1rem' }}>
                <p className="text-xs text-muted mb-2">Quick test command:</p>
                <code className="text-xs" style={{
                  display: 'block',
                  padding: '0.5rem',
                  backgroundColor: 'var(--color-surface-hover)',
                  borderRadius: '0.25rem'
                }}>
                  cce-mcp-test {server.name}
                </code>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default MCPServers;