import React, { useEffect, useRef, useState } from 'react';
import { Terminal as XTerm } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import { WebLinksAddon } from 'xterm-addon-web-links';
import { X, Maximize2, Minimize2, Terminal as TerminalIcon } from 'lucide-react';
import 'xterm/css/xterm.css';

interface TerminalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const Terminal: React.FC<TerminalProps> = ({ isOpen, onClose }) => {
  const terminalRef = useRef<HTMLDivElement>(null);
  const xtermRef = useRef<XTerm | null>(null);
  const fitAddonRef = useRef<FitAddon | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const [isMaximized, setIsMaximized] = useState(false);

  useEffect(() => {
    if (!isOpen || !terminalRef.current || xtermRef.current) return;

    // Create terminal instance
    const term = new XTerm({
      theme: {
        background: getComputedStyle(document.documentElement)
          .getPropertyValue('--color-bg-primary'),
        foreground: getComputedStyle(document.documentElement)
          .getPropertyValue('--color-text-primary'),
        cursor: getComputedStyle(document.documentElement)
          .getPropertyValue('--color-accent-primary'),
      },
      fontFamily: 'JetBrains Mono, Consolas, monospace',
      fontSize: 14,
      cursorBlink: true,
      convertEol: true,
    });

    // Add addons
    const fitAddon = new FitAddon();
    const webLinksAddon = new WebLinksAddon();
    
    term.loadAddon(fitAddon);
    term.loadAddon(webLinksAddon);
    
    // Open terminal in container
    term.open(terminalRef.current);
    fitAddon.fit();

    // Store references
    xtermRef.current = term;
    fitAddonRef.current = fitAddon;

    // Connect to WebSocket for terminal backend
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const ws = new WebSocket(`${protocol}//${window.location.host}/terminal`);
    wsRef.current = ws;

    ws.onopen = () => {
      term.writeln('Welcome to CCE Terminal');
      term.writeln('');
      term.write('$ ');
    };

    ws.onmessage = (event) => {
      term.write(event.data);
    };

    ws.onerror = (error) => {
      term.writeln('\r\nConnection error. Terminal backend not available.');
      term.writeln('Please ensure the terminal server is running.');
    };

    // Handle terminal input
    term.onData((data) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(data);
      }
    });

    // Handle resize
    const handleResize = () => {
      fitAddon.fit();
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'resize',
          cols: term.cols,
          rows: term.rows
        }));
      }
    };

    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      ws.close();
      term.dispose();
      xtermRef.current = null;
      fitAddonRef.current = null;
      wsRef.current = null;
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className={`terminal-container ${isMaximized ? 'maximized' : ''}`}>
      <div className="terminal-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <TerminalIcon size={16} />
          <span className="font-medium">Terminal</span>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button
            className="btn btn-secondary p-2"
            onClick={() => setIsMaximized(!isMaximized)}
          >
            {isMaximized ? <Minimize2 size={16} /> : <Maximize2 size={16} />}
          </button>
          <button
            className="btn btn-secondary p-2"
            onClick={onClose}
          >
            <X size={16} />
          </button>
        </div>
      </div>
      <div className="terminal-body" ref={terminalRef} />
    </div>
  );
};