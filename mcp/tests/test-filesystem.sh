#!/bin/bash
echo "🗂️ Testing Filesystem MCP..."
echo "This should list files in current directory:"
claude --mcp-config ~/.config/claude/config.json -p "Using the filesystem MCP, list all files in the current directory with their sizes"