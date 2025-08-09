#!/bin/bash
# Start CCE Dashboard

echo "🚀 Starting CCE Dashboard..."

# Check if dependencies are installed
if [ ! -d "$HOME/.cce-universal/web/node_modules" ]; then
    echo "📦 Installing backend dependencies..."
    cd ~/.cce-universal/web
    npm install
fi

if [ ! -d "$HOME/.cce-universal/web/dashboard/node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    cd ~/.cce-universal/web/dashboard
    npm install
fi

# Build frontend if not built
if [ ! -d "$HOME/.cce-universal/web/dashboard/build" ]; then
    echo "🔨 Building frontend..."
    cd ~/.cce-universal/web/dashboard
    npm run build
fi

# Start the server
cd ~/.cce-universal/web
echo "🌐 Starting server on http://localhost:3456"
npm start &

# Save PID
echo $! > ~/.cce-universal/web/server.pid

echo "✅ Dashboard running at http://localhost:3456"
echo "Press Ctrl+C to stop"

# Wait
wait