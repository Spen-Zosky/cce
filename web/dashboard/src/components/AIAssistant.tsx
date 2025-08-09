import React, { useState, useRef, useEffect } from 'react';
import { useMutation } from '@tanstack/react-query';
import axios from 'axios';
import { Send, Bot, User, Loader, X, Maximize2, Minimize2 } from 'lucide-react';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface AIAssistantProps {
  isOpen: boolean;
  onClose: () => void;
  context?: any;
}

export const AIAssistant: React.FC<AIAssistantProps> = ({ isOpen, onClose, context }) => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isMinimized, setIsMinimized] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessageMutation = useMutation({
    mutationFn: async (message: string) => {
      const { data } = await axios.post('/api/v1/ai/chat', {
        message,
        context,
        history: messages
      });
      return data;
    },
    onSuccess: (data) => {
      setMessages(prev => [...prev, {
        id: Date.now().toString(),
        role: 'assistant',
        content: data.response,
        timestamp: new Date()
      }]);
    }
  });

  const handleSend = () => {
    if (!input.trim() || sendMessageMutation.isPending) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    sendMessageMutation.mutate(input);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  if (!isOpen) return null;

  return (
    <div className={`ai-assistant-container ${isMinimized ? 'minimized' : ''}`}>
      <div className="ai-assistant-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Bot size={18} />
          <span className="font-medium">Claude Assistant</span>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button
            className="btn btn-secondary p-2"
            onClick={() => setIsMinimized(!isMinimized)}
          >
            {isMinimized ? <Maximize2 size={16} /> : <Minimize2 size={16} />}
          </button>
          <button
            className="btn btn-secondary p-2"
            onClick={onClose}
          >
            <X size={16} />
          </button>
        </div>
      </div>

      {!isMinimized && (
        <>
          <div className="ai-assistant-messages">
            {messages.length === 0 ? (
              <div className="ai-assistant-empty">
                <Bot size={48} className="text-muted" style={{ marginBottom: '1rem' }} />
                <p className="text-muted">Hi! I'm Claude, your AI assistant.</p>
                <p className="text-muted text-sm">Ask me anything about your projects or development tasks.</p>
              </div>
            ) : (
              messages.map((message) => (
                <div
                  key={message.id}
                  className={`ai-assistant-message ${message.role}`}
                >
                  <div className="ai-assistant-message-icon">
                    {message.role === 'user' ? (
                      <User size={16} />
                    ) : (
                      <Bot size={16} />
                    )}
                  </div>
                  <div className="ai-assistant-message-content">
                    <div className="ai-assistant-message-text">
                      {message.content}
                    </div>
                    <div className="ai-assistant-message-time">
                      {message.timestamp.toLocaleTimeString()}
                    </div>
                  </div>
                </div>
              ))
            )}
            {sendMessageMutation.isPending && (
              <div className="ai-assistant-message assistant">
                <div className="ai-assistant-message-icon">
                  <Bot size={16} />
                </div>
                <div className="ai-assistant-message-content">
                  <Loader size={16} className="animate-spin" />
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <div className="ai-assistant-input">
            <textarea
              ref={inputRef}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Ask me anything..."
              className="ai-assistant-textarea"
              rows={2}
            />
            <button
              className="btn btn-primary p-2"
              onClick={handleSend}
              disabled={!input.trim() || sendMessageMutation.isPending}
            >
              <Send size={18} />
            </button>
          </div>
        </>
      )}
    </div>
  );
};