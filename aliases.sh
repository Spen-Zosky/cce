#!/usr/bin/env bash
# CCE Universal aliases and functions

# Environment detection
export CCE_ENV="wsl"
export CCE_ARCH="amd64"
export CCE_HOME=~/.cce-universal
export PATH="$PATH:$CCE_HOME/bin"

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
