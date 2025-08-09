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
    claude --mcp-config ~/.config/claude/config.json -p "Using sequential-thinking MCP, plan a full-stack application called '$project_name'.
    Define: tech stack, database schema, API endpoints, and UI components.
    Use memory MCP to store the plan for subsequent agents."
    
    # Phase 2: Database Design
    echo ""
    echo "💾 Phase 2: Designing database..."
    claude --mcp-config ~/.config/claude/config.json -p "Using memory MCP to recall the project plan,
    create the database schema using filesystem MCP to write schema.prisma or migrations.
    If postgresql MCP is available, validate the schema design."
    
    # Phase 3: API Development
    echo ""
    echo "🔌 Phase 3: Building APIs..."
    cce-agent coder "implement all API endpoints based on the project plan in memory"
    
    # Phase 4: Frontend
    echo ""
    echo "🎨 Phase 4: Creating UI components..."
    claude --mcp-config ~/.config/claude/config.json -p "Using memory MCP to recall the project plan,
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
    claude --mcp-config ~/.config/claude/config.json -p "Using sequential-thinking MCP,
    analyze this issue: $issue
    Create a debugging plan and store it in memory MCP.
    Use filesystem MCP to read relevant code files."
    
    # Phase 2: Search for Similar Issues
    echo ""
    echo "🔎 Phase 2: Searching for similar issues..."
    claude --mcp-config ~/.config/claude/config.json -p "Using github MCP, search for similar issues.
    Using fetch MCP, search Stack Overflow and documentation.
    Add findings to memory MCP."
    
    # Phase 3: Root Cause Analysis
    echo ""
    echo "🔬 Phase 3: Root cause analysis..."
    cce-agent debugger "$issue"
    
    # Phase 4: Fix Implementation
    echo ""
    echo "🔧 Phase 4: Implementing fix..."
    claude --mcp-config ~/.config/claude/config.json -p "Using memory MCP to recall the debugging findings,
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
    claude --mcp-config ~/.config/claude/config.json -p "Based on the analysis,
    create a step-by-step modernization plan using sequential-thinking MCP.
    Store the plan in memory MCP.
    Consider: dependencies update, code patterns, performance, security."
    
    # Phase 3: Implementation
    echo ""
    echo "🔨 Phase 3: Implementing improvements..."
    claude --mcp-config ~/.config/claude/config.json -p "Using the modernization plan from memory MCP,
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
    claude --mcp-config ~/.config/claude/config.json -p "Using fetch MCP, research: $topic
    Focus on recent developments, best practices, and case studies.
    Store key findings in memory MCP."
    
    # Phase 2: Code Examples
    echo ""
    echo "💻 Phase 2: Finding code examples..."
    claude --mcp-config ~/.config/claude/config.json -p "Using github MCP, find repositories related to: $topic
    Using fetch MCP, find tutorials and examples.
    Add to memory MCP research notes."
    
    # Phase 3: Summary Report
    echo ""
    echo "📝 Phase 3: Creating summary..."
    claude --mcp-config ~/.config/claude/config.json -p "Using memory MCP to recall all research,
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
    claude --mcp-config ~/.config/claude/config.json -p "Analyze codebase for performance issues:
    - Algorithm complexity
    - Database queries
    - Memory usage
    - Bundle size
    - Rendering performance"
    
    # Phase 2: Optimization Plan
    echo ""
    echo "📋 Phase 2: Creating optimization plan..."
    claude --mcp-config ~/.config/claude/config.json -p "Create prioritized optimization plan.
    Store in memory MCP for tracking progress."
    
    # Phase 3: Implementation
    echo ""
    echo "🔧 Phase 3: Implementing optimizations..."
    claude --mcp-config ~/.config/claude/config.json -p "Implement optimizations from the plan.
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