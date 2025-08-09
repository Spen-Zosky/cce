#!/bin/bash
# Setup environment for Claude Code Ecosystem

export CCE_HOME="${HOME}/.cce-universal"
export CCE_CONFIG="${CCE_HOME}/config/claude-code-config.yaml"
export MCP_CONFIG="${CCE_HOME}/config/mcp-config.json"

# Add CCE scripts to PATH
export PATH="${CCE_HOME}/scripts:${PATH}"

echo "Claude Code Ecosystem environment loaded"
