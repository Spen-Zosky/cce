#!/usr/bin/env bash
# CCE Universal Installer - Main Entry Point
# Unified installer for the Claude Code Ecosystem
# Supports multiple environments: WSL, VM, Native Linux
# Supports multiple architectures: AMD64, ARM64

set -euo pipefail

# Version and metadata
CCE_VERSION="1.0.0"
INSTALL_DIR="$HOME/.cce-universal"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Installation profiles
PROFILE_MINIMAL="core"
PROFILE_DEVELOPER="core,web,templates,tools"
PROFILE_FULL="core,web,templates,tools,mcp,agents"

# Default settings
PROFILE="developer"
SKIP_DEPS=false
VERBOSE=false
FORCE_INSTALL=false
WITH_WEB=true
WITH_MCP=false
WITH_AGENTS=false
INSTALL_CLAUDE=true
AUTO_TEMPLATES=true

# Help function
show_help() {
    cat << 'EOF'
CCE Universal Installer

USAGE:
    ./install.sh [OPTIONS]

INSTALLATION PROFILES:
    --profile minimal     Install core components only
    --profile developer   Install core + web + templates + tools (default)  
    --profile full       Install everything including MCP and agents

COMPONENT OPTIONS:
    --with-web           Include web dashboard (default: true)
    --with-mcp           Include MCP servers integration
    --with-agents        Include multi-agent system
    --with-templates     Include project templates (default: true)
    --no-claude          Skip Claude Code installation
    --no-web             Skip web dashboard installation
    --no-templates       Skip template installation

BEHAVIOR OPTIONS:
    --force             Force reinstallation over existing setup
    --skip-deps         Skip dependency installation
    --verbose           Verbose logging output
    --help              Show this help message

EXAMPLES:
    # Standard developer installation
    ./install.sh

    # Minimal installation for CI/CD
    ./install.sh --profile minimal --no-web

    # Full installation with everything
    ./install.sh --profile full --with-mcp --with-agents

    # Force reinstall with verbose output
    ./install.sh --force --verbose

    # Quick developer setup
    ./install.sh --profile developer --with-templates

ENVIRONMENT:
    CCE_HOME            Installation directory (default: ~/.cce-universal)
    ANTHROPIC_API_KEY   Claude API key (required for AI features)
    NODE_INSTALL_METHOD Package manager preference (npm/volta/nvm)

For more information, visit: https://github.com/anthropics/cce-universal
EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --with-web)
                WITH_WEB=true
                shift
                ;;
            --no-web)
                WITH_WEB=false
                shift
                ;;
            --with-mcp)
                WITH_MCP=true
                shift
                ;;
            --with-agents)
                WITH_AGENTS=true
                shift
                ;;
            --with-templates)
                AUTO_TEMPLATES=true
                shift
                ;;
            --no-templates)
                AUTO_TEMPLATES=false
                shift
                ;;
            --no-claude)
                INSTALL_CLAUDE=false
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Validate installation requirements
validate_requirements() {
    log_step "Validating installation requirements..."
    
    # Check OS
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_error "This installer only supports Linux environments"
        log_error "Detected OS: $OSTYPE"
        exit 1
    fi
    
    # Check basic tools
    local missing_tools=()
    for tool in curl wget git bash; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install these tools before continuing"
        exit 1
    fi
    
    # Check Node.js for web components
    if [[ "$WITH_WEB" == "true" ]] && ! command -v node &> /dev/null; then
        log_warning "Node.js not found - web components will be skipped"
        WITH_WEB=false
    fi
    
    log_success "Requirements validation complete"
}

# Configure installation based on profile
configure_installation() {
    log_step "Configuring installation profile: $PROFILE"
    
    case "$PROFILE" in
        minimal)
            WITH_WEB=false
            WITH_MCP=false
            WITH_AGENTS=false
            AUTO_TEMPLATES=false
            ;;
        developer)
            WITH_WEB=true
            WITH_MCP=false
            WITH_AGENTS=false
            AUTO_TEMPLATES=true
            ;;
        full)
            WITH_WEB=true
            WITH_MCP=true
            WITH_AGENTS=true
            AUTO_TEMPLATES=true
            ;;
        *)
            log_error "Unknown profile: $PROFILE"
            log_error "Available profiles: minimal, developer, full"
            exit 1
            ;;
    esac
    
    log_debug "Configuration:"
    log_debug "  Profile: $PROFILE"
    log_debug "  Web Interface: $WITH_WEB"
    log_debug "  MCP Integration: $WITH_MCP"
    log_debug "  Multi-Agent: $WITH_AGENTS"
    log_debug "  Templates: $AUTO_TEMPLATES"
    log_debug "  Claude Code: $INSTALL_CLAUDE"
}

