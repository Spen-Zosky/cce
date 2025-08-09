#!/bin/bash
# Install ALL MCP Servers

echo "🚀 Installing ALL MCP Servers"
echo "============================="

# Core MCP
echo "📦 Installing Core MCP..."
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-fetch
npm install -g @modelcontextprotocol/server-sqlite

# Research MCP
echo "📚 Installing Research MCP..."
npm install -g @modelcontextprotocol/server-arxiv
npm install -g @modelcontextprotocol/server-pubmed

# Development MCP
echo "🔧 Installing Dev MCP..."
npm install -g @modelcontextprotocol/server-git
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-docker

# Monitoring MCP
echo "📊 Installing Monitoring MCP..."
npm install -g @modelcontextprotocol/server-sentry

# Communication MCP
echo "💬 Installing Communication MCP..."
npm install -g @modelcontextprotocol/server-slack

echo "✅ All MCP servers installed!"
