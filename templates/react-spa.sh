#!/bin/bash
# React SPA Template

PROJECT_NAME="${1:-my-react-app}"
echo "📦 Creating React SPA project: $PROJECT_NAME"

# Create React app
npx create-react-app "$PROJECT_NAME" --template typescript
cd "$PROJECT_NAME"

# Install additional dependencies
npm install @tanstack/react-query axios react-router-dom
npm install -D @types/react-router-dom

# Initialize CCE
~/.cce-universal/scripts/init-project.sh .

echo "✅ React SPA project created!"
echo "Run: cd $PROJECT_NAME && npm start"
