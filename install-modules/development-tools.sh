#!/bin/bash
# CCE Development Tools Module
# Handles advanced development utilities and helpers

setup_universal_formatter() {
    log_step "Installing universal code formatter..."
    
    cat > ~/.cce-universal/scripts/universal-format.sh << 'EOF'
#!/usr/bin/env bash
# Universal formatter - works across all platforms

FILE="$1"
[ ! -f "$FILE" ] && exit 0

# Source environment adapter
source ~/.cce-universal/adapters/env-adapter.sh

# Normalize path for cross-platform
FILE=$(normalize_path "$FILE")

# Get file extension
EXT="${FILE##*.}"
FILENAME=$(basename "$FILE")

# Detect and apply appropriate formatter
format_javascript() {
    if command -v prettier &> /dev/null; then
        prettier --write "$FILE" 2>/dev/null
    elif command -v npx &> /dev/null; then
        npx -y prettier --write "$FILE" 2>/dev/null
    fi
}

format_python() {
    if command -v black &> /dev/null; then
        black "$FILE" 2>/dev/null
    elif command -v autopep8 &> /dev/null; then
        autopep8 --in-place "$FILE" 2>/dev/null
    elif command -v ruff &> /dev/null; then
        ruff format "$FILE" 2>/dev/null
    fi
}

format_rust() {
    if command -v rustfmt &> /dev/null; then
        rustfmt "$FILE" 2>/dev/null
    fi
}

format_go() {
    if command -v gofmt &> /dev/null; then
        gofmt -w "$FILE" 2>/dev/null
    elif command -v goimports &> /dev/null; then
        goimports -w "$FILE" 2>/dev/null
    fi
}

# Apply formatting based on extension
case "$EXT" in
    js|jsx|ts|tsx|json|md|mdx|yaml|yml)
        format_javascript ;;
    py|pyw)
        format_python ;;
    rs)
        format_rust ;;
    go)
        format_go ;;
    sh|bash)
        if command -v shfmt &> /dev/null; then
            shfmt -w "$FILE" 2>/dev/null
        fi ;;
esac

# TypeScript type checking
if [[ "$EXT" =~ ^(ts|tsx)$ ]]; then
    if [ -f "tsconfig.json" ] && command -v npx &> /dev/null; then
        npx -y tsc --noEmit --skipLibCheck "$FILE" 2>/dev/null || true
    fi
fi
EOF
    chmod +x ~/.cce-universal/scripts/universal-format.sh
    
    log_success "Universal formatter installed"
}

