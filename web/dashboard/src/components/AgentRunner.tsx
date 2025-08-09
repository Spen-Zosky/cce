import React, { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import axios from 'axios';
import { Play, Loader } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

interface Agent {
  id: string;
  name: string;
  description: string;
}

const AgentRunner: React.FC = () => {
  const [selectedAgent, setSelectedAgent] = useState('coder');
  const [args, setArgs] = useState('');
  const [output, setOutput] = useState('');

  const agents: Agent[] = [
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
    onError: (error: any) => {
      setOutput(`Error: ${error.response?.data?.error || error.message}`);
    },
  });

  const handleExecute = () => {
    setOutput('');
    executeMutation.mutate({ agent: selectedAgent, args });
  };

  return (
    <div>
      <h2 className="text-3xl font-bold mb-6 text-primary">AI Agents</h2>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Agent Selection */}
        <div>
          <h3 className="text-lg font-semibold mb-4 text-primary">Select Agent</h3>
          <div className="space-y-2">
            {agents.map((agent) => (
              <div
                key={agent.id}
                className={`card cursor-pointer transition-colors ${
                  selectedAgent === agent.id
                    ? 'border-accent bg-accent-secondary'
                    : 'hover:border-accent'
                }`}
                onClick={() => setSelectedAgent(agent.id)}
              >
                <h4 className="font-semibold text-primary">{agent.name}</h4>
                <p className="text-sm text-secondary">{agent.description}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Agent Execution */}
        <div>
          <h3 className="text-lg font-semibold mb-4 text-primary">Execute Agent</h3>
          <div className="space-y-4">
            <div>
              <label htmlFor="args" className="block text-sm font-medium mb-2 text-secondary">
                Arguments (optional)
              </label>
              <textarea
                id="args"
                className="w-full p-3 rounded-lg border border-primary focus:outline-none focus:ring-2"
                rows={4}
                value={args}
                onChange={(e) => setArgs(e.target.value)}
                placeholder="Enter task description or arguments..."
              />
            </div>
            
            <button
              onClick={handleExecute}
              disabled={executeMutation.isPending}
              className="btn btn-primary w-full py-3 disabled:opacity-50 disabled:cursor-not-allowed"
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
              <div className="flex items-center gap-2 mb-2">
                <h4 className="text-lg font-semibold text-primary">Output</h4>
                <div className="status-indicator status-success">Completed</div>
              </div>
              <pre className="p-4 bg-tertiary rounded-lg overflow-auto max-h-96 text-sm border border-primary font-mono text-primary">
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