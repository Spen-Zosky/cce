import React from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { FileText, RefreshCw } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

interface LogFile {
  file: string;
  content: string[];
}

const Logs: React.FC = () => {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['logs'],
    queryFn: async () => {
      const { data } = await axios.get(`${API_BASE}/logs`);
      return data;
    },
    refetchInterval: 10000, // Refresh every 10 seconds
  });

  if (isLoading) {
    return <div className="animate-pulse">Loading logs...</div>;
  }

  if (error) {
    return <div className="text-red-500">Error loading logs</div>;
  }

  const handleRefresh = () => {
    refetch();
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-3xl font-bold text-primary">System Logs</h2>
        <button
          onClick={handleRefresh}
          className="btn btn-secondary p-2"
          title="Refresh logs"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>
      
      {!data?.logs || data.logs.length === 0 ? (
        <div className="card text-center">
          <FileText className="w-12 h-12 text-muted mx-auto mb-3" />
          <p className="text-secondary">No logs available</p>
          <p className="text-sm text-muted mt-1">Logs will appear here when the system generates them</p>
        </div>
      ) : (
        <div className="space-y-4">
          {data.logs.map((log: LogFile, index: number) => (
            <div key={index} className="card">
              <div className="flex items-center gap-2 mb-2">
                <FileText className="w-4 h-4 text-muted" />
                <h3 className="font-semibold text-primary">{log.file}</h3>
                <span className="status-indicator status-success text-xs">Active</span>
              </div>
              <pre className="text-sm bg-tertiary p-3 rounded border border-primary overflow-auto max-h-64 font-mono text-primary">
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