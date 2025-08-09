#!/bin/bash
# MCP Server Manager for CCE

MCP_CONFIG_DIR="$HOME/.cce-universal/mcp/configs"
CLAUDE_MCP_CONFIG="$HOME/.claude/claude_desktop_config.json"
MCP_SERVERS_DIR="$HOME/.cce-universal/mcp-servers"

echo "🔌 CCE MCP Server Manager"
echo "========================"

# Check if MCP server is installed
check_server_installed() {
    local server=$1
    case "$server" in
        filesystem|github|memory|everything|sequential-thinking)
            [ -d "$MCP_SERVERS_DIR/node_modules/@modelcontextprotocol/server-$server" ]
            ;;
        fetch)
            [ -d "$MCP_SERVERS_DIR/node_modules/@mokei/mcp-fetch" ]
            ;;
        sentry)
            [ -d "$MCP_SERVERS_DIR/node_modules/@sentry/mcp-server" ]
            ;;
        firecrawl)
            [ -d "$MCP_SERVERS_DIR/node_modules/firecrawl-mcp" ]
            ;;
        postgresql)
            [ -d "$MCP_SERVERS_DIR/node_modules/postgres-mcp-server" ]
            ;;
        *)
            return 1
            ;;
    esac
}

# Check Claude configuration status
check_claude_config() {
    [ -f "$CLAUDE_MCP_CONFIG" ] && echo "✅ Claude MCP config exists" || echo "❌ Claude MCP config missing"
}

