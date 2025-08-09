# Agent System MCP Enhancement - Complete Instructions

## Context
You are enhancing the CCE Agent System to make it MCP-aware. The goal is to create specialized agents that automatically use appropriate MCP servers for their tasks, making development workflows more powerful and automated.

## Current State
- ✅ 6 basic agents exist: coder, reviewer, tester, documenter, debugger, deployer
- ✅ 9 MCP servers are configured and working
- ⚠️ Agents don't currently leverage MCP capabilities
- ⚠️ Need specialized workflows combining agents + MCP

## Task 1: Create MCP-Aware Agent Manager

Replace the current agent manager at `~/.cce-universal/agents/agent-manager.sh` with this enhanced version:

```bash
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
        if ! [ -d "$HOME/.cce-universal/mcp-servers/node_modules/"*"$server"* ]; then
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
                claude --mcp-servers filesystem,github -p "You are an MCP-enhanced coding agent. 
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
                claude --mcp-servers filesystem,github,memory -p "You are an MCP-enhanced code review agent.
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
                claude --mcp-servers filesystem,memory -p "You are an MCP-enhanced test generation agent.
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
                claude --mcp-servers filesystem,github,memory -p "You are an MCP-enhanced documentation agent.
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
            
            claude --mcp-servers $mcp_servers -p "You are an MCP-enhanced debugging agent.
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
                claude --mcp-servers filesystem,github -p "You are an MCP-enhanced deployment agent.
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
                claude --mcp-servers filesystem,everything,sequential-thinking -p "You are an MCP-enhanced code analysis agent.
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
```

Make it executable:
```bash
chmod +x ~/.cce-universal/agents/agent-manager.sh
```

## Task 2: Create Specialized MCP Workflows

Create new file `~/.cce-universal/agents/mcp-workflows.sh`:

