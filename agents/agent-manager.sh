#!/bin/bash
# CCE MCP-Aware Agent Manager

AGENTS_DIR="$HOME/.cce-universal/agents"

echo "🤖 CCE Agent System (MCP-Enhanced)"
echo "=================================="

# Helper function to check if MCP servers are available
check_mcp_servers() {
    local required_servers="$1"
    local missing=()
    
    for server in $required_servers; do
        # Check for @modelcontextprotocol/server-* format
        if ! [ -d "$HOME/.cce-universal/mcp-servers/node_modules/@modelcontextprotocol/server-$server" ]; then
            missing+=("$server")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "⚠️  Missing MCP servers: ${missing[*]}"
        echo "Install with: cce-mcp install ${missing[*]}"
        return 1
    fi
    return 0
}

run_agent() {
    AGENT_NAME=$1
    shift
    AGENT_ARGS="$@"
    
    case "$AGENT_NAME" in
        coder)
            echo "🔨 Running MCP-Enhanced Coder Agent..."
            echo "📁 Using: filesystem, github MCP servers"
            
            if check_mcp_servers "filesystem github"; then
                claude --mcp-config ~/.config/claude/config.json -p "You are an MCP-enhanced coding agent. 
                Use filesystem MCP to read and write code files.
                Use github MCP to check related issues and PRs.
                Task: $AGENT_ARGS
                
                First, analyze the project structure, then implement the requested feature.
                Create or modify files as needed using the filesystem MCP."
            else
                # Fallback to basic mode
                claude -p "You are a coding agent. Task: $AGENT_ARGS"
            fi
            ;;
            
        reviewer)
            echo "👀 Running MCP-Enhanced Code Review Agent..."
            echo "📁 Using: filesystem, github, memory MCP servers"
            
            if check_mcp_servers "filesystem github memory"; then
                claude --mcp-config ~/.config/claude/config.json -p "You are an MCP-enhanced code review agent.
                Use filesystem MCP to read all code files.
                Use github MCP to check coding standards from previous PRs.
                Use memory MCP to remember review findings.
                
                Review the current project for:
                1. Code quality and best practices
                2. Security vulnerabilities
                3. Performance issues
                4. Code duplication
                5. Test coverage
                
                Provide specific file:line references for all findings."
            else
                claude -p "Review the current project for code quality, security, and performance issues."
            fi
            ;;
            
        tester)
            echo "🧪 Running MCP-Enhanced Test Generator Agent..."
            echo "📁 Using: filesystem, memory MCP servers"
            
            if check_mcp_servers "filesystem memory"; then
                claude --mcp-config ~/.config/claude/config.json -p "You are an MCP-enhanced test generation agent.
                Use filesystem MCP to:
                1. Read all source code files
                2. Analyze existing test structure
                3. Create comprehensive test files
                
                Use memory MCP to track test coverage as you go.
                
                Generate tests for all functions, edge cases, and error scenarios.
                Follow the project's existing test patterns."
            else
                claude -p "Generate comprehensive tests for all code files in the current project."
            fi
            ;;
            
        documenter)
            echo "📚 Running MCP-Enhanced Documentation Agent..."
            echo "📁 Using: filesystem, github, memory MCP servers"
            
            if check_mcp_servers "filesystem github memory"; then
                claude --mcp-config ~/.config/claude/config.json -p "You are an MCP-enhanced documentation agent.
                Use filesystem MCP to read all code and existing docs.
                Use github MCP to check documentation issues.
                Use memory MCP to maintain documentation structure.
                
                Create/update:
                1. README.md with project overview
                2. API documentation for all endpoints
                3. Code comments for complex functions
                4. Usage examples
                5. Architecture diagrams (as markdown/mermaid)
                6. CONTRIBUTING.md if missing"
            else
                claude -p "Generate complete documentation for this project."
            fi
            ;;
            
        debugger)
            echo "🐛 Running MCP-Enhanced Debugger Agent..."
            echo "📁 Using: filesystem, github, postgresql, sentry MCP servers"
            
            if [ -z "$AGENT_ARGS" ]; then
                echo "❌ Error: Please provide an error message or issue to debug"
                echo "Usage: cce-agent debugger \"error message or description\""
                return 1
            fi
            
            local mcp_servers="filesystem"
            [ -n "$GITHUB_TOKEN" ] && mcp_servers+=",github"
            [ -n "$DATABASE_URL" ] && mcp_servers+=",postgresql"
            [ -n "$SENTRY_AUTH_TOKEN" ] && mcp_servers+=",sentry"
            
            claude --mcp-config ~/.config/claude/config.json -p "You are an MCP-enhanced debugging agent.
            Issue to debug: $AGENT_ARGS
            
            Use available MCP servers to:
            - filesystem: Read code and log files
            - github: Check if similar issues were reported
            - postgresql: Query database for related data issues
            - sentry: Check error tracking for patterns
            
            Find the root cause and provide a fix with explanation."
            ;;
            
        deployer)
            echo "🚀 Running MCP-Enhanced Deploy Agent..."
            echo "📁 Using: filesystem, github MCP servers"
            
            TARGET="${AGENT_ARGS:-vercel}"
            
            if check_mcp_servers "filesystem github"; then
                claude --mcp-config ~/.config/claude/config.json -p "You are an MCP-enhanced deployment agent.
                Use filesystem MCP to read project configuration.
                Use github MCP to check deployment workflows.
                
                Prepare this project for deployment to: $TARGET
                
                Create/update:
                1. Dockerfile if needed
                2. CI/CD pipeline (.github/workflows/ or similar)
                3. Environment configuration
                4. Deployment scripts
                5. Production optimization settings
                
                Target platform: $TARGET"
            else
                claude -p "Prepare deployment configuration for: $TARGET"
            fi
            ;;
            
        analyzer)
            echo "📊 Running MCP-Enhanced Code Analyzer Agent..."
            echo "📁 Using: filesystem, everything, sequential-thinking MCP servers"
            
            if check_mcp_servers "filesystem everything sequential-thinking"; then
                claude --mcp-config ~/.config/claude/config.json -p "You are an MCP-enhanced code analysis agent.
                Use filesystem MCP to read entire codebase.
                Use everything MCP for comprehensive analysis.
                Use sequential-thinking MCP for complex reasoning.
                
                Analyze:
                1. Code architecture and patterns
                2. Dependencies and their usage
                3. Performance bottlenecks
                4. Security vulnerabilities
                5. Technical debt
                6. Refactoring opportunities
                
                Provide actionable recommendations with priority levels."
            else
                echo "⚠️  This agent requires MCP servers: filesystem, everything, sequential-thinking"
            fi
            ;;
            
        *)
            echo "❌ Unknown agent: $AGENT_NAME"
            echo ""
            echo "Available MCP-Enhanced Agents:"
            echo "  coder     - Write code with project awareness"
            echo "  reviewer  - Review code using best practices"
            echo "  tester    - Generate comprehensive tests"
            echo "  documenter - Create complete documentation"
            echo "  debugger  - Debug issues with full context"
            echo "  deployer  - Setup deployment configurations"
            echo "  analyzer  - Deep code analysis (NEW)"
            echo ""
            echo "Usage: cce-agent <agent-name> [arguments]"
            ;;
    esac
}

# Main execution
if [ -z "$1" ]; then
    echo "Usage: cce-agent <agent-name> [arguments]"
    echo ""
    echo "MCP-Enhanced Agents:"
    echo "  coder     - Uses: filesystem, github"
    echo "  reviewer  - Uses: filesystem, github, memory"
    echo "  tester    - Uses: filesystem, memory"
    echo "  documenter - Uses: filesystem, github, memory"
    echo "  debugger  - Uses: filesystem, github, postgresql, sentry"
    echo "  deployer  - Uses: filesystem, github"
    echo "  analyzer  - Uses: filesystem, everything, sequential-thinking"
    exit 1
fi

run_agent "$@"