setup_project_initializer() {
    log_step "Installing project initializer..."
    
    cat > ~/.cce-universal/scripts/init-project.sh << 'EOF'
#!/usr/bin/env bash
# Universal project initializer

source ~/.cce-universal/adapters/env-adapter.sh

PROJECT_DIR="${1:-$(get_project_root)}"
cd "$PROJECT_DIR" || exit 1

echo "🚀 Initializing CCE Universal in $(basename "$PROJECT_DIR")"

# Create .claude directory
mkdir -p .claude/{commands,hooks,config}

# Detect project type
detect_project_type() {
    local type="generic"
    
    # Node/JavaScript/TypeScript
    if [ -f "package.json" ]; then
        type="node"
        if grep -q '"react"' package.json 2>/dev/null; then
            type="react"
        elif grep -q '"vue"' package.json 2>/dev/null; then
            type="vue"
        elif grep -q '"@angular/core"' package.json 2>/dev/null; then
            type="angular"
        elif grep -q '"next"' package.json 2>/dev/null; then
            type="nextjs"
        fi
    # Python
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
        type="python"
        if [ -f "pyproject.toml" ] && grep -q "django" pyproject.toml 2>/dev/null; then
            type="django"
        elif [ -f "requirements.txt" ] && grep -q "flask" requirements.txt 2>/dev/null; then
            type="flask"
        fi
    # Rust
    elif [ -f "Cargo.toml" ]; then
        type="rust"
    # Go
    elif [ -f "go.mod" ]; then
        type="go"
    # Ruby
    elif [ -f "Gemfile" ]; then
        type="ruby"
    # Java
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        type="java"
    fi
    
    echo "$type"
}

PROJECT_TYPE=$(detect_project_type)
echo "📦 Detected project type: $PROJECT_TYPE"

# Get environment info
ENV_INFO=$(~/.cce-universal/scripts/detect-env.sh 2>/dev/null || echo "unknown:unknown")
ENV_TYPE="${ENV_INFO%%:*}"
ARCH="${ENV_INFO##*:}"

# Create project CLAUDE.md
cat > .claude/CLAUDE.md << PROJECTMD
# Project: $(basename "$PROJECT_DIR")
# Type: $PROJECT_TYPE
# Environment: $ENV_TYPE ($ARCH)
# Initialized: $(date -u +"%Y-%m-%d %H:%M UTC")

## Project Context
@include ~/.claude/CLAUDE.md

## Project Configuration
- Type: $PROJECT_TYPE
- Path: $PROJECT_DIR
- VCS: $([ -d .git ] && echo "Git" || echo "None")

## Project Specific Information
[TODO: Add project description]

### Architecture
[TODO: Describe system architecture]

### Key Features
[TODO: List main features]

### Dependencies
$(if [ -f "package.json" ]; then
    echo "See package.json for dependencies"
elif [ -f "requirements.txt" ]; then
    echo "See requirements.txt for dependencies"
elif [ -f "go.mod" ]; then
    echo "See go.mod for dependencies"
else
    echo "[TODO: List key dependencies]"
fi)

### Development Workflow
[TODO: Describe development process]

### Testing Strategy
[TODO: Describe testing approach]

## Important Notes
- This project uses CCE Universal for cross-platform compatibility
- Configuration syncs across WSL, VMs, and native Linux
- Environment: $ENV_TYPE, Architecture: $ARCH
PROJECTMD

# Create project settings
cat > .claude/settings.json << PROJECTSETTINGS
{
  "extends": "~/.claude/settings.json",
  "projectType": "$PROJECT_TYPE",
  "projectName": "$(basename "$PROJECT_DIR")",
  "environment": {
    "type": "$ENV_TYPE",
    "arch": "$ARCH"
  },
  "sync": {
    "enabled": true,
    "exclude": ["node_modules", ".git", "dist", "build", "target"]
  }
}
PROJECTSETTINGS

# Add project-specific commands based on type
case "$PROJECT_TYPE" in
    node|react|vue|angular|nextjs)
        cat > .claude/commands/dev.md << 'CMDEOF'
Start development server
Usage: /dev
Execute: npm run dev || npm start
CMDEOF
        
        cat > .claude/commands/test.md << 'CMDEOF'
Run tests
Usage: /test [pattern]
Execute: npm test $ARGUMENTS
CMDEOF
        
        cat > .claude/commands/build.md << 'CMDEOF'
Build for production
Usage: /build
Execute: npm run build
CMDEOF
        ;;
    
    python|django|flask)
        cat > .claude/commands/test.md << 'CMDEOF'
Run Python tests
Usage: /test [pattern]
Execute: pytest $ARGUMENTS || python -m pytest $ARGUMENTS
CMDEOF
        
        if [ "$PROJECT_TYPE" = "django" ]; then
            cat > .claude/commands/runserver.md << 'CMDEOF'
Start Django development server
Usage: /runserver [port]
Execute: python manage.py runserver ${ARGUMENTS:-8000}
CMDEOF
        fi
        ;;
    
    rust)
        cat > .claude/commands/build.md << 'CMDEOF'
Build Rust project
Usage: /build [--release]
Execute: cargo build $ARGUMENTS
CMDEOF
        
        cat > .claude/commands/test.md << 'CMDEOF'
Run Rust tests
Usage: /test
Execute: cargo test
CMDEOF
        ;;
    
    go)
        cat > .claude/commands/run.md << 'CMDEOF'
Run Go application
Usage: /run
Execute: go run .
CMDEOF
        
        cat > .claude/commands/test.md << 'CMDEOF'
Run Go tests
Usage: /test
Execute: go test ./...
CMDEOF
        ;;
esac

# Create .gitignore if not exists
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'GITEOF'
# CCE
.claude/settings.local.json
.claude/.cache/
.cce-sync/

# Environment
.env
.env.local
*.env

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db
GITEOF
fi

echo "✅ CCE Universal initialized for $PROJECT_TYPE project!"
echo ""
echo "Next steps:"
echo "1. Edit .claude/CLAUDE.md with project details"
echo "2. Run 'cc' or 'claude' to start"
echo "3. Use 'cce-sync' to sync across environments"
EOF
    chmod +x ~/.cce-universal/scripts/init-project.sh
    
    log_success "Project initializer installed"
}

setup_sync_utility() {
    log_step "Installing sync utility..."
    
    cat > ~/.cce-universal/scripts/sync.sh << 'EOF'
#!/usr/bin/env bash
# Sync CCE configuration across environments

SYNC_REPO="${CCE_SYNC_REPO:-}"
SYNC_BRANCH="${CCE_SYNC_BRANCH:-main}"

sync_push() {
    if [ -z "$SYNC_REPO" ]; then
        echo "❌ No sync repository configured"
        echo "Set CCE_SYNC_REPO environment variable"
        return 1
    fi
    
    echo "📤 Pushing CCE configuration..."
    
    # Create temporary sync directory
    SYNC_DIR=$(mktemp -d)
    cd "$SYNC_DIR" || exit 1
    
    # Initialize git repo
    git init
    git remote add origin "$SYNC_REPO"
    
    # Copy configuration files
    cp -r ~/.claude .claude
    cp -r ~/.cce-universal .cce-universal
    
    # Create sync manifest
    cat > sync-manifest.json << MANIFEST
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": "$(~/.cce-universal/scripts/detect-env.sh)",
  "hostname": "$(hostname)",
  "version": "1.0.0"
}
MANIFEST
    
    # Commit and push
    git add .
    git commit -m "CCE sync from $(hostname) at $(date -u +"%Y-%m-%d %H:%M UTC")"
    git push -u origin "$SYNC_BRANCH" --force
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$SYNC_DIR"
    
    echo "✅ Configuration synced"
}

sync_pull() {
    if [ -z "$SYNC_REPO" ]; then
        echo "❌ No sync repository configured"
        return 1
    fi
    
    echo "📥 Pulling CCE configuration..."
    
    # Backup current config
    BACKUP_DIR=~/.cce-backup-$(date +%Y%m%d-%H%M%S)
    mkdir -p "$BACKUP_DIR"
    [ -d ~/.claude ] && cp -r ~/.claude "$BACKUP_DIR/"
    [ -d ~/.cce-universal ] && cp -r ~/.cce-universal "$BACKUP_DIR/"
    
    # Pull configuration
    SYNC_DIR=$(mktemp -d)
    cd "$SYNC_DIR" || exit 1
    
    git clone "$SYNC_REPO" . --branch "$SYNC_BRANCH" --depth 1
    
    # Apply configuration
    [ -d .claude ] && cp -r .claude ~/
    [ -d .cce-universal ] && cp -r .cce-universal ~/
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$SYNC_DIR"
    
    echo "✅ Configuration pulled"
    echo "📁 Backup saved to: $BACKUP_DIR"
}

case "${1:-}" in
    push) sync_push ;;
    pull) sync_pull ;;
    *)
        echo "Usage: $0 {push|pull}"
        echo ""
        echo "Configure with:"
        echo "  export CCE_SYNC_REPO='git@github.com:username/cce-config.git'"
        echo "  export CCE_SYNC_BRANCH='main'"
        ;;
esac
EOF
    chmod +x ~/.cce-universal/scripts/sync.sh
    
    log_success "Sync utility installed"
}

setup_bash_integration() {
    log_step "Setting up Bash integration..."
    
    # Bash aliases and functions
    cat > ~/.cce-universal/aliases.sh << 'EOF'
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
EOF
    
    # Add to bashrc if not present
    if ! grep -q "cce-universal/aliases.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# CCE Universal" >> ~/.bashrc
        echo "[ -f ~/.cce-universal/aliases.sh ] && source ~/.cce-universal/aliases.sh" >> ~/.bashrc
    fi
    
    log_success "Bash integration setup complete"
}

# Main function for development tools setup
setup_development_tools() {
    setup_universal_formatter
    setup_project_initializer
    setup_sync_utility
    setup_bash_integration
}