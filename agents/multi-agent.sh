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
claude --mcp-config ~/.config/claude/config.json -p "Using memory MCP, store this project context:
- Project Name: $PROJECT_NAME
- Project Type: $PROJECT_TYPE
- Tech Stack: Next.js 14, TypeScript, Tailwind CSS, PostgreSQL, Prisma
- Created: $(date)
This context should be used by all subsequent agents."

# Agent 1: Architect
echo ""
echo "🏗️ Agent 1: Architecture Design..."
claude --mcp-config ~/.config/claude/config.json -p "You are the architect agent.
Using sequential-thinking MCP, design the architecture for $PROJECT_TYPE project: $PROJECT_NAME.
Store the architecture decisions in memory MCP.
Create initial project structure using filesystem MCP."

sleep 2

# Agent 2: Coder
echo ""
echo "📝 Agent 2: Implementation..."
claude --mcp-config ~/.config/claude/config.json -p "You are the coder agent.
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
claude --mcp-config ~/.config/claude/config.json -p "You are the enhancement agent.
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
claude --mcp-config ~/.config/claude/config.json -p "Using memory MCP, recall all project context and decisions.
Using filesystem MCP, create a PROJECT_SUMMARY.md with:
- Architecture overview
- Key features implemented
- Technology choices
- Setup instructions
- Next steps"

echo ""
echo "✅ Multi-agent task complete!"
echo "Project $PROJECT_NAME has been created with full MCP integration."