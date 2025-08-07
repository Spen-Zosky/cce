#!/bin/bash
# CCE Main Installer
echo "🚀 Installing CCE (Claude Code Ecosystem)"
echo "======================================="

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js required. Install from nodejs.org"
    exit 1
fi

# Install Claude CLI if needed
if ! command -v claude &> /dev/null; then
    echo "📦 Installing Claude CLI..."
    npm install -g @anthropic-ai/claude-code
fi

# Make all scripts executable
echo "🔧 Setting up scripts..."
chmod +x scripts/*.sh 2>/dev/null
chmod +x templates/*.sh 2>/dev/null
chmod +x generators/*.sh 2>/dev/null
chmod +x *.sh 2>/dev/null

# Add to bashrc if not present
if ! grep -q "cce-universal/aliases.sh" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# CCE - Claude Code Ecosystem" >> ~/.bashrc
    echo "[ -f ~/.cce-universal/aliases.sh ] && source ~/.cce-universal/aliases.sh" >> ~/.bashrc
fi

echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. source ~/.bashrc"
echo "  2. cce-info (to check status)"
echo "  3. cc (to start Claude)"
