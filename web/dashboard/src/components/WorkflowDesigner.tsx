import React, { useCallback, useState, useEffect } from 'react';
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
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { 
  Play, 
  Save, 
  Plus, 
  Bot, 
  Code, 
  FileText, 
  Bug, 
  Package, 
  Download, 
  Upload,
  Trash2,
  Settings,
  Clock,
  CheckCircle,
  XCircle,
  Loader,
  Eye,
  Edit3,
  RotateCcw,
  Database,
  Search,
  Zap,
  GitBranch
} from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

interface WorkflowNode extends Node {
  data: {
    label: string;
    agentType: string;
    args?: string;
    status?: 'idle' | 'running' | 'completed' | 'error';
    executionTime?: number;
    description?: string;
    lastRun?: string;
  };
}

interface WorkflowExecution {
  id: string;
  name: string;
  status: 'idle' | 'running' | 'completed' | 'error';
  startTime?: string;
  endTime?: string;
  currentNode?: string;
  results?: any;
}

interface SavedWorkflow {
  id: string;
  name: string;
  description?: string;
  nodes: Node[];
  edges: Edge[];
  created: string;
  modified: string;
  executions: number;
}

function AgentNode({ data, selected }: NodeProps) {
  const getIcon = () => {
    switch (data.agentType) {
      case 'coder': return <Code size={20} />;
      case 'reviewer': return <FileText size={20} />;
      case 'tester': return <Play size={20} />;
      case 'debugger': return <Bug size={20} />;
      case 'deployer': return <Package size={20} />;
      case 'analyzer': return <Search size={20} />;
      case 'documenter': return <FileText size={20} />;
      default: return <Bot size={20} />;
    }
  };

  const getStatusIcon = () => {
    switch (data.status) {
      case 'running': return <Loader size={16} className="animate-spin text-blue-500" />;
      case 'completed': return <CheckCircle size={16} className="text-green-500" />;
      case 'error': return <XCircle size={16} className="text-red-500" />;
      default: return null;
    }
  };

  const getNodeColor = () => {
    switch (data.status) {
      case 'running': return '#3B82F6';
      case 'completed': return '#10B981';
      case 'error': return '#EF4444';
      default: return '#6B7280';
    }
  };

  return (
    <div 
      className={`workflow-node ${selected ? 'selected' : ''}`}
      style={{
        borderColor: getNodeColor(),
        boxShadow: selected ? `0 0 10px ${getNodeColor()}` : undefined
      }}
    >
      <Handle type="target" position={Position.Top} />
      
      <div className="workflow-node-content">
        <div className="workflow-node-header">
          <div className="workflow-node-icon" style={{ color: getNodeColor() }}>
            {getIcon()}
          </div>
          <div className="workflow-node-status">
            {getStatusIcon()}
          </div>
        </div>
        
        <div className="workflow-node-info">
          <div className="workflow-node-title">{data.label}</div>
          <div className="workflow-node-type">{data.agentType}</div>
          {data.executionTime && (
            <div className="workflow-node-time">
              <Clock size={12} />
              {data.executionTime}s
            </div>
          )}
        </div>
        
        {data.description && (
          <div className="workflow-node-description">
            {data.description}
          </div>
        )}
      </div>
      
      <Handle type="source" position={Position.Bottom} />
    </div>
  );
}

const nodeTypes = {
  agent: AgentNode,
};

const PREDEFINED_WORKFLOWS = {
  fullstack: {
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
  }
};

const initialNodes: Node[] = [
  {
    id: '1',
    type: 'agent',
    position: { x: 250, y: 100 },
    data: { 
      label: 'Start Here', 
      agentType: 'analyzer',
      description: 'Add agents to create your workflow',
      status: 'idle'
    },
  },
];

const initialEdges: Edge[] = [];

