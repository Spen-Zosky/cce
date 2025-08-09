# CCE Installation Guide

Complete installation guide for CCE (Claude Code Ecosystem) with 9 MCP servers and 6 AI agents.

## 📋 Prerequisites

### Required Software
- **Node.js 18+** - [Download](https://nodejs.org/)
- **npm** or **yarn** - Comes with Node.js
- **Git** - [Download](https://git-scm.com/)
- **Claude CLI** - Will be installed automatically

### Optional (for full features)
- **PostgreSQL** - For database features
- **Python 3.12+** - For SQLite and arXiv MCP servers
- **pip** - For Python packages

## 🚀 Quick Installation

### Step 1: Clone Repository
```bash
git clone https://github.com/Spen-Zosky/cce.git ~/.cce-universal
cd ~/.cce-universal
```

### Step 2: Run Installer
```bash
./install.sh
```

This will:
- Install Claude CLI globally
- Set up all scripts and permissions
- Add CCE to your PATH
- Configure bash aliases

### Step 3: Reload Shell
```bash
source ~/.bashrc
```

### Step 4: Set API Key
```bash
export ANTHROPIC_API_KEY='sk-ant-...'
```

Add to `~/.bashrc` to make permanent:
```bash
echo "export ANTHROPIC_API_KEY='sk-ant-...'" >> ~/.bashrc
```

### Step 5: Verify Installation
```bash
cce-info
```

You should see:
```
CCE Universal Status
====================
Environment: wsl/native/vm
Architecture: amd64/arm64
CCE Home: ~/.cce-universal
Claude: ✓ installed
Node: v18.x.x
API Key: ✓ configured
```

## 📦 MCP Servers Installation

All 9 MCP servers are already installed in the repository:

### Installed Servers
1. ✅ **filesystem** - File system operations
2. ✅ **github** - GitHub integration
3. ✅ **postgresql** - PostgreSQL database
4. ✅ **fetch** - Web scraping
5. ✅ **memory** - Persistent storage
6. ✅ **everything** - Comprehensive toolkit
7. ✅ **sequential-thinking** - Step-by-step reasoning
8. ✅ **sentry** - Error monitoring
9. ✅ **firecrawl** - Advanced web scraping

### Manual Installation (if needed)
```bash
cd ~/.cce-universal/mcp-servers
npm install
```

### Installing Additional Servers

#### SQLite Server (requires Python)
```bash
# Install Python dependencies
sudo apt install python3-pip python3-venv

# Install SQLite MCP
npm install sqlite-mcp-server
```

#### arXiv Server (requires Python)
```bash
# Install Python venv
sudo apt install python3.12-venv

# Install arXiv MCP
npm install arxiv-mcp-server
```

## 🔧 Configuration

### Environment Detection
CCE automatically detects your environment:

```bash
# Check detected environment
echo $CCE_ENV     # wsl, native, or vm
echo $CCE_ARCH    # amd64 or arm64
```

### Database Setup (Optional)

#### PostgreSQL
```bash
# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Create database
sudo -u postgres createdb myapp

# Set connection string
export DATABASE_URL="postgresql://user:pass@localhost/myapp"
```

#### SQLite
```bash
# SQLite is included in most systems
# No additional setup needed for development
```

### GitHub Integration (Optional)
```bash
# Create GitHub token at: https://github.com/settings/tokens
export GITHUB_TOKEN="ghp_..."
```

### Sentry Integration (Optional)
```bash
# Get DSN from Sentry dashboard
export SENTRY_DSN="https://..."
```

## 🐧 Platform-Specific Instructions

### WSL (Windows Subsystem for Linux)
```bash
# Ensure WSL2 is installed
wsl --version

# Update WSL
wsl --update

# Install in WSL environment
./install.sh
```

### Native Linux
```bash
# Works out of the box
./install.sh
```

### macOS
```bash
# Install Homebrew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js
brew install node

# Continue with standard installation
./install.sh
```

### Docker
```bash
# Use the provided Dockerfile (coming soon)
docker build -t cce .
docker run -it cce
```

## ✅ Post-Installation Setup

### 1. Initialize a Project
```bash
mkdir my-project
cd my-project
cce-init
```

### 2. Test MCP Servers
```bash
# List available servers
cce-mcp list

# Start Claude with MCP
claude --mcp-servers filesystem,github,fetch
```

### 3. Test AI Agents
```bash
# Test coder agent
cce-coder "create a hello world function"

# Test reviewer agent
cce-review
```

### 4. Create Your First Project
```bash
# Next.js + PostgreSQL
cce-create my-app

# Or super app with everything
cce-super
```

## 🚨 Troubleshooting

### Claude CLI Not Found
```bash
# Reinstall Claude CLI
npm install -g @anthropic-ai/claude-code

# Check installation
which claude
```

### Permission Denied
```bash
# Fix script permissions
chmod +x ~/.cce-universal/**/*.sh

# Fix npm permissions
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
```

### MCP Servers Not Working
```bash
# Reinstall dependencies
cd ~/.cce-universal/mcp-servers
rm -rf node_modules package-lock.json
npm install
```

### API Key Issues
```bash
# Check if key is set
echo $ANTHROPIC_API_KEY

# Test API key
claude -p "Hello"
```

### Node Version Issues
```bash
# Check Node version
node --version  # Should be 18+

# Update Node.js using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

## 📊 Verify Complete Installation

Run this check script:
```bash
#!/bin/bash
echo "🔍 CCE Installation Check"
echo "========================"

# Check Node
if command -v node &> /dev/null; then
    echo "✅ Node.js: $(node -v)"
else
    echo "❌ Node.js not found"
fi

# Check Claude CLI
if command -v claude &> /dev/null; then
    echo "✅ Claude CLI installed"
else
    echo "❌ Claude CLI not found"
fi

# Check API key
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "✅ API key configured"
else
    echo "❌ API key not set"
fi

# Check CCE
if [ -d "$HOME/.cce-universal" ]; then
    echo "✅ CCE installed at: $HOME/.cce-universal"
else
    echo "❌ CCE not found"
fi

# Check MCP servers
if [ -d "$HOME/.cce-universal/mcp-servers/node_modules" ]; then
    echo "✅ MCP servers installed"
else
    echo "❌ MCP servers not installed"
fi

# Check commands
for cmd in cce-info cce-init cce-agent cce-mcp; do
    if command -v $cmd &> /dev/null; then
        echo "✅ Command available: $cmd"
    else
        echo "❌ Command not found: $cmd"
    fi
done
```

## 🎯 Next Steps

1. **Read Documentation**
   - [README.md](../README.md) - Overview
   - [MCP_AND_AGENTS.md](MCP_AND_AGENTS.md) - MCP & Agents guide
   - [HOW_TO_USE_MCP.md](HOW_TO_USE_MCP.md) - MCP usage

2. **Try Examples**
   ```bash
   # Create a project
   cce-create test-app
   
   # Use MCP servers
   claude --mcp-servers filesystem,fetch
   
   # Use agents
   cce-multi-agent my-app fullstack
   ```

3. **Join Community**
   - Report issues on GitHub
   - Share your projects
   - Contribute improvements

## 📄 License

MIT License - See LICENSE file

## 🆘 Support

- **GitHub Issues**: [Report bugs](https://github.com/Spen-Zosky/cce/issues)
- **Documentation**: [Wiki](https://github.com/Spen-Zosky/cce/wiki)

---

**CCE v1.0.0** - Installation Guide
**Last Updated**: 2025
**Status**: 9 MCP Servers Installed, 6 AI Agents Ready