```bash
#!/bin/bash
# Specialized MCP-Agent Workflows

echo "🔄 MCP-Agent Workflow System"
echo "==========================="

# Full-Stack Development Workflow
workflow_fullstack() {
    local project_name="${1:-my-app}"
    echo "🚀 Starting Full-Stack MCP Workflow for: $project_name"
    
    # Phase 1: Project Analysis
    echo ""
    echo "📊 Phase 1: Analyzing project requirements..."
    claude --mcp-servers sequential-thinking,memory -p "Using sequential-thinking MCP, plan a full-stack application called '$project_name'.
    Define: tech stack, database schema, API endpoints, and UI components.
    Use memory MCP to store the plan for subsequent agents."
    
    # Phase 2: Database Design
    echo ""
    echo "💾 Phase 2: Designing database..."
    claude --mcp-servers filesystem,memory,postgresql -p "Using memory MCP to recall the project plan,
    create the database schema using filesystem MCP to write schema.prisma or migrations.
    If postgresql MCP is available, validate the schema design."
    
    # Phase 3: API Development
    echo ""
    echo "🔌 Phase 3: Building APIs..."
    cce-agent coder "implement all API endpoints based on the project plan in memory"
    
    # Phase 4: Frontend
    echo ""
    echo "🎨 Phase 4: Creating UI components..."
    claude --mcp-servers filesystem,memory -p "Using memory MCP to recall the project plan,
    create React/Next.js components for all UI elements using filesystem MCP."
    
    # Phase 5: Testing
    echo ""
    echo "🧪 Phase 5: Generating tests..."
    cce-agent tester
    
    # Phase 6: Documentation
    echo ""
    echo "📚 Phase 6: Creating documentation..."
    cce-agent documenter
}

# Bug Investigation Workflow
workflow_debug() {
    local issue="$1"
    if [ -z "$issue" ]; then
        echo "❌ Usage: cce-workflow debug \"description of the issue\""
        return 1
    fi
    
    echo "🔍 Starting Debug Investigation Workflow"
    echo "Issue: $issue"
    
    # Phase 1: Error Analysis
    echo ""
    echo "🔍 Phase 1: Analyzing error..."
    claude --mcp-servers filesystem,sequential-thinking,memory -p "Using sequential-thinking MCP,
    analyze this issue: $issue
    Create a debugging plan and store it in memory MCP.
    Use filesystem MCP to read relevant code files."
    
    # Phase 2: Search for Similar Issues
    echo ""
    echo "🔎 Phase 2: Searching for similar issues..."
    claude --mcp-servers github,fetch,memory -p "Using github MCP, search for similar issues.
    Using fetch MCP, search Stack Overflow and documentation.
    Add findings to memory MCP."
    
    # Phase 3: Root Cause Analysis
    echo ""
    echo "🔬 Phase 3: Root cause analysis..."
    cce-agent debugger "$issue"
    
    # Phase 4: Fix Implementation
    echo ""
    echo "🔧 Phase 4: Implementing fix..."
    claude --mcp-servers filesystem,memory -p "Using memory MCP to recall the debugging findings,
    implement the fix using filesystem MCP to modify the necessary files.
    Add comments explaining the fix."
    
    # Phase 5: Test Fix
    echo ""
    echo "✅ Phase 5: Testing fix..."
    cce-agent tester
}

# Code Modernization Workflow
workflow_modernize() {
    echo "🔄 Starting Code Modernization Workflow"
    
    # Phase 1: Analysis
    echo ""
    echo "📊 Phase 1: Analyzing current codebase..."
    cce-agent analyzer
    
    # Phase 2: Planning
    echo ""
    echo "📋 Phase 2: Creating modernization plan..."
    claude --mcp-servers filesystem,memory,sequential-thinking -p "Based on the analysis,
    create a step-by-step modernization plan using sequential-thinking MCP.
    Store the plan in memory MCP.
    Consider: dependencies update, code patterns, performance, security."
    
    # Phase 3: Implementation
    echo ""
    echo "🔨 Phase 3: Implementing improvements..."
    claude --mcp-servers filesystem,memory -p "Using the modernization plan from memory MCP,
    implement improvements step by step using filesystem MCP.
    Focus on backward compatibility."
    
    # Phase 4: Testing
    echo ""
    echo "🧪 Phase 4: Comprehensive testing..."
    cce-agent tester
    
    # Phase 5: Documentation Update
    echo ""
    echo "📚 Phase 5: Updating documentation..."
    cce-agent documenter
}

# Research Workflow
workflow_research() {
    local topic="$1"
    if [ -z "$topic" ]; then
        echo "❌ Usage: cce-workflow research \"topic\""
        return 1
    fi
    
    echo "🔬 Starting Research Workflow"
    echo "Topic: $topic"
    
    # Phase 1: Academic Research
    echo ""
    echo "📚 Phase 1: Academic research..."
    claude --mcp-servers fetch,memory -p "Using fetch MCP, research: $topic
    Focus on recent developments, best practices, and case studies.
    Store key findings in memory MCP."
    
    # Phase 2: Code Examples
    echo ""
    echo "💻 Phase 2: Finding code examples..."
    claude --mcp-servers github,fetch,memory -p "Using github MCP, find repositories related to: $topic
    Using fetch MCP, find tutorials and examples.
    Add to memory MCP research notes."
    
    # Phase 3: Summary Report
    echo ""
    echo "📝 Phase 3: Creating summary..."
    claude --mcp-servers filesystem,memory -p "Using memory MCP to recall all research,
    create a comprehensive report using filesystem MCP.
    Save as research-$topic.md with:
    - Executive summary
    - Key findings
    - Code examples
    - Recommendations
    - References"
}

# Performance Optimization Workflow
workflow_optimize() {
    echo "⚡ Starting Performance Optimization Workflow"
    
    # Phase 1: Performance Analysis
    echo ""
    echo "📊 Phase 1: Analyzing performance..."
    claude --mcp-servers filesystem,everything,sequential-thinking -p "Analyze codebase for performance issues:
    - Algorithm complexity
    - Database queries
    - Memory usage
    - Bundle size
    - Rendering performance"
    
    # Phase 2: Optimization Plan
    echo ""
    echo "📋 Phase 2: Creating optimization plan..."
    claude --mcp-servers memory,sequential-thinking -p "Create prioritized optimization plan.
    Store in memory MCP for tracking progress."
    
    # Phase 3: Implementation
    echo ""
    echo "🔧 Phase 3: Implementing optimizations..."
    claude --mcp-servers filesystem,memory -p "Implement optimizations from the plan.
    Track each change in memory MCP."
    
    # Phase 4: Verification
    echo ""
    echo "✅ Phase 4: Verifying improvements..."
    cce-agent tester
}

# Main workflow dispatcher
case "$1" in
    fullstack)
        shift
        workflow_fullstack "$@"
        ;;
    debug)
        shift
        workflow_debug "$@"
        ;;
    modernize)
        workflow_modernize
        ;;
    research)
        shift
        workflow_research "$@"
        ;;
    optimize)
        workflow_optimize
        ;;
    *)
        echo "Available MCP-Agent Workflows:"
        echo ""
        echo "🚀 fullstack <name>  - Complete full-stack app development"
        echo "🐛 debug <issue>     - Investigate and fix bugs"
        echo "🔄 modernize         - Modernize legacy codebase"
        echo "🔬 research <topic>  - Research and document topics"
        echo "⚡ optimize          - Performance optimization"
        echo ""
        echo "Usage: cce-workflow <workflow> [args]"
        ;;
esac
```

Make it executable:
```bash
chmod +x ~/.cce-universal/agents/mcp-workflows.sh
```

## Task 3: Create Agent Chains

Create file `~/.cce-universal/agents/agent-chains.sh`:

```bash
#!/bin/bash
# Agent Chains - Connecting multiple agents for complex tasks

# Code Quality Chain
chain_quality() {
    echo "🔗 Running Code Quality Chain"
    echo "============================="
    
    echo "Step 1: Code Review"
    cce-agent reviewer
    
    echo -e "\nStep 2: Generate Missing Tests"
    cce-agent tester
    
    echo -e "\nStep 3: Update Documentation"
    cce-agent documenter
    
    echo -e "\nStep 4: Final Analysis"
    cce-agent analyzer
}

# Feature Development Chain
chain_feature() {
    local feature="$1"
    if [ -z "$feature" ]; then
        echo "Usage: cce-chain feature \"feature description\""
        return 1
    fi
    
    echo "🔗 Running Feature Development Chain"
    echo "==================================="
    echo "Feature: $feature"
    
    echo -e "\nStep 1: Implementation"
    cce-agent coder "$feature"
    
    echo -e "\nStep 2: Generate Tests"
    cce-agent tester
    
    echo -e "\nStep 3: Code Review"
    cce-agent reviewer
    
    echo -e "\nStep 4: Documentation"
    cce-agent documenter
}

# Deployment Preparation Chain
chain_deploy() {
    local target="${1:-vercel}"
    
    echo "🔗 Running Deployment Chain"
    echo "=========================="
    echo "Target: $target"
    
    echo -e "\nStep 1: Code Analysis"
    cce-agent analyzer
    
    echo -e "\nStep 2: Fix Critical Issues"
    cce-agent reviewer
    
    echo -e "\nStep 3: Ensure Test Coverage"
    cce-agent tester
    
    echo -e "\nStep 4: Prepare Deployment"
    cce-agent deployer "$target"
    
    echo -e "\nStep 5: Update Documentation"
    cce-agent documenter
}

# Refactoring Chain
chain_refactor() {
    echo "🔗 Running Refactoring Chain"
    echo "============================"
    
    echo "Step 1: Analyze Current Code"
    cce-agent analyzer
    
    echo -e "\nStep 2: Create Safety Tests"
    cce-agent tester
    
    echo -e "\nStep 3: Refactor Code"
    claude --mcp-servers filesystem,memory,sequential-thinking -p "Based on the analysis,
    refactor the codebase for better structure, readability, and performance.
    Maintain all existing functionality."
    
    echo -e "\nStep 4: Verify Tests Pass"
    cce-agent tester
    
    echo -e "\nStep 5: Update Documentation"
    cce-agent documenter
}

# Main chain dispatcher
case "$1" in
    quality)
        chain_quality
        ;;
    feature)
        shift
        chain_feature "$@"
        ;;
    deploy)
        shift
        chain_deploy "$@"
        ;;
    refactor)
        chain_refactor
        ;;
    *)
        echo "Available Agent Chains:"
        echo ""
        echo "🔍 quality          - Complete code quality check"
        echo "✨ feature <desc>   - Develop new feature end-to-end"
        echo "🚀 deploy [target]  - Prepare for deployment"
        echo "🔄 refactor         - Refactor with safety"
        echo ""
        echo "Usage: cce-chain <chain> [args]"
        ;;
esac
```

Make it executable:
```bash
chmod +x ~/.cce-universal/agents/agent-chains.sh
```

## Task 4: Update Multi-Agent Script

Update `~/.cce-universal/agents/multi-agent.sh` to be MCP-aware:

```bash
#!/bin/bash
# MCP-Enhanced Multi-Agent Orchestrator

echo "🎭 MCP-Enhanced Multi-Agent Task Executor"
echo "========================================"

PROJECT_NAME=${1:-"my-app"}
PROJECT_TYPE=${2:-"fullstack"}

echo "Creating $PROJECT_NAME ($PROJECT_TYPE) with MCP-enhanced agents..."

# Use memory MCP to maintain context across agents
echo ""
echo "📝 Initializing project context in memory..."
claude --mcp-servers memory -p "Using memory MCP, store this project context:
- Project Name: $PROJECT_NAME
- Project Type: $PROJECT_TYPE
- Tech Stack: Next.js 14, TypeScript, Tailwind CSS, PostgreSQL, Prisma
- Created: $(date)
This context should be used by all subsequent agents."

# Agent 1: Architect
echo ""
echo "🏗️ Agent 1: Architecture Design..."
claude --mcp-servers sequential-thinking,memory,filesystem -p "You are the architect agent.
Using sequential-thinking MCP, design the architecture for $PROJECT_TYPE project: $PROJECT_NAME.
Store the architecture decisions in memory MCP.
Create initial project structure using filesystem MCP."

sleep 2

# Agent 2: Coder
echo ""
echo "📝 Agent 2: Implementation..."
claude --mcp-servers filesystem,memory,github -p "You are the coder agent.
Using memory MCP, recall the project architecture.
Using filesystem MCP, implement the core features:
- Database models
- API routes
- UI components
- Authentication setup
Check github MCP for best practices if available."

sleep 2

# Agent 3: Enhancer
echo ""
echo "✨ Agent 3: Adding advanced features..."
claude --mcp-servers filesystem,memory,fetch -p "You are the enhancement agent.
Using memory MCP, understand what's been built.
Using filesystem MCP, add:
- Error handling
- Input validation  
- Performance optimizations
- Security headers
Use fetch MCP to check current best practices if needed."

sleep 2

# Agent 4: Tester
echo ""
echo "🧪 Agent 4: Comprehensive testing..."
cce-agent tester

sleep 2

# Agent 5: Reviewer
echo ""
echo "👀 Agent 5: Code review and quality check..."
cce-agent reviewer

sleep 2

# Agent 6: Documenter
echo ""
echo "📚 Agent 6: Documentation..."
cce-agent documenter

# Final Summary
echo ""
echo "📊 Final: Project Summary..."
claude --mcp-servers memory,filesystem -p "Using memory MCP, recall all project context and decisions.
Using filesystem MCP, create a PROJECT_SUMMARY.md with:
- Architecture overview
- Key features implemented
- Technology choices
- Setup instructions
- Next steps"

echo ""
echo "✅ Multi-agent task complete!"
echo "Project $PROJECT_NAME has been created with full MCP integration."
```

## Task 5: Update Aliases

Add these new commands to `~/.cce-universal/aliases.sh`:

```bash
# MCP-Agent Commands
alias cce-workflow='~/.cce-universal/agents/mcp-workflows.sh'
alias cce-chain='~/.cce-universal/agents/agent-chains.sh'

# Quick workflow shortcuts
alias cce-debug='cce-workflow debug'
alias cce-research='cce-workflow research'
alias cce-modernize='cce-workflow modernize'
alias cce-optimize='cce-workflow optimize'

# Agent shortcuts with MCP
alias cce-analyze='cce-agent analyzer'

# Project templates with MCP
cce-create-mcp() {
    local name="${1:-my-mcp-app}"
    echo "Creating MCP-enabled project: $name"
    mkdir -p "$name"
    cd "$name"
    
    # Initialize with MCP context
    claude --mcp-servers filesystem,memory -p "Create a new Next.js project structure here with:
    - TypeScript configuration
    - Tailwind CSS
    - Prisma with PostgreSQL
    - Basic authentication ready
    - MCP-friendly documentation
    Store project metadata in memory MCP."
    
    # Run workflow
    cce-workflow fullstack "$name"
}
```

## Task 6: Create Examples Directory

Create example usage scripts:

```bash
mkdir -p ~/.cce-universal/agents/examples
```

Create `~/.cce-universal/agents/examples/example-blog.sh`:
```bash
#!/bin/bash
# Example: Create a blog with MCP agents

echo "📝 Creating a blog with MCP-enhanced agents"

# Use the fullstack workflow
cce-workflow fullstack "my-blog"

# Add specific blog features
cce-agent coder "add markdown support and syntax highlighting for blog posts"

# Generate blog-specific tests
cce-agent tester

# Create deployment configuration
cce-agent deployer vercel
```

Create `~/.cce-universal/agents/examples/example-debug.sh`:
```bash
#!/bin/bash
# Example: Debug a complex issue

echo "🐛 Debugging authentication issue"

# Use debug workflow
cce-workflow debug "users cannot login after password reset"

# Run additional analysis
cce-agent analyzer

# Ensure fix is tested
cce-chain quality
```

Make examples executable:
```bash
chmod +x ~/.cce-universal/agents/examples/*.sh
```

## Task 7: Create Status Check Script

Create `~/.cce-universal/agents/check-mcp-agents.sh`:

```bash
#!/bin/bash
# Check MCP-Agent Integration Status

echo "🔍 MCP-Agent Integration Status"
echo "==============================="
echo ""

# Check enhanced agents
echo "📋 Enhanced Agents:"
agents=(coder reviewer tester documenter debugger deployer analyzer)
for agent in "${agents[@]}"; do
    echo "  • $agent - MCP-aware ✅"
done
echo ""

# Check workflows
echo "🔄 Available Workflows:"
echo "  • fullstack - Full application development"
echo "  • debug - Issue investigation and fixing"
echo "  • modernize - Code modernization"
echo "  • research - Topic research and documentation"
echo "  • optimize - Performance optimization"
echo ""

# Check chains
echo "🔗 Available Chains:"
echo "  • quality - Code quality pipeline"
echo "  • feature - Feature development pipeline"
echo "  • deploy - Deployment preparation"
echo "  • refactor - Safe refactoring"
echo ""

# Check MCP integration
echo "🔌 MCP Integration:"
if [ -f "$HOME/.config/claude/config.json" ]; then
    echo "  ✅ MCP servers configured"
    
    # Count available servers
    servers=$(cd ~/.cce-universal/mcp-servers/node_modules && ls -d @* */ 2>/dev/null | grep -E "(filesystem|github|postgresql|fetch|memory|everything|sequential-thinking|sentry|firecrawl)" | wc -l)
    echo "  ✅ $servers MCP servers available"
else
    echo "  ❌ MCP configuration missing"
fi
echo ""

echo "🚀 Quick Start Commands:"
echo "  cce-workflow fullstack my-app   # Create full app"
echo "  cce-chain feature \"new feature\" # Develop feature"
echo "  cce-agent analyzer              # Analyze code"
echo "  cce-debug \"error message\"       # Debug issue"
echo ""

echo "📚 Examples:"
echo "  ~/.cce-universal/agents/examples/"
ls ~/.cce-universal/agents/examples/*.sh 2>/dev/null | xargs -n1 basename | sed 's/^/    - /'
```

Make it executable:
```bash
chmod +x ~/.cce-universal/agents/check-mcp-agents.sh
```

## Final Steps

1. Reload bash configuration:
   ```bash
   source ~/.bashrc
   ```

2. Test the integration:
   ```bash
   ~/.cce-universal/agents/check-mcp-agents.sh
   ```

3. Try a simple workflow:
   ```bash
   cce-agent analyzer
   ```

4. Try a complex workflow:
   ```bash
   cce-workflow research "Next.js 15 new features"
   ```

## Expected Results

After completing all tasks:
- ✅ All agents are MCP-aware and use appropriate servers
- ✅ New workflows combine multiple agents with MCP
- ✅ Agent chains for common development patterns
- ✅ Examples for learning and reference
- ✅ Status check shows everything integrated

## Usage Patterns

### For New Projects
```bash
cce-workflow fullstack my-new-app
```

### For Debugging
```bash
cce-debug "specific error message"
```

### For Code Quality
```bash
cce-chain quality
```

### For Research
```bash
cce-research "GraphQL vs REST APIs"
```

The agents now automatically select and use appropriate MCP servers for their tasks, making them much more powerful and context-aware.