# Source installation modules
source_modules() {
    local modules_dir="$INSTALL_DIR/install-modules"
    
    # Check if modules exist
    if [[ ! -d "$modules_dir" ]]; then
        log_error "Installation modules not found at $modules_dir"
        log_error "Please ensure you have the complete CCE Universal package"
        exit 1
    fi
    
    # Source required modules
    local required_modules=("core-setup.sh")
    [[ "$WITH_WEB" == "true" ]] && required_modules+=("web-interface.sh")
    [[ "$AUTO_TEMPLATES" == "true" ]] && required_modules+=("templates.sh")
    required_modules+=("development-tools.sh")
    
    for module in "${required_modules[@]}"; do
        local module_path="$modules_dir/$module"
        if [[ -f "$module_path" ]]; then
            log_debug "Loading module: $module"
            source "$module_path"
        else
            log_error "Required module not found: $module"
            exit 1
        fi
    done
    
    log_success "Installation modules loaded"
}

# Check for existing installation
check_existing_installation() {
    if [[ -d "$INSTALL_DIR" ]] && [[ "$FORCE_INSTALL" != "true" ]]; then
        log_warning "Existing CCE Universal installation found at $INSTALL_DIR"
        read -p "Continue with installation? This will update existing components. [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
}

# Main installation function
run_installation() {
    log_info "Starting CCE Universal installation..."
    log_info "Version: $CCE_VERSION"
    log_info "Profile: $PROFILE"
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Run installation modules
    log_step "Installing core components..."
    setup_core
    
    if [[ "$WITH_WEB" == "true" ]]; then
        log_step "Installing web interface..."
        setup_web_interface
    fi
    
    if [[ "$AUTO_TEMPLATES" == "true" ]]; then
        log_step "Installing project templates..."
        setup_templates
    fi
    
    log_step "Installing development tools..."
    setup_development_tools
    
    log_success "CCE Universal installation complete!"
}

# Post-installation setup
post_installation() {
    log_step "Running post-installation setup..."
    
    # Set environment variables
    export CCE_ENV=$(~/.cce-universal/scripts/detect-env.sh 2>/dev/null | cut -d: -f1)
    export CCE_ARCH=$(~/.cce-universal/scripts/detect-env.sh 2>/dev/null | cut -d: -f2)
    export CCE_HOME="$INSTALL_DIR"
    
    # Update PATH in current session
    export PATH="$PATH:$INSTALL_DIR/bin"
    
    # Verify installation
    log_step "Verifying installation..."
    
    local verification_passed=true
    
    # Check core files
    if [[ ! -f "$INSTALL_DIR/scripts/detect-env.sh" ]]; then
        log_error "Core scripts missing"
        verification_passed=false
    fi
    
    # Check Claude integration
    if [[ ! -f "$HOME/.claude/CLAUDE.md" ]]; then
        log_error "Claude integration missing"
        verification_passed=false
    fi
    
    # Check web components if enabled
    if [[ "$WITH_WEB" == "true" ]] && [[ ! -f "$INSTALL_DIR/bin/cce-web" ]]; then
        log_error "Web components missing"
        verification_passed=false
    fi
    
    if [[ "$verification_passed" == "true" ]]; then
        log_success "Installation verification passed"
    else
        log_error "Installation verification failed"
        exit 1
    fi
    
    log_success "Post-installation setup complete"
}

# Display final instructions
show_completion_message() {
    cat << EOF

🎉 CCE Universal Installation Complete!

📋 Installation Summary:
   • Profile: $PROFILE
   • Environment: $CCE_ENV ($CCE_ARCH)
   • Location: $INSTALL_DIR
   • Web Interface: $([ "$WITH_WEB" = "true" ] && echo "✓ Enabled" || echo "✗ Disabled")
   • Templates: $([ "$AUTO_TEMPLATES" = "true" ] && echo "✓ Enabled" || echo "✗ Disabled")

🚀 Next Steps:
   1. Restart your terminal or run: source ~/.bashrc
   2. Verify installation: cce-info
   3. Set your API key: export ANTHROPIC_API_KEY="sk-ant-..."

🛠  Quick Commands:
   • cce-help          - Show all available commands
   • cce-init          - Initialize CCE in a project
   • cce-create        - Create new projects from templates
   • cc or claude      - Start Claude interactive mode
   • cce-dashboard     - Launch web interface

📖 Documentation:
   • Global config: ~/.claude/CLAUDE.md
   • Project config: .claude/CLAUDE.md (after cce-init)
   • Web interface: http://localhost:3456 (if enabled)

For help and updates: https://github.com/anthropics/cce-universal
EOF

    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        echo ""
        log_warning "ANTHROPIC_API_KEY not set"
        echo "   Set your API key to use Claude features:"
        echo "   export ANTHROPIC_API_KEY='sk-ant-...'"
    fi
}

# Main execution
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Show header
    echo -e "${PURPLE}╭─────────────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│       CCE Universal Installer v$CCE_VERSION       │${NC}"
    echo -e "${PURPLE}│    Claude Code Ecosystem - Universal Setup  │${NC}"
    echo -e "${PURPLE}╰─────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Validate and configure
    validate_requirements
    configure_installation
    check_existing_installation
    
    # Source installation modules
    source_modules
    
    # Run installation
    run_installation
    post_installation
    
    # Show completion
    show_completion_message
}

# Execute main function
main "$@"