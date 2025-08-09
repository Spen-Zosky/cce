#!/bin/bash
# Setup MCP for Claude

echo "🔧 Setting up MCP for Claude"
echo "============================"

CONFIG_FILE="$HOME/.config/claude/claude_desktop_config.json"

# Create config directory
mkdir -p "$HOME/.config/claude"

# Create Claude MCP config
cat > "$CONFIG_FILE" << 'CONFIG'
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["/usr/local/lib/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js", "/home/ubuntu"]
    },
    "arxiv": {
      "command": "node",
      "args": ["/usr/local/lib/node_modules/@modelcontextprotocol/server-arxiv/dist/index.js"]
    },
    "fetch": {
      "command": "node",
      "args": ["/usr/local/lib/node_modules/@modelcontextprotocol/server-fetch/dist/index.js"]
    }
  }
}
CONFIG

echo "✅ MCP configured for Claude!"
echo ""
echo "IMPORTANT: When using Claude, you can now:"
echo "  - Access files with filesystem MCP"
echo "  - Search papers with arXiv MCP"
echo "  - Fetch web content with fetch MCP"
