#!/bin/bash
# MCP Integration Status Check

echo "🔍 MCP Integration Status"
echo "========================="
echo ""

# Check config file
if [ -f "$HOME/.config/claude/config.json" ]; then
    echo "✅ Configuration file exists"
    echo "   Location: ~/.config/claude/config.json"
else
    echo "❌ Configuration file missing"
fi
echo ""

# Check installed servers
echo "📦 Installed MCP Servers:"
for server in filesystem github postgresql fetch memory everything sequential-thinking sentry firecrawl; do
    case $server in
        filesystem) pkg="@modelcontextprotocol/server-filesystem" ;;
        github) pkg="@modelcontextprotocol/server-github" ;;
        postgresql) pkg="postgres-mcp-server" ;;
        fetch) pkg="@mokei/mcp-fetch" ;;
        memory) pkg="@modelcontextprotocol/server-memory" ;;
        everything) pkg="@modelcontextprotocol/server-everything" ;;
        sequential-thinking) pkg="@modelcontextprotocol/server-sequential-thinking" ;;
        sentry) pkg="@sentry/mcp-server" ;;
        firecrawl) pkg="firecrawl-mcp" ;;
    esac
    
    if [ -d "$HOME/.cce-universal/mcp-servers/node_modules/$pkg" ]; then
        echo "  ✅ $server"
    else
        echo "  ❌ $server (missing)"
    fi
done
echo ""

# Check environment variables
echo "🔐 Environment Variables:"
[ -n "$GITHUB_TOKEN" ] && echo "  ✅ GITHUB_TOKEN set" || echo "  ⚠️  GITHUB_TOKEN not set (optional)"
[ -n "$DATABASE_URL" ] && echo "  ✅ DATABASE_URL set" || echo "  ⚠️  DATABASE_URL not set (optional)"
[ -n "$SENTRY_AUTH_TOKEN" ] && echo "  ✅ SENTRY_AUTH_TOKEN set" || echo "  ⚠️  SENTRY_AUTH_TOKEN not set (optional)"
[ -n "$FIRECRAWL_API_KEY" ] && echo "  ✅ FIRECRAWL_API_KEY set" || echo "  ⚠️  FIRECRAWL_API_KEY not set (optional)"
echo ""

# Check test scripts
echo "🧪 Test Scripts:"
if [ -d "$HOME/.cce-universal/mcp/tests" ]; then
    echo "  ✅ Test directory exists"
    echo "  Available tests:"
    ls ~/.cce-universal/mcp/tests/test-*.sh 2>/dev/null | xargs -n1 basename | sed 's/test-//;s/.sh//' | sed 's/^/    - /'
else
    echo "  ❌ Test directory missing"
fi
echo ""

echo "📋 Quick Test Commands:"
echo "  cce-mcp-test filesystem   # Test file operations"
echo "  cce-mcp-test fetch       # Test web fetching"
echo "  cce-mcp-test memory      # Test persistent memory"
echo ""
echo "🚀 Usage Examples:"
echo "  cce-mcp-examples         # Show usage examples"
echo "  cce-mcp-fs              # Use filesystem MCP"
echo "  cce-mcp-dev             # Use dev combo (fs+github+db)"
echo "  cce-mcp-all             # Use all MCP servers"