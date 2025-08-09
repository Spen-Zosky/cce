#!/bin/bash
# Run dashboard in development mode

echo "🔧 Starting CCE Dashboard in development mode..."

# Terminal 1: Backend
gnome-terminal --tab --title="CCE API" -- bash -c "cd ~/.cce-universal/web && npm run dev; exec bash"

# Terminal 2: Frontend
gnome-terminal --tab --title="CCE Frontend" -- bash -c "cd ~/.cce-universal/web/dashboard && npm start; exec bash"

echo "✅ Development servers starting..."
echo "   API: http://localhost:3456"
echo "   Frontend: http://localhost:3000"