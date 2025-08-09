#!/usr/bin/env bash
# CCE Universal aliases and functions

# Environment detection
export CCE_ENV="wsl"
export CCE_ARCH="amd64"
export CCE_HOME=~/.cce-universal
export PATH="$CCE_HOME/bin:$PATH"

# Quick Claude commands
alias cc='claude'
alias ccp='claude -p'
alias ccr='claude --resume'
alias ccc='claude --continue'

# Initialize project
cce-init() {
    echo "🚀 Initializing CCE in current directory..."
    mkdir -p .claude/commands
    cat > .claude/CLAUDE.md << EOF
# Project: $(basename $(pwd))
# Type: auto-detected
# Environment: WSL

## Project Context
This project uses CCE Universal.

## Notes
[Add your project-specific notes here]
EOF
    echo "✅ CCE initialized!"
}

# Environment info
cce-info() {
    echo "CCE Universal Status"
    echo "===================="
    echo "Environment: $CCE_ENV"
    echo "Architecture: $CCE_ARCH"
    echo "CCE Home: $CCE_HOME"
    echo "Claude: $(command -v claude &>/dev/null && echo '✓ installed' || echo '✗ not found')"
    echo "Node: $(node -v 2>/dev/null || echo 'not found')"
    
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "API Key: ✓ configured"
    else
        echo "API Key: ✗ not configured"
        echo "Run: export ANTHROPIC_API_KEY='sk-ant-...'"
    fi
}

# Quick help
cce-help() {
    echo "CCE Commands:"
    echo "  cce-init    - Initialize CCE in project"
    echo "  cce-info    - Show CCE status"
    echo "  cc          - Start Claude"
    echo "  ccp 'query' - Quick Claude query"
}

# Export functions
export -f cce-init cce-info cce-help

# Quick Winner Commands
alias cce-create="~/.cce-universal/templates/nextjs-postgres.sh"
alias cce-crud="~/.cce-universal/generators/crud-generator.sh"
alias cce-db="npx prisma studio"
alias cce-migrate="npx prisma migrate dev"

# Database helpers
cce-db-push() {
    npx prisma db push
    npx prisma generate
}

cce-db-reset() {
    npx prisma migrate reset --force
    npx prisma migrate dev --name init
}

alias cce-super="~/.cce-universal/templates/create-super-app.sh"
alias cce-auth="~/.cce-universal/generators/auth/nextauth-generator.sh"

# MCP Servers
alias cce-mcp='~/.cce-universal/mcp/mcp-manager.sh'

# Agents
alias cce-agent='~/.cce-universal/agents/agent-manager.sh'
alias cce-multi-agent='~/.cce-universal/agents/multi-agent.sh'

# Agent shortcuts
alias cce-coder='cce-agent coder'
alias cce-review='cce-agent reviewer'
alias cce-test='cce-agent tester'
alias cce-docs='cce-agent documenter'
alias cce-deploy='cce-agent deployer'

# MCP Shortcuts (use config file for all servers)
alias cce-mcp-fs='claude --mcp-config ~/.config/claude/config.json'
alias cce-mcp-gh='claude --mcp-config ~/.config/claude/config.json' 
alias cce-mcp-db='claude --mcp-config ~/.config/claude/config.json'
alias cce-mcp-web='claude --mcp-config ~/.config/claude/config.json'
alias cce-mcp-dev='claude --mcp-config ~/.config/claude/config.json'
alias cce-mcp-all='claude --mcp-config ~/.config/claude/config.json'

# MCP Test Commands
cce-mcp-test() {
    local server=$1
    if [ -z "$server" ]; then
        echo "Usage: cce-mcp-test <server-name>"
        echo "Available: filesystem, github, postgresql, fetch, memory"
        return 1
    fi
    local test_script="$HOME/.cce-universal/mcp/tests/test-$server.sh"
    if [ -f "$test_script" ]; then
        bash "$test_script"
    else
        echo "Test not found for: $server"
        echo "Available tests:"
        ls ~/.cce-universal/mcp/tests/test-*.sh 2>/dev/null | xargs -n1 basename | sed 's/test-//;s/.sh//'
    fi
}

# MCP Usage Examples
cce-mcp-examples() {
    echo "🔧 MCP Usage Examples:"
    echo ""
    echo "📁 Filesystem:"
    echo "  cce-mcp-fs -p \"Using filesystem MCP, list all .js files\""
    echo ""
    echo "🐙 GitHub:"  
    echo "  cce-mcp-gh -p \"Using github MCP, show my recent commits\""
    echo ""
    echo "🌐 Web Fetch:"
    echo "  cce-mcp-web -p \"Using fetch MCP, get content from [URL]\""
    echo ""
    echo "💾 Memory:"
    echo "  cce-mcp-all -p \"Using memory MCP, remember this project uses Next.js 14\""
    echo ""
    echo "🚀 Combined:"
    echo "  cce-mcp-dev -p \"Using filesystem MCP read package.json, github MCP check issues, and suggest improvements\""
}

# Export MCP functions
export -f cce-mcp-test cce-mcp-examples

# MCP-Agent Commands
alias cce-workflow='~/.cce-universal/agents/mcp-workflows.sh'
alias cce-chain='~/.cce-universal/agents/agent-chains.sh'

# Quick workflow shortcuts
alias cce-debug='cce-workflow debug'
alias cce-research='cce-workflow research'
alias cce-modernize='cce-workflow modernize'
alias cce-optimize='cce-workflow optimize'

# Agent shortcuts with MCP
alias cce-analyze='cce-agent analyzer'

# Project templates with MCP
cce-create-mcp() {
    local name="${1:-my-mcp-app}"
    echo "Creating MCP-enabled project: $name"
    mkdir -p "$name"
    cd "$name"
    
    # Initialize with MCP context
    claude --mcp-config ~/.config/claude/config.json -p "Create a new Next.js project structure here with:
    - TypeScript configuration
    - Tailwind CSS
    - Prisma with PostgreSQL
    - Basic authentication ready
    - MCP-friendly documentation
    Store project metadata in memory MCP."
    
    # Run workflow
    cce-workflow fullstack "$name"
}

# Export MCP functions
export -f cce-create-mcp

# Dashboard commands
alias cce-dashboard='~/.cce-universal/web/start-dashboard.sh'
alias cce-dash='cce-dashboard'

# Stop dashboard
cce-dashboard-stop() {
    if [ -f ~/.cce-universal/web/server.pid ]; then
        kill $(cat ~/.cce-universal/web/server.pid)
        rm ~/.cce-universal/web/server.pid
        echo "✅ Dashboard stopped"
    else
        echo "❌ Dashboard not running"
    fi
}

# Export dashboard functions
export -f cce-dashboard-stop
