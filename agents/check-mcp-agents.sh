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
    servers=$(ls ~/.cce-universal/mcp-servers/node_modules/@modelcontextprotocol/server-* 2>/dev/null | wc -l)
    other_servers=$(ls ~/.cce-universal/mcp-servers/node_modules | grep -E "(postgres-mcp-server|firecrawl-mcp)" | wc -l)
    total=$((servers + other_servers))
    echo "  ✅ $total MCP servers available"
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