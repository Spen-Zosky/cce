import React from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { CheckCircle, XCircle, Clock, Cpu, HardDrive } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

const SystemStatus: React.FC = () => {
  const { data: status, isLoading, error } = useQuery({
    queryKey: ['status'],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/status`);
      return data;
    },
  });

  if (isLoading) {
    return <div className="animate-pulse">Loading system status...</div>;
  }

  if (error) {
    return <div className="text-red-500">Error loading status</div>;
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
      <h2 className="text-3xl font-bold mb-6 text-primary">System Status</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* CCE Status */}
        <div className="card">
          <h3 className="text-lg font-semibold mb-4 text-primary">CCE Environment</h3>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-secondary">Version</span>
              <span className="font-mono text-primary">{status?.cce?.version || 'N/A'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-secondary">Environment</span>
              <span className="font-mono text-primary">{status?.cce?.environment || 'N/A'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-secondary">Architecture</span>
              <span className="font-mono text-primary">{status?.cce?.architecture || 'N/A'}</span>
            </div>
          </div>
        </div>

        {/* Claude Status */}
        <div className="card">
          <h3 className="text-lg font-semibold mb-4 text-primary">Claude CLI</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-secondary">Installation</span>
              <div className={`status-indicator ${status?.claude?.installed ? 'status-success' : 'status-error'}`}>
                {status?.claude?.installed ? (
                  <CheckCircle className="w-4 h-4" />
                ) : (
                  <XCircle className="w-4 h-4" />
                )}
                {status?.claude?.installed ? 'Installed' : 'Not Found'}
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-secondary">API Key</span>
              <div className={`status-indicator ${status?.apiKey?.configured ? 'status-success' : 'status-error'}`}>
                {status?.apiKey?.configured ? (
                  <CheckCircle className="w-4 h-4" />
                ) : (
                  <XCircle className="w-4 h-4" />
                )}
                {status?.apiKey?.configured ? 'Configured' : 'Missing'}
              </div>
            </div>
          </div>
        </div>

        {/* System Resources */}
        <div className="card">
          <h3 className="text-lg font-semibold mb-4 text-primary">System Resources</h3>
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-muted" />
              <span className="text-sm text-secondary">Uptime: {formatUptime(status?.uptime || 0)}</span>
            </div>
            <div className="flex items-center gap-2">
              <HardDrive className="w-4 h-4 text-muted" />
              <span className="text-sm text-secondary">Memory: {formatMemory(status?.memory?.heapUsed || 0)}</span>
            </div>
            <div className="flex items-center gap-2">
              <Cpu className="w-4 h-4 text-muted" />
              <span className="text-sm text-secondary">Node: {status?.node || 'N/A'}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8">
        <h3 className="text-xl font-semibold mb-4 text-primary">Quick Actions</h3>
        <div className="flex gap-4">
          <button className="btn btn-primary">
            Create New Project
          </button>
          <button className="btn btn-secondary">
            Run System Check
          </button>
          <button className="btn btn-secondary">
            Update CCE
          </button>
        </div>
      </div>
    </div>
  );
};

export default SystemStatus;