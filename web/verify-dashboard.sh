#!/bin/bash
echo "🔍 Verifying Dashboard Implementation"
echo "===================================="

# Check React components
echo -e "\n📁 React Components:"
components=("Dashboard" "SystemStatus" "MCPServers" "Projects" "AgentRunner")
for comp in "${components[@]}"; do
    if [ -f "dashboard/src/components/$comp.tsx" ]; then
        echo "✅ $comp.tsx exists"
    else
        echo "❌ $comp.tsx missing"
    fi
done

# Check API endpoints
echo -e "\n🔌 API Endpoints:"
endpoints=("status" "mcp/servers" "projects" "agents/execute" "health")
for endpoint in "${endpoints[@]}"; do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3456/api/v1/$endpoint 2>/dev/null)
    if [ "$response" = "200" ] || [ "$response" = "404" ]; then
        echo "✅ /api/v1/$endpoint - HTTP $response"
    else
        echo "❌ /api/v1/$endpoint - Not responding"
    fi
done

# Check Tailwind setup
echo -e "\n🎨 Tailwind Setup:"
cd dashboard
if grep -q "@tailwind" src/index.css; then
    echo "✅ Tailwind directives in CSS"
else
    echo "❌ Tailwind directives missing (using custom CSS)"
fi

if [ -f "tailwind.config.js" ] && [ -f "postcss.config.js" ]; then
    echo "✅ Config files exist"
else
    echo "❌ Config files missing (using tailwind-compat.css)"
fi

# Check dependencies
echo -e "\n📦 Key Dependencies:"
deps=("axios" "@tanstack/react-query" "lucide-react" "tailwindcss")
for dep in "${deps[@]}"; do
    if npm list "$dep" --depth=0 2>/dev/null | grep -q "$dep"; then
        echo "✅ $dep installed"
    else
        echo "❌ $dep missing"
    fi
done

echo -e "\n✨ Dashboard URL: http://localhost:3456"
