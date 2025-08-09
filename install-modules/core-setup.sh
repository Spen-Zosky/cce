#!/bin/bash
# CCE Core Setup Module
# Handles basic environment detection and core directory structure

setup_core_environment() {
    log_step "Setting up core CCE environment..."
    
    # Backup existing installations
    if [ -d ~/.claude ] || [ -d ~/.cce ]; then
        log_warning "Existing CCE installation found"
        BACKUP_DIR=~/.cce-backup-$(date +%Y%m%d-%H%M%S)
        mkdir -p "$BACKUP_DIR"
        [ -d ~/.claude ] && cp -r ~/.claude "$BACKUP_DIR/"
        [ -d ~/.cce ] && cp -r ~/.cce "$BACKUP_DIR/"
        log_success "Backup created: $BACKUP_DIR"
    fi
    
    # Install Claude Code if needed
    if ! command -v claude &> /dev/null; then
        log_step "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
        log_success "Claude Code installed"
    else
        log_success "Claude Code already installed ($(claude --version 2>/dev/null || echo 'version unknown'))"
    fi
    
    # Create CCE Universal structure
    log_step "Creating CCE Universal structure..."
    
    # Core directories
    mkdir -p ~/.cce-universal/{core,adapters,sync,scripts,templates,config}
    mkdir -p ~/.cce-universal/web/{server,client,api,dashboard,public,data}
    mkdir -p ~/.cce-universal/bin
    mkdir -p ~/.claude/{commands,hooks,templates}
    
    log_success "Core environment setup complete"
}

setup_core_configuration() {
    log_step "Creating core configuration files..."
    
    # Main CCE config
    cat > ~/.cce-universal/config/cce.json << 'EOF'
{
  "version": "1.0.0",
  "type": "universal",
  "features": {
    "autoDetect": true,
    "crossPlatform": true,
    "syncEnabled": true
  },
  "environments": {
    "wsl": {
      "pathSeparator": "/",
      "lineEnding": "auto",
      "gitConfig": {
        "core.autocrlf": "input"
      }
    },
    "vm": {
      "pathSeparator": "/",
      "lineEnding": "lf"
    },
    "native": {
      "pathSeparator": "/",
      "lineEnding": "lf"
    }
  },
  "sync": {
    "method": "git",
    "remote": "",
    "autoSync": false
  }
}
EOF
    
    log_success "Core configuration created"
}

setup_core_scripts() {
    log_step "Installing core scripts..."
    
    # Environment detector script
    cat > ~/.cce-universal/scripts/detect-env.sh << 'EOF'
#!/usr/bin/env bash
# Detect current environment

ENV_TYPE="unknown"
ARCH=$(uname -m)

# Normalize architecture
case "$ARCH" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
esac

# Detect environment type
if grep -qi microsoft /proc/version 2>/dev/null; then
    ENV_TYPE="wsl"
elif [ -f /.dockerenv ]; then
    ENV_TYPE="docker"
elif [ -f /sys/class/dmi/id/product_name ] 2>/dev/null; then
    PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
    if [[ "$PRODUCT" == *"Virtual"* ]] || [[ "$PRODUCT" == *"VM"* ]]; then
        ENV_TYPE="vm"
    else
        ENV_TYPE="native"
    fi
else
    ENV_TYPE="native"
fi

echo "$ENV_TYPE:$ARCH"
EOF
    chmod +x ~/.cce-universal/scripts/detect-env.sh
    
    # Environment adapter
    cat > ~/.cce-universal/adapters/env-adapter.sh << 'EOF'
#!/bin/bash
# Environment-specific adaptations

get_home_dir() {
    echo "$HOME"
}

get_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/package.json" ] || [ -f "$dir/.git/config" ] || [ -f "$dir/.claude/settings.json" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

normalize_path() {
    local path="$1"
    # Convert Windows paths if in WSL
    if [[ "$path" =~ ^[A-Za-z]: ]]; then
        if command -v wslpath &> /dev/null; then
            wslpath -u "$path"
        else
            echo "$path"
        fi
    else
        echo "$path"
    fi
}

detect_line_ending() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "auto"  # Let git handle it
    else
        echo "lf"
    fi
}
EOF
    chmod +x ~/.cce-universal/adapters/env-adapter.sh
    
    log_success "Core scripts installed"
}

setup_claude_integration() {
    log_step "Setting up Claude integration..."
    
    # Universal CLAUDE.md
    cat > ~/.claude/CLAUDE.md << 'EOF'
# CCE Universal Context

## System Information
- Environment: Multi-Platform (WSL/VM/Native Linux)
- Architecture: Cross-Architecture (AMD64/ARM64)
- Mode: Universal Configuration

## Development Philosophy

### Portability First
- Write code that works everywhere
- Avoid platform-specific dependencies
- Use relative paths, not absolute
- Test on multiple environments

### Code Standards
- Clean, readable, maintainable code
- Comprehensive error handling
- Meaningful variable names
- Document complex logic

### Git Workflow
- Conventional commits (feat:, fix:, docs:)
- Branch protection for main
- PR reviews when possible
- Clean commit history

### Security
- Environment variables for secrets
- Never commit sensitive data
- Input validation always
- Principle of least privilege

## Cross-Platform Considerations
- Use `#!/usr/bin/env bash` not `#!/bin/bash`
- Handle both LF and CRLF line endings
- Path separators: always forward slash
- Case sensitivity: assume case-sensitive

## Available Tools
- `/help` - Show available commands
- `/sync` - Sync configuration across environments
- `/analyze` - Analyze project structure
- `/test` - Run tests appropriately

## Environment Variables
- `CCE_ENV` - Current environment type (wsl/vm/native)
- `CCE_ARCH` - Current architecture (amd64/arm64)
- `CCE_HOME` - CCE installation directory
EOF
    
    # Universal settings.json
    cat > ~/.claude/settings.json << 'EOF'
{
  "theme": "dark",
  "autoUpdaterStatus": "enabled",
  "defaultModel": "claude-3-7-sonnet-20250219",
  "telemetry": false,
  "verbose": false,
  "hooks": [
    {
      "matcher": "Edit",
      "hooks": [
        {
          "type": "command",
          "command": "~/.cce-universal/scripts/universal-format.sh \"$CLAUDE_FILE_PATHS\""
        }
      ]
    }
  ],
  "defaultPermissions": {
    "Bash": "allow",
    "Edit": "allow",
    "Write": "allow",
    "Read": "allow"
  },
  "environmentVariables": {
    "CCE_ENV": "${CCE_ENV}",
    "CCE_ARCH": "${CCE_ARCH}"
  }
}
EOF
    
    log_success "Claude integration configured"
}

# Main function for core setup
setup_core() {
    setup_core_environment
    setup_core_configuration
    setup_core_scripts
    setup_claude_integration
}