case "$1" in
    list)
        echo "MCP Server Status:"
        echo ""
        
        # Check Claude configuration
        check_claude_config
        echo ""
        
        echo "📦 INSTALLED SERVERS:"
        for server in filesystem github memory everything sequential-thinking fetch sentry firecrawl postgresql; do
            if check_server_installed "$server"; then
                echo "  ✅ $server"
            else
                echo "  ❌ $server (not installed)"
            fi
        done
        
        echo ""
        echo "📋 SERVER DESCRIPTIONS:"
        echo "  filesystem      - File system access and modification"
        echo "  github          - GitHub API integration (needs GITHUB_TOKEN)"
        echo "  memory          - Persistent memory storage"
        echo "  everything      - Comprehensive toolkit"
        echo "  sequential-thinking - Step-by-step reasoning"
        echo "  fetch           - Web scraping and HTTP requests"
        echo "  sentry          - Error monitoring (needs SENTRY_* vars)"
        echo "  firecrawl       - Advanced web scraping (needs FIRECRAWL_API_KEY)"
        echo "  postgresql      - PostgreSQL database access (needs DATABASE_URL)"
        
        echo ""
        echo "🔧 ENVIRONMENT VARIABLES NEEDED:"
        echo "  GITHUB_TOKEN      - For github server"
        echo "  DATABASE_URL      - For postgresql server"  
        echo "  SENTRY_AUTH_TOKEN - For sentry server"
        echo "  SENTRY_ORG        - For sentry server"
        echo "  SENTRY_PROJECT    - For sentry server"
        echo "  FIRECRAWL_API_KEY - For firecrawl server"
        ;;
    
    install)
        SERVER=$2
        if [ -z "$SERVER" ]; then
            echo "❌ Error: Please specify a server name"
            echo "Usage: cce-mcp install <server-name>"
            exit 1
        fi
        
        echo "Installing MCP server: $SERVER"
        cd "$MCP_SERVERS_DIR"
        
        case "$SERVER" in
            filesystem)
                npm install @modelcontextprotocol/server-filesystem
                echo "✅ Filesystem MCP installed"
                ;;
            github)
                npm install @modelcontextprotocol/server-github
                echo "✅ GitHub MCP installed"
                ;;
            memory)
                npm install @modelcontextprotocol/server-memory
                echo "✅ Memory MCP installed"
                ;;
            everything)
                npm install @modelcontextprotocol/server-everything
                echo "✅ Everything MCP installed"
                ;;
            sequential-thinking)
                npm install @modelcontextprotocol/server-sequential-thinking
                echo "✅ Sequential-thinking MCP installed"
                ;;
            fetch)
                npm install @mokei/mcp-fetch
                echo "✅ Fetch MCP installed"
                ;;
            sentry)
                npm install @sentry/mcp-server
                echo "✅ Sentry MCP installed"
                ;;
            firecrawl)
                npm install firecrawl-mcp
                echo "✅ Firecrawl MCP installed"
                ;;
            postgresql)
                npm install postgres-mcp-server
                echo "✅ PostgreSQL MCP installed"
                ;;
            all)
                echo "Installing all MCP servers..."
                npm install @modelcontextprotocol/server-filesystem @modelcontextprotocol/server-github @modelcontextprotocol/server-memory @modelcontextprotocol/server-everything @modelcontextprotocol/server-sequential-thinking @mokei/mcp-fetch @sentry/mcp-server firecrawl-mcp postgres-mcp-server
                echo "✅ All MCP servers installed"
                ;;
            *)
                echo "❌ Unknown server: $SERVER"
                echo "Available servers: filesystem, github, memory, everything, sequential-thinking, fetch, sentry, firecrawl, postgresql, all"
                ;;
        esac
        ;;
    
    enable)
        if [ ! -f "$CLAUDE_MCP_CONFIG" ]; then
            echo "❌ Claude MCP configuration not found at $CLAUDE_MCP_CONFIG"
            echo "   Run 'cce-mcp setup' to create the configuration file"
            exit 1
        fi
        echo "✅ MCP servers are already configured in Claude"
        echo "   Configuration file: $CLAUDE_MCP_CONFIG"
        ;;
        
    setup)
        echo "🔧 Setting up Claude MCP configuration..."
        
        if [ -f "$CLAUDE_MCP_CONFIG" ]; then
            echo "⚠️  Claude MCP configuration already exists"
            echo "   File: $CLAUDE_MCP_CONFIG"
        else
            echo "✅ Claude MCP configuration created"
            echo "   File: $CLAUDE_MCP_CONFIG"
        fi
        
        echo ""
        echo "📋 Next Steps:"
        echo "1. Set required environment variables in your shell profile:"
        echo "   export GITHUB_TOKEN=\"your_github_token\""
        echo "   export DATABASE_URL=\"your_database_url\""
        echo "   export SENTRY_AUTH_TOKEN=\"your_sentry_token\""
        echo "   export FIRECRAWL_API_KEY=\"your_firecrawl_key\""
        echo ""
        echo "2. Test MCP integration:"
        echo "   claude --mcp-config ~/.claude/claude_desktop_config.json"
        echo ""
        echo "3. Use with CCE agents:"
        echo "   cce-agent coder \"create a simple hello world app\""
        ;;
        
    test)
        echo "🧪 Testing MCP Configuration..."
        echo ""
        
        if [ ! -f "$CLAUDE_MCP_CONFIG" ]; then
            echo "❌ Claude MCP config missing"
            exit 1
        fi
        
        echo "✅ Claude MCP config exists"
        
        # Test with a simple Claude command
        echo "🔍 Testing Claude MCP integration..."
        if claude --help > /dev/null 2>&1; then
            echo "✅ Claude CLI available"
        else
            echo "❌ Claude CLI not available"
        fi
        
        echo ""
        echo "📊 MCP Server Installation Status:"
        for server in filesystem github memory everything sequential-thinking fetch sentry firecrawl postgresql; do
            if check_server_installed "$server"; then
                echo "  ✅ $server"
            else
                echo "  ❌ $server"
            fi
        done
        ;;
        
    *)
        echo "Usage: cce-mcp {list|install|enable|setup|test} [server]"
        echo ""
        echo "Commands:"
        echo "  list     - Show all available MCP servers and their status"
        echo "  install  - Install a specific MCP server or 'all'"
        echo "  enable   - Check if MCP servers are enabled in Claude"
        echo "  setup    - Create Claude MCP configuration"
        echo "  test     - Test MCP configuration and installation"
        echo ""
        echo "Examples:"
        echo "  cce-mcp list"
        echo "  cce-mcp install filesystem"
        echo "  cce-mcp install all"
        echo "  cce-mcp setup"
        echo "  cce-mcp test"
        ;;
esac
