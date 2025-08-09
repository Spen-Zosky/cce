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
    claude --mcp-config ~/.config/claude/config.json -p "Based on the analysis,
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