export const WorkflowDesigner: React.FC = () => {
  const queryClient = useQueryClient();
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);
  const [selectedNode, setSelectedNode] = useState<Node | null>(null);
  const [currentExecution, setCurrentExecution] = useState<WorkflowExecution | null>(null);
  const [savedWorkflows, setSavedWorkflows] = useState<SavedWorkflow[]>([]);
  const [showSaveModal, setShowSaveModal] = useState(false);
  const [showLoadModal, setShowLoadModal] = useState(false);
  const [showTemplatesModal, setShowTemplatesModal] = useState(false);
  const [workflowName, setWorkflowName] = useState('');
  const [workflowDescription, setWorkflowDescription] = useState('');

  // Load saved workflows from localStorage
  useEffect(() => {
    const saved = localStorage.getItem('cce-workflows');
    if (saved) {
      try {
        setSavedWorkflows(JSON.parse(saved));
      } catch (error) {
        console.error('Failed to load saved workflows:', error);
      }
    }
  }, []);

  // Save workflows to localStorage
  const saveWorkflowsToStorage = (workflows: SavedWorkflow[]) => {
    localStorage.setItem('cce-workflows', JSON.stringify(workflows));
    setSavedWorkflows(workflows);
  };

  const onConnect = useCallback(
    (params: any) => setEdges((eds) => addEdge(params, eds)),
    [setEdges]
  );

  const onNodeClick = useCallback((event: any, node: Node) => {
    setSelectedNode(node);
  }, []);

  const addNode = (agentType: string) => {
    const newNode: Node = {
      id: `node-${Date.now()}`,
      type: 'agent',
      position: { x: Math.random() * 400 + 100, y: Math.random() * 300 + 100 },
      data: { 
        label: `New ${agentType.charAt(0).toUpperCase() + agentType.slice(1)}`, 
        agentType,
        status: 'idle',
        description: `${agentType} agent description`
      },
    };
    setNodes((nds) => nds.concat(newNode));
  };

  const deleteNode = (nodeId: string) => {
    setNodes((nds) => nds.filter(n => n.id !== nodeId));
    setEdges((eds) => eds.filter(e => e.source !== nodeId && e.target !== nodeId));
    if (selectedNode?.id === nodeId) {
      setSelectedNode(null);
    }
  };

  const updateNodeData = (nodeId: string, newData: any) => {
    setNodes((nds) =>
      nds.map((node) =>
        node.id === nodeId
          ? { ...node, data: { ...node.data, ...newData } }
          : node
      )
    );
  };

  // Execute workflow using the agent API
  const executeWorkflowMutation = useMutation({
    mutationFn: async () => {
      const execution: WorkflowExecution = {
        id: `exec-${Date.now()}`,
        name: workflowName || 'Unnamed Workflow',
        status: 'running',
        startTime: new Date().toISOString(),
        currentNode: nodes[0]?.id
      };
      
      setCurrentExecution(execution);

      // Execute nodes in topological order based on edges
      const executionOrder = getExecutionOrder(nodes, edges);
      const results: any = {};
      
      for (const nodeId of executionOrder) {
        const node = nodes.find(n => n.id === nodeId);
        if (!node) continue;

        // Update node status to running
        setNodes(prev => prev.map(n => 
          n.id === nodeId 
            ? { ...n, data: { ...n.data, status: 'running' } }
            : n
        ));

        setCurrentExecution(prev => prev ? { ...prev, currentNode: nodeId } : null);

        try {
          const startTime = Date.now();
          
          // Execute the agent
          const { data } = await axios.post(`${API_BASE}/agents/execute`, {
            agent: node.data.agentType,
            args: node.data.args || '',
            project: ''
          });

          const executionTime = (Date.now() - startTime) / 1000;

          // Update node status to completed
          setNodes(prev => prev.map(n => 
            n.id === nodeId 
              ? { 
                  ...n, 
                  data: { 
                    ...n.data, 
                    status: 'completed',
                    executionTime,
                    lastRun: new Date().toISOString()
                  } 
                }
              : n
          ));

          results[nodeId] = data;

        } catch (error: any) {
          // Update node status to error
          setNodes(prev => prev.map(n => 
            n.id === nodeId 
              ? { ...n, data: { ...n.data, status: 'error' } }
              : n
          ));

          results[nodeId] = { error: error.message };
          console.error(`Agent ${node.data.agentType} failed:`, error);
        }
      }

      // Complete execution
      const completedExecution: WorkflowExecution = {
        ...execution,
        status: 'completed',
        endTime: new Date().toISOString(),
        results
      };

      setCurrentExecution(completedExecution);
      return completedExecution;
    }
  });

  // Get execution order using topological sort
  const getExecutionOrder = (nodes: Node[], edges: Edge[]): string[] => {
    const nodeIds = nodes.map(n => n.id);
    const dependencies: Record<string, string[]> = {};
    const inDegree: Record<string, number> = {};

    // Initialize
    nodeIds.forEach(id => {
      dependencies[id] = [];
      inDegree[id] = 0;
    });

    // Build dependency graph
    edges.forEach(edge => {
      dependencies[edge.source].push(edge.target);
      inDegree[edge.target]++;
    });

    // Topological sort
    const queue: string[] = [];
    const result: string[] = [];

    // Find nodes with no dependencies
    Object.keys(inDegree).forEach(id => {
      if (inDegree[id] === 0) {
        queue.push(id);
      }
    });

    while (queue.length > 0) {
      const current = queue.shift()!;
      result.push(current);

      dependencies[current].forEach(dependent => {
        inDegree[dependent]--;
        if (inDegree[dependent] === 0) {
          queue.push(dependent);
        }
      });
    }

    return result;
  };

  const saveCurrentWorkflow = () => {
    if (!workflowName.trim()) return;

    const workflow: SavedWorkflow = {
      id: `workflow-${Date.now()}`,
      name: workflowName,
      description: workflowDescription,
      nodes,
      edges,
      created: new Date().toISOString(),
      modified: new Date().toISOString(),
      executions: 0
    };

    const updated = [...savedWorkflows, workflow];
    saveWorkflowsToStorage(updated);
    setShowSaveModal(false);
    setWorkflowName('');
    setWorkflowDescription('');
  };

  const loadWorkflow = (workflow: SavedWorkflow) => {
    setNodes(workflow.nodes);
    setEdges(workflow.edges);
    setShowLoadModal(false);
  };

  const loadTemplate = (templateKey: string) => {
    const template = PREDEFINED_WORKFLOWS[templateKey as keyof typeof PREDEFINED_WORKFLOWS];
    if (template) {
      setNodes(template.nodes);
      setEdges(template.edges);
      setWorkflowName(template.name);
      setWorkflowDescription(template.description);
    }
    setShowTemplatesModal(false);
  };

  const clearWorkflow = () => {
    setNodes(initialNodes);
    setEdges(initialEdges);
    setSelectedNode(null);
    setCurrentExecution(null);
  };

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <h2 className="text-primary font-semibold mb-2" style={{ fontSize: '1.875rem' }}>
          Workflow Designer
        </h2>
        <p className="text-secondary">
          Design and execute automated workflows using CCE agents
        </p>
      </div>

      <div style={{ height: '700px', border: '1px solid var(--color-border)', borderRadius: '0.5rem' }}>
        {/* Enhanced Toolbar */}
        <div className="workflow-toolbar" style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '1rem',
          borderBottom: '1px solid var(--color-border)',
          backgroundColor: 'var(--color-surface)',
          gap: '1rem'
        }}>
          {/* Execution Controls */}
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            <button 
              className="btn btn-primary" 
              onClick={() => executeWorkflowMutation.mutate()}
              disabled={executeWorkflowMutation.isPending || nodes.length <= 1}
            >
              {executeWorkflowMutation.isPending ? (
                <>
                  <Loader size={16} className="animate-spin" />
                  Running...
                </>
              ) : (
                <>
                  <Play size={16} />
                  Run Workflow
                </>
              )}
            </button>
            
            <button className="btn btn-secondary" onClick={() => setShowSaveModal(true)}>
              <Save size={16} />
              Save
            </button>
            
            <button className="btn btn-secondary" onClick={() => setShowLoadModal(true)}>
              <Download size={16} />
              Load
            </button>
            
            <button className="btn btn-secondary" onClick={() => setShowTemplatesModal(true)}>
              <Upload size={16} />
              Templates
            </button>
            
            <button className="btn btn-ghost" onClick={clearWorkflow}>
              <RotateCcw size={16} />
              Clear
            </button>
          </div>

          {/* Agent Add Controls */}
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            {['coder', 'reviewer', 'tester', 'debugger', 'analyzer', 'documenter', 'deployer'].map(agent => (
              <button 
                key={agent}
                className="btn btn-ghost btn-sm" 
                onClick={() => addNode(agent)}
                title={`Add ${agent} agent`}
              >
                <Plus size={14} />
                {agent}
              </button>
            ))}
          </div>

          {/* Execution Status */}
          {currentExecution && (
            <div style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: '0.5rem',
              padding: '0.5rem 1rem',
              backgroundColor: currentExecution.status === 'running' ? '#FEF3C7' : '#D1FAE5',
              borderRadius: '0.375rem',
              fontSize: '0.875rem'
            }}>
              {currentExecution.status === 'running' ? (
                <Loader size={16} className="animate-spin text-yellow-600" />
              ) : (
                <CheckCircle size={16} className="text-green-600" />
              )}
              <span>{currentExecution.name}</span>
              <span className="text-muted">({currentExecution.status})</span>
            </div>
          )}
        </div>

        {/* React Flow Canvas */}
        <div style={{ height: 'calc(100% - 80px)' }}>
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onConnect={onConnect}
            onNodeClick={onNodeClick}
            nodeTypes={nodeTypes}
            fitView
            style={{ backgroundColor: 'var(--color-bg-secondary)' }}
          >
            <Background />
            <Controls />
            <MiniMap />
          </ReactFlow>
        </div>
      </div>

      {/* Enhanced Sidebar */}
      {selectedNode && (
        <div style={{
          position: 'fixed',
          top: '50%',
          right: '2rem',
          transform: 'translateY(-50%)',
          width: '320px',
          backgroundColor: 'var(--color-surface)',
          border: '1px solid var(--color-border)',
          borderRadius: '0.5rem',
          padding: '1.5rem',
          boxShadow: '0 4px 6px var(--color-shadow)',
          zIndex: 1000,
          maxHeight: '80vh',
          overflowY: 'auto'
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h3 className="font-semibold text-primary">Node Configuration</h3>
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button 
                className="btn btn-ghost btn-icon"
                onClick={() => deleteNode(selectedNode.id)}
                title="Delete node"
              >
                <Trash2 size={16} />
              </button>
              <button 
                className="btn btn-ghost btn-icon"
                onClick={() => setSelectedNode(null)}
              >
                <XCircle size={16} />
              </button>
            </div>
          </div>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <div>
              <label className="text-sm font-medium text-secondary">Agent Type</label>
              <select
                value={selectedNode.data.agentType}
                onChange={(e) => updateNodeData(selectedNode.id, { agentType: e.target.value })}
                className="input mt-1"
              >
                <option value="coder">Coder</option>
                <option value="reviewer">Reviewer</option>
                <option value="tester">Tester</option>
                <option value="debugger">Debugger</option>
                <option value="analyzer">Analyzer</option>
                <option value="documenter">Documenter</option>
                <option value="deployer">Deployer</option>
              </select>
            </div>

            <div>
              <label className="text-sm font-medium text-secondary">Node Label</label>
              <input
                type="text"
                value={selectedNode.data.label}
                onChange={(e) => updateNodeData(selectedNode.id, { label: e.target.value })}
                className="input mt-1"
                placeholder="Node label"
              />
            </div>

            <div>
              <label className="text-sm font-medium text-secondary">Description</label>
              <textarea
                value={selectedNode.data.description || ''}
                onChange={(e) => updateNodeData(selectedNode.id, { description: e.target.value })}
                className="input mt-1"
                rows={3}
                placeholder="Node description"
              />
            </div>

            <div>
              <label className="text-sm font-medium text-secondary">Arguments</label>
              <textarea
                value={selectedNode.data.args || ''}
                onChange={(e) => updateNodeData(selectedNode.id, { args: e.target.value })}
                className="input mt-1"
                rows={2}
                placeholder="Agent arguments"
              />
            </div>

            {selectedNode.data.status && (
              <div>
                <label className="text-sm font-medium text-secondary">Status</label>
                <div style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '0.5rem',
                  marginTop: '0.25rem'
                }}>
                  {selectedNode.data.status === 'running' && <Loader size={16} className="animate-spin text-blue-500" />}
                  {selectedNode.data.status === 'completed' && <CheckCircle size={16} className="text-green-500" />}
                  {selectedNode.data.status === 'error' && <XCircle size={16} className="text-red-500" />}
                  <span className="text-sm capitalize">{selectedNode.data.status}</span>
                </div>
              </div>
            )}

            {selectedNode.data.executionTime && (
              <div>
                <label className="text-sm font-medium text-secondary">Last Execution Time</label>
                <p className="text-sm text-muted">{selectedNode.data.executionTime}s</p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Save Modal */}
      {showSaveModal && (
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
          zIndex: 2000
        }}>
          <div className="card" style={{ width: '90%', maxWidth: '500px', padding: '2rem' }}>
            <h3 className="font-semibold text-primary mb-4">Save Workflow</h3>
            
            <div style={{ marginBottom: '1rem' }}>
              <label className="text-sm font-medium text-secondary">Workflow Name</label>
              <input
                type="text"
                value={workflowName}
                onChange={(e) => setWorkflowName(e.target.value)}
                className="input mt-1"
                placeholder="Enter workflow name"
              />
            </div>

            <div style={{ marginBottom: '1.5rem' }}>
              <label className="text-sm font-medium text-secondary">Description</label>
              <textarea
                value={workflowDescription}
                onChange={(e) => setWorkflowDescription(e.target.value)}
                className="input mt-1"
                rows={3}
                placeholder="Describe what this workflow does"
              />
            </div>

            <div style={{ display: 'flex', gap: '1rem', justifyContent: 'flex-end' }}>
              <button 
                className="btn btn-secondary" 
                onClick={() => setShowSaveModal(false)}
              >
                Cancel
              </button>
              <button 
                className="btn btn-primary" 
                onClick={saveCurrentWorkflow}
                disabled={!workflowName.trim()}
              >
                Save Workflow
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Load Modal */}
      {showLoadModal && (
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
          zIndex: 2000
        }}>
          <div className="card" style={{ width: '90%', maxWidth: '600px', padding: '2rem' }}>
            <h3 className="font-semibold text-primary mb-4">Load Saved Workflow</h3>
            
            {savedWorkflows.length === 0 ? (
              <p className="text-muted text-center py-8">No saved workflows found</p>
            ) : (
              <div style={{ display: 'grid', gap: '1rem', maxHeight: '400px', overflowY: 'auto' }}>
                {savedWorkflows.map(workflow => (
                  <div 
                    key={workflow.id} 
                    className="card"
                    style={{ 
                      padding: '1rem',
                      cursor: 'pointer',
                      border: '1px solid var(--color-border)'
                    }}
                    onClick={() => loadWorkflow(workflow)}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                      <div>
                        <h4 className="font-medium text-primary">{workflow.name}</h4>
                        {workflow.description && (
                          <p className="text-sm text-secondary mt-1">{workflow.description}</p>
                        )}
                        <div style={{ display: 'flex', gap: '1rem', marginTop: '0.5rem' }}>
                          <span className="text-xs text-muted">
                            {workflow.nodes.length} nodes, {workflow.edges.length} edges
                          </span>
                          <span className="text-xs text-muted">
                            Created: {new Date(workflow.created).toLocaleDateString()}
                          </span>
                        </div>
                      </div>
                      <button
                        className="btn btn-ghost btn-icon"
                        onClick={(e) => {
                          e.stopPropagation();
                          const updated = savedWorkflows.filter(w => w.id !== workflow.id);
                          saveWorkflowsToStorage(updated);
                        }}
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
              <button 
                className="btn btn-secondary" 
                onClick={() => setShowLoadModal(false)}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Templates Modal */}
      {showTemplatesModal && (
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
          zIndex: 2000
        }}>
          <div className="card" style={{ width: '90%', maxWidth: '600px', padding: '2rem' }}>
            <h3 className="font-semibold text-primary mb-4">Workflow Templates</h3>
            
            <div style={{ display: 'grid', gap: '1rem' }}>
              {Object.entries(PREDEFINED_WORKFLOWS).map(([key, template]) => (
                <div 
                  key={key}
                  className="card"
                  style={{ 
                    padding: '1rem',
                    cursor: 'pointer',
                    border: '1px solid var(--color-border)'
                  }}
                  onClick={() => loadTemplate(key)}
                >
                  <h4 className="font-medium text-primary">{template.name}</h4>
                  <p className="text-sm text-secondary mt-1">{template.description}</p>
                  <div style={{ marginTop: '0.5rem' }}>
                    <span className="text-xs text-muted">
                      {template.nodes.length} agents, {template.edges.length} connections
                    </span>
                  </div>
                </div>
              ))}
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
              <button 
                className="btn btn-secondary" 
                onClick={() => setShowTemplatesModal(false)}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// Add workflow-specific styles
const workflowStyles = `
.workflow-node {
  min-width: 180px;
  background: var(--color-surface);
  border: 2px solid var(--color-border);
  border-radius: 8px;
  padding: 12px;
  box-shadow: 0 2px 8px var(--color-shadow);
  transition: all 0.2s ease;
}

.workflow-node:hover {
  box-shadow: 0 4px 12px var(--color-shadow);
  transform: translateY(-1px);
}

.workflow-node.selected {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.3);
}

.workflow-node-content {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.workflow-node-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.workflow-node-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  background: var(--color-surface-hover);
  border-radius: 6px;
  color: var(--color-text-primary);
}

.workflow-node-status {
  display: flex;
  align-items: center;
}

.workflow-node-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.workflow-node-title {
  font-weight: 600;
  color: var(--color-text-primary);
  font-size: 14px;
  line-height: 1.2;
}

.workflow-node-type {
  color: var(--color-text-secondary);
  font-size: 12px;
  text-transform: capitalize;
}

.workflow-node-time {
  display: flex;
  align-items: center;
  gap: 4px;
  color: var(--color-text-muted);
  font-size: 11px;
  margin-top: 2px;
}

.workflow-node-description {
  color: var(--color-text-muted);
  font-size: 11px;
  line-height: 1.3;
  max-width: 160px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.btn-sm {
  padding: 0.375rem 0.75rem;
  font-size: 0.8125rem;
}

.btn-icon {
  padding: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* React Flow customizations */
.react-flow__node-agent {
  background: transparent;
  border: none;
  padding: 0;
}

.react-flow__handle {
  width: 8px;
  height: 8px;
  background: var(--color-primary);
  border: 2px solid var(--color-surface);
}

.react-flow__handle-top {
  top: -4px;
}

.react-flow__handle-bottom {
  bottom: -4px;
}

.react-flow__edge-default {
  stroke: var(--color-primary);
  stroke-width: 2;
}

.react-flow__controls {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
}

.react-flow__controls-button {
  background: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text-primary);
}

.react-flow__controls-button:hover {
  background: var(--color-surface-hover);
}

.react-flow__minimap {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
}
`;

// Add styles to document
if (typeof document !== 'undefined') {
  const styleSheet = document.createElement('style');
  styleSheet.textContent = workflowStyles;
  document.head.appendChild(styleSheet);
}