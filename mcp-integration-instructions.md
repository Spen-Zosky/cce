# MCP Integration - Complete Setup Instructions

## Context
You are helping me complete the MCP (Model Context Protocol) integration for CCE (Claude Code Ecosystem). We have 9 MCP servers already installed in `~/.cce-universal/mcp-servers/` but they need proper configuration to work with Claude CLI.

## Current State
- ✅ 9 MCP servers installed: filesystem, github, postgresql, fetch, memory, everything, sequential-thinking, sentry, firecrawl
- ⚠️ Missing proper configuration file for Claude CLI
- ⚠️ Need test scripts and usage shortcuts

## Task 1: Create MCP Configuration File

Create the main configuration file for Claude CLI at `~/.config/claude/config.json`:

```bash
mkdir -p ~/.config/claude
```

Then create the config file with this content (replace `/home/ubuntu` with actual home path):

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js",
        "/home/ubuntu"
      ],
      "env": {}
    },
    "github": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/@modelcontextprotocol/server-github/dist/index.js"
      ],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "postgresql": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/postgres-mcp-server/dist/index.js",
        "${DATABASE_URL:-postgresql://localhost/postgres}"
      ],
      "env": {}
    },
    "fetch": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/@mokei/mcp-fetch/dist/index.js"
      ],
      "env": {}
    },
    "memory": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/@modelcontextprotocol/server-memory/dist/index.js"
      ],
      "env": {}
    },
    "everything": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/@modelcontextprotocol/server-everything/dist/index.js"
      ],
      "env": {}
    },
    "sequential-thinking": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/@modelcontextprotocol/server-sequential-thinking/dist/index.js"
      ],
      "env": {}
    },
    "sentry": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/@sentry/mcp-server/dist/index.js"
      ],
      "env": {
        "SENTRY_AUTH_TOKEN": "${SENTRY_AUTH_TOKEN}",
        "SENTRY_ORG": "${SENTRY_ORG}",
        "SENTRY_PROJECT": "${SENTRY_PROJECT}"
      }
    },
    "firecrawl": {
      "command": "node",
      "args": [
        "/home/ubuntu/.cce-universal/mcp-servers/node_modules/firecrawl-mcp/dist/index.js"
      ],
      "env": {
        "FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY}"
      }
    }
  }
}
```

## Task 2: Create Environment Template

Create template for API credentials at `~/.cce-universal/config/mcp-env.template`:

```bash
# MCP Server Environment Variables
# Copy this to ~/.cce-universal/config/mcp-env and fill in your values

# GitHub Integration (optional - get token from https://github.com/settings/tokens)
export GITHUB_TOKEN="your-github-token-here"

# PostgreSQL Connection (optional - for database operations)
export DATABASE_URL="postgresql://user:password@localhost/dbname"

# Sentry Error Monitoring (optional)
export SENTRY_AUTH_TOKEN="your-sentry-auth-token"
export SENTRY_ORG="your-sentry-org"
export SENTRY_PROJECT="your-sentry-project"

# Firecrawl Web Scraping (optional)
export FIRECRAWL_API_KEY="your-firecrawl-api-key"
```

## Task 3: Create Test Scripts

Create test directory and individual test scripts:

```bash
mkdir -p ~/.cce-universal/mcp/tests
```

### Test Script 1: `~/.cce-universal/mcp/tests/test-filesystem.sh`
```bash
#!/bin/bash
echo "🗂️ Testing Filesystem MCP..."
echo "This should list files in current directory:"
claude --mcp-servers filesystem -p "Using the filesystem MCP, list all files in the current directory with their sizes"
```

### Test Script 2: `~/.cce-universal/mcp/tests/test-github.sh`
```bash
#!/bin/bash
echo "🐙 Testing GitHub MCP..."
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  GITHUB_TOKEN not set. This test requires GitHub authentication."
    echo "Set it with: export GITHUB_TOKEN='your-token'"
    exit 1
fi
claude --mcp-servers github -p "Using the github MCP, show my user information"
```

### Test Script 3: `~/.cce-universal/mcp/tests/test-fetch.sh`
```bash
#!/bin/bash
echo "🌐 Testing Fetch MCP..."
claude --mcp-servers fetch -p "Using the fetch MCP, get the title from https://example.com"
```

### Test Script 4: `~/.cce-universal/mcp/tests/test-memory.sh`
```bash
#!/bin/bash
echo "🧠 Testing Memory MCP..."
echo "Storing test data..."
claude --mcp-servers memory -p "Using the memory MCP, remember this test: CCE MCP Integration Test Successful at $(date)"
echo ""
echo "Retrieving test data..."
claude --mcp-servers memory -p "Using the memory MCP, what did I ask you to remember about CCE MCP Integration Test?"
```

### Test Script 5: `~/.cce-universal/mcp/tests/test-postgresql.sh`
```bash
#!/bin/bash
echo "🐘 Testing PostgreSQL MCP..."
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  DATABASE_URL not set. Using default: postgresql://localhost/postgres"
fi
claude --mcp-servers postgresql -p "Using the postgresql MCP, show the current database version"
```

Make all test scripts executable:
```bash
chmod +x ~/.cce-universal/mcp/tests/*.sh
```

## Task 4: Update Aliases File

Add these lines to `~/.cce-universal/aliases.sh`:

```bash
# MCP Shortcuts
alias cce-mcp-fs='claude --mcp-servers filesystem'
alias cce-mcp-gh='claude --mcp-servers github' 
alias cce-mcp-db='claude --mcp-servers postgresql'
alias cce-mcp-web='claude --mcp-servers fetch,firecrawl'
alias cce-mcp-dev='claude --mcp-servers filesystem,github,postgresql'
alias cce-mcp-all='claude --mcp-servers filesystem,github,postgresql,fetch,memory,everything,sequential-thinking,sentry,firecrawl'

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
```

## Task 5: Create Setup Summary Script

Create `~/.cce-universal/mcp/check-integration.sh`:

```bash
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
```

Make it executable:
```bash
chmod +x ~/.cce-universal/mcp/check-integration.sh
```

## Task 6: Final Verification

After completing all tasks:

1. Reload bash configuration:
   ```bash
   source ~/.bashrc
   ```

2. Run integration check:
   ```bash
   ~/.cce-universal/mcp/check-integration.sh
   ```

3. Test basic functionality:
   ```bash
   cce-mcp-test filesystem
   cce-mcp-test fetch
   ```

4. Try a practical example:
   ```bash
   cce-mcp-fs -p "Using the filesystem MCP, show the content of package.json if it exists"
   ```

## Troubleshooting

If tests fail:

1. **Check Node.js paths**: Ensure MCP server files exist
   ```bash
   ls ~/.cce-universal/mcp-servers/node_modules/
   ```

2. **Verify config syntax**: 
   ```bash
   cat ~/.config/claude/config.json | jq .
   ```

3. **Test without MCP first**:
   ```bash
   claude -p "Hello, this is a test without MCP"
   ```

4. **Check Claude CLI version**:
   ```bash
   claude --version
   ```

## Expected Result

After successful setup:
- ✅ All MCP servers configured in `~/.config/claude/config.json`
- ✅ Test scripts ready in `~/.cce-universal/mcp/tests/`
- ✅ Shortcuts available: `cce-mcp-fs`, `cce-mcp-dev`, etc.
- ✅ `cce-mcp-test` command works for testing individual servers
- ✅ Can use MCP servers with Claude CLI

## Notes
- Most MCP servers work without API keys (filesystem, fetch, memory, etc.)
- GitHub, Sentry, and Firecrawl require API keys only if you want to use them
- Start with filesystem and fetch for testing - they work immediately
- The integration is complete when you can successfully run: `cce-mcp-fs -p "Using filesystem MCP, list current directory"`