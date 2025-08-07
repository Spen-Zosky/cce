#!/bin/bash
# CCE Agent Manager

AGENTS_DIR="$HOME/.cce-universal/agents"

echo "🤖 CCE Agent System"
echo "=================="

run_agent() {
    AGENT_NAME=$1
    shift
    AGENT_ARGS="$@"
    
    case "$AGENT_NAME" in
        coder)
            echo "🔨 Running Coder Agent..."
            claude -p "You are a coding agent. Task: $AGENT_ARGS. Complete this task step by step, creating and modifying files as needed."
            ;;
            
        reviewer)
            echo "👀 Running Code Review Agent..."
            claude -p "Review the current project for: code quality, bugs, security issues, performance. Provide specific suggestions."
            ;;
            
        tester)
            echo "🧪 Running Test Generator Agent..."
            claude -p "Generate comprehensive tests for all code files in the current project. Use the appropriate testing framework."
            ;;
            
        documenter)
            echo "📚 Running Documentation Agent..."
            claude -p "Generate complete documentation for this project including: README, API docs, code comments, usage examples."
            ;;
            
        debugger)
            echo "🐛 Running Debugger Agent..."
            claude -p "Debug this issue: $AGENT_ARGS. Find the root cause and provide a fix."
            ;;
            
        deployer)
            echo "🚀 Running Deploy Agent..."
            claude -p "Prepare this project for deployment: create Dockerfile, CI/CD pipeline, deployment scripts for: $AGENT_ARGS"
            ;;
            
        *)
            echo "Unknown agent: $AGENT_NAME"
            echo "Available agents:"
            echo "  - coder: Write code"
            echo "  - reviewer: Review code"
            echo "  - tester: Generate tests"
            echo "  - documenter: Create docs"
            echo "  - debugger: Fix bugs"
            echo "  - deployer: Deploy setup"
            ;;
    esac
}

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: cce-agent <agent-name> [arguments]"
    echo ""
    echo "Available agents:"
    echo "  coder <task>      - Write code for task"
    echo "  reviewer          - Review current code"
    echo "  tester            - Generate tests"
    echo "  documenter        - Create documentation"
    echo "  debugger <error>  - Debug specific error"
    echo "  deployer <target> - Setup deployment"
else
    run_agent "$@"
fi
