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
