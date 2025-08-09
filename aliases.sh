#!/usr/bin/env bash
# CCE Universal aliases and functions

# Environment detection
export CCE_ENV=$(~/.cce-universal/scripts/detect-env.sh 2>/dev/null | cut -d: -f1)
export CCE_ARCH=$(~/.cce-universal/scripts/detect-env.sh 2>/dev/null | cut -d: -f2)
export CCE_HOME=~/.cce-universal
export PATH="$PATH:$CCE_HOME/bin"

# Quick Claude commands
alias cc='claude'
alias ccp='claude -p'
alias ccr='claude --resume'
alias ccc='claude --continue'

# Web interface commands
alias cce-web='~/.cce-universal/bin/cce-web'

# Initialize project
cce-init() {
    ~/.cce-universal/scripts/init-project.sh "$@"
}

# Sync configuration
cce-sync() {
    ~/.cce-universal/scripts/sync.sh "$@"
}

# Quick analysis
cce-analyze() {
    claude -p "Analyze this project structure, dependencies, and architecture. Provide insights about code organization, potential improvements, and best practices applicable to this codebase."
}

# Generate tests
cce-test() {
    local file="${1}"
    if [ -z "$file" ]; then
        echo "Usage: cce-test <file>"
        return 1
    fi
    claude -p "Generate comprehensive tests for $file using the appropriate testing framework for this project. Include edge cases and error handling."
}

# Code review
cce-review() {
    local files="${1:-$(git diff --name-only HEAD 2>/dev/null || echo "all files")}"
    claude -p "Review the following files for code quality, bugs, security issues, and improvements: $files"
}

# Fix error
cce-fix() {
    if [ -z "$1" ]; then
        echo "Usage: cce-fix <error-message>"
        return 1
    fi
    claude -p "I'm getting this error: $* 
Please help me understand and fix it."
}

# Dashboard shortcut
cce-dashboard() {
    ~/.cce-universal/bin/cce-web start
    echo ""
    echo "📊 Dashboard starting..."
    echo "   Use 'cce-web stop' to shutdown"
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
    echo "NPM: $(npm -v 2>/dev/null || echo 'not found')"
    
    if [ -d .claude ]; then
        echo ""
        echo "Project Status"
        echo "=============="
        if [ -f .claude/settings.json ]; then
            echo "Type: $(grep projectType .claude/settings.json | cut -d'"' -f4)"
            echo "Name: $(grep projectName .claude/settings.json | cut -d'"' -f4)"
        fi
        echo "CCE: ✓ initialized"
    else
        echo ""
        echo "Project: not initialized (run cce-init)"
    fi
    
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo ""
        echo "API Key: ✓ configured"
    else
        echo ""
        echo "API Key: ✗ not configured"
        echo "Run: export ANTHROPIC_API_KEY='sk-ant-...'"
    fi
}

# Quick help
cce-help() {
    cat << 'HELP'
CCE Universal Commands
======================
Core Commands:
  cce-init        Initialize CCE in current project
  cce-sync        Sync configuration across environments
  cce-analyze     Analyze project structure
  cce-test        Generate tests for a file
  cce-review      Review code changes
  cce-fix         Get help with errors
  cce-info        Show CCE status
  cce-help        Show this help

Project Creation:
  cce-create      Create new projects from templates
  cce-create list Show available templates

Web Interface:
  cce-dashboard   Start web dashboard
  cce-web start   Start web server
  cce-web stop    Stop web server

Claude Commands:
  cc              Start Claude interactive
  ccp "query"     Claude print mode (quick questions)
  ccr             Resume last session
  ccc             Continue conversation

Environment Variables:
  CCE_ENV         Current environment (wsl/vm/native)
  CCE_ARCH        Current architecture (amd64/arm64)
  CCE_SYNC_REPO   Git repo for config sync
HELP
}

# Export functions
export -f cce-init cce-sync cce-analyze cce-test cce-review cce-fix cce-info cce-help cce-dashboard
