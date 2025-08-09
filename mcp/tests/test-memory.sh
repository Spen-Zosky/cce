#!/bin/bash
echo "🧠 Testing Memory MCP..."
echo "Storing test data..."
claude --mcp-config ~/.config/claude/config.json -p "Using the memory MCP, remember this test: CCE MCP Integration Test Successful at $(date)"
echo ""
echo "Retrieving test data..."
claude --mcp-config ~/.config/claude/config.json -p "Using the memory MCP, what did I ask you to remember about CCE MCP Integration Test?"