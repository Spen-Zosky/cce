import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { X, Save, RefreshCw } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3456/api/v1';

interface SettingsData {
  theme: 'light' | 'dark';
  autoRefresh: boolean;
  refreshInterval: number;
  notifications: boolean;
  compactView: boolean;
  showSystemStats: boolean;
}

interface SettingsProps {
  isOpen: boolean;
  onClose: () => void;
}

const Settings: React.FC<SettingsProps> = ({ isOpen, onClose }) => {
  const queryClient = useQueryClient();
  const [isDirty, setIsDirty] = useState(false);

  const { data: settings, isLoading } = useQuery({
    queryKey: ['settings'],
    queryFn: async (): Promise<SettingsData> => {
      const { data } = await axios.get(`${API_BASE}/settings`);
      return data;
    },
  });

  const [formData, setFormData] = useState<SettingsData>({
    theme: 'light',
    autoRefresh: true,
    refreshInterval: 10000,
    notifications: true,
    compactView: false,
    showSystemStats: true,
    ...settings
  });

  React.useEffect(() => {
    if (settings) {
      setFormData(settings);
    }
  }, [settings]);

  const saveMutation = useMutation({
    mutationFn: async (data: SettingsData) => {
      const { data: response } = await axios.post(`${API_BASE}/settings`, data);
      return response;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings'] });
      setIsDirty(false);
      onClose();
    },
  });

  const handleInputChange = (key: keyof SettingsData, value: any) => {
    setFormData(prev => ({ ...prev, [key]: value }));
    setIsDirty(true);
  };

  const handleSave = () => {
    saveMutation.mutate(formData);
  };

  const handleReset = () => {
    if (settings) {
      setFormData(settings);
      setIsDirty(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="card max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-6 pb-4 border-b border-primary">
          <h2 className="text-2xl font-bold text-primary">Dashboard Settings</h2>
          <button
            onClick={onClose}
            className="btn btn-secondary p-2"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {isLoading ? (
          <div className="animate-pulse text-center py-8">Loading settings...</div>
        ) : (
          <div className="space-y-6">
            {/* Theme Settings */}
            <section>
              <h3 className="text-lg font-semibold text-primary mb-4">Appearance</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-secondary mb-2">
                    Theme
                  </label>
                  <div className="flex gap-3">
                    <label className="flex items-center">
                      <input
                        type="radio"
                        name="theme"
                        value="light"
                        checked={formData.theme === 'light'}
                        onChange={(e) => handleInputChange('theme', e.target.value)}
                        className="mr-2"
                      />
                      <span className="text-secondary">Light</span>
                    </label>
                    <label className="flex items-center">
                      <input
                        type="radio"
                        name="theme"
                        value="dark"
                        checked={formData.theme === 'dark'}
                        onChange={(e) => handleInputChange('theme', e.target.value)}
                        className="mr-2"
                      />
                      <span className="text-secondary">Dark</span>
                    </label>
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <label className="text-sm font-medium text-secondary">
                    Compact View
                  </label>
                  <input
                    type="checkbox"
                    checked={formData.compactView}
                    onChange={(e) => handleInputChange('compactView', e.target.checked)}
                    className="toggle"
                  />
                </div>
              </div>
            </section>

            {/* Data Refresh Settings */}
            <section>
              <h3 className="text-lg font-semibold text-primary mb-4">Data & Updates</h3>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <label className="text-sm font-medium text-secondary">
                    Auto Refresh
                  </label>
                  <input
                    type="checkbox"
                    checked={formData.autoRefresh}
                    onChange={(e) => handleInputChange('autoRefresh', e.target.checked)}
                    className="toggle"
                  />
                </div>

                {formData.autoRefresh && (
                  <div>
                    <label className="block text-sm font-medium text-secondary mb-2">
                      Refresh Interval (seconds)
                    </label>
                    <select
                      value={formData.refreshInterval / 1000}
                      onChange={(e) => handleInputChange('refreshInterval', parseInt(e.target.value) * 1000)}
                      className="w-full p-2 border border-primary rounded-lg bg-primary text-primary"
                    >
                      <option value="5">5 seconds</option>
                      <option value="10">10 seconds</option>
                      <option value="30">30 seconds</option>
                      <option value="60">1 minute</option>
                      <option value="300">5 minutes</option>
                    </select>
                  </div>
                )}
              </div>
            </section>

            {/* Display Settings */}
            <section>
              <h3 className="text-lg font-semibold text-primary mb-4">Display</h3>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <label className="text-sm font-medium text-secondary">
                    Show System Statistics
                  </label>
                  <input
                    type="checkbox"
                    checked={formData.showSystemStats}
                    onChange={(e) => handleInputChange('showSystemStats', e.target.checked)}
                    className="toggle"
                  />
                </div>

                <div className="flex items-center justify-between">
                  <label className="text-sm font-medium text-secondary">
                    Enable Notifications
                  </label>
                  <input
                    type="checkbox"
                    checked={formData.notifications}
                    onChange={(e) => handleInputChange('notifications', e.target.checked)}
                    className="toggle"
                  />
                </div>
              </div>
            </section>

            {/* System Information */}
            <section className="card bg-tertiary">
              <h3 className="text-lg font-semibold text-primary mb-4">System Information</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-secondary">Dashboard Version</span>
                  <span className="font-mono text-primary">2.0.0 Pro</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-secondary">API Endpoint</span>
                  <span className="font-mono text-primary">{API_BASE}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-secondary">WebSocket</span>
                  <div className="status-indicator status-success">Connected</div>
                </div>
              </div>
            </section>
          </div>
        )}

        {/* Footer */}
        <div className="flex items-center justify-between mt-8 pt-4 border-t border-primary">
          <div className="flex gap-2">
            <button
              onClick={handleReset}
              disabled={!isDirty}
              className="btn btn-secondary"
            >
              <RefreshCw className="w-4 h-4" />
              Reset
            </button>
          </div>
          
          <div className="flex gap-2">
            <button
              onClick={onClose}
              className="btn btn-secondary"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={!isDirty || saveMutation.isPending}
              className="btn btn-primary"
            >
              <Save className="w-4 h-4" />
              {saveMutation.isPending ? 'Saving...' : 'Save Settings'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;