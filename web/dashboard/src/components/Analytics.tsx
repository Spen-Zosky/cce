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

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
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