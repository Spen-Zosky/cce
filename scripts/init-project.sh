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
cat > .claude/CLAUDE.md << EOF
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
