#!/bin/bash
# Multi-Agent Orchestrator

echo "🎭 Multi-Agent Task Executor"
echo "============================"

PROJECT_NAME=${1:-"my-app"}
PROJECT_TYPE=${2:-"fullstack"}

echo "Creating $PROJECT_NAME ($PROJECT_TYPE) with multiple agents..."

# Agent 1: Coder creates the base
echo "📝 Agent 1: Creating project structure..."
claude -p "Create a $PROJECT_TYPE project named $PROJECT_NAME with proper structure and boilerplate"

sleep 2

# Agent 2: Enhancer adds features
echo "✨ Agent 2: Adding features..."
claude -p "Add authentication, database models, and API routes to the current project"

sleep 2

# Agent 3: Tester adds tests
echo "🧪 Agent 3: Generating tests..."
claude -p "Generate comprehensive test suite for all components and functions"

sleep 2

# Agent 4: Documenter
echo "📚 Agent 4: Creating documentation..."
claude -p "Create complete documentation including README, API docs, and inline comments"

echo "✅ Multi-agent task complete!"
