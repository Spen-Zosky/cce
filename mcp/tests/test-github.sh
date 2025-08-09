#!/bin/bash
echo "🐙 Testing GitHub MCP..."
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  GITHUB_TOKEN not set. This test requires GitHub authentication."
    echo "Set it with: export GITHUB_TOKEN='your-token'"
    exit 1
fi
claude --mcp-config ~/.config/claude/config.json -p "Using the github MCP, show my user information"