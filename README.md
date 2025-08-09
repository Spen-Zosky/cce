# CCE - Claude Code Ecosystem

Complete AI-powered development environment with Claude integration, featuring 9 MCP servers and 6 specialized AI agents.

## 🚀 Quick Install

```bash
git clone https://github.com/Spen-Zosky/cce.git ~/.cce-universal
cd ~/.cce-universal
./install.sh
source ~/.bashrc
```

## ✨ Features

### 🔌 9 MCP Servers Installed
- **filesystem** - File system access and modification
- **github** - GitHub API integration
- **postgresql** - PostgreSQL database queries
- **fetch** - Web scraping and HTTP requests
- **memory** - Persistent memory storage
- **everything** - Comprehensive toolkit
- **sequential-thinking** - Step-by-step reasoning
- **sentry** - Error monitoring
- **firecrawl** - Advanced web scraping

### 🤖 6 Specialized AI Agents
- **coder** - Write code for specific tasks
- **reviewer** - Review code quality and security
- **tester** - Generate comprehensive test suites
- **documenter** - Create documentation
- **debugger** - Find and fix bugs
- **deployer** - Setup deployment configurations

### 🎭 Multi-Agent Orchestration
Coordinate multiple agents for complex tasks with automatic workflow management.

## 📚 Quick Start Guide

### Basic Commands

```bash
# Claude shortcuts
cc                    # Start Claude
ccp 'query'          # Quick Claude query  
ccr                  # Claude resume
ccc                  # Claude continue

# System info
cce-info             # Show CCE status
cce-help            # Show available commands
cce-init            # Initialize CCE in project
```

### Using MCP Servers

```bash
# List all MCP servers
cce-mcp list

# Use with Claude
claude --mcp-servers filesystem,github,fetch

# In Claude prompt
"Using the filesystem MCP, analyze all Python files"
"Using the github MCP, check recent pull requests"
"Using the fetch MCP, scrape data from website"
```

### Using AI Agents

```bash
# Single agent commands
cce-coder "implement user authentication"
cce-review           # Review current code
cce-test            # Generate tests
cce-docs            # Create documentation
cce-debug "error message"
cce-deploy "vercel"

# Multi-agent orchestration
cce-multi-agent my-app fullstack
```

### Project Creation

```bash
# Create Next.js + PostgreSQL project
cce-create my-app

# Create super app with all features
cce-super

# Generate CRUD operations
cce-crud Product

# Setup authentication
cce-auth
```

### Database Operations

```bash
cce-db              # Open Prisma Studio
cce-migrate         # Run migrations
cce-db-push         # Push schema changes
cce-db-reset        # Reset database
```

## 🛠️ Technology Stack

- **Frontend**: Next.js 14 (App Router), TypeScript, Tailwind CSS, shadcn/ui
- **Backend**: Next.js API Routes, Prisma ORM
- **Database**: PostgreSQL (primary), SQLite (development)
- **Authentication**: NextAuth.js
- **AI Integration**: Claude API, MCP Protocol
- **Deployment**: Vercel-ready

## 📖 Documentation

- [MCP and Agents Guide](docs/MCP_AND_AGENTS.md) - Complete guide to MCP servers and AI agents
- [How to Use MCP](docs/HOW_TO_USE_MCP.md) - Practical MCP usage examples
- [CLAUDE.md](CLAUDE.md) - Claude Code configuration

## 🔧 System Requirements

- Node.js 18+ 
- npm or yarn
- Claude CLI (`npm install -g @anthropic-ai/claude-code`)
- Anthropic API key

## 🌍 Cross-Platform Support

CCE works seamlessly across:
- WSL (Windows Subsystem for Linux)
- Native Linux
- Virtual Machines
- AMD64 and ARM64 architectures

## 📁 Project Structure

```
~/.cce-universal/
├── agents/           # AI agent definitions
├── mcp/             # MCP server configurations
├── mcp-servers/     # Installed MCP servers (9 servers)
├── templates/       # Project templates
├── generators/      # Code generators
├── scripts/         # Utility scripts
├── config/          # Configuration files
├── docs/           # Documentation
└── web/            # Web dashboard
```

## 🔐 Environment Variables

```bash
export ANTHROPIC_API_KEY='your-api-key'
export CCE_ENV="wsl"                    # or "native", "vm"
export CCE_ARCH="amd64"                # or "arm64"
export CCE_HOME=~/.cce-universal
```

## 🚀 Advanced Features

### Multi-Agent Workflows
The multi-agent system orchestrates complex tasks:
1. **Coder Agent** - Creates project structure
2. **Enhancer Agent** - Adds features (auth, DB, API)
3. **Tester Agent** - Generates test suites
4. **Documenter Agent** - Creates documentation

### MCP Server Capabilities
- Access and modify files across your system
- Query databases (PostgreSQL, SQLite)
- Interact with GitHub repositories
- Scrape websites and make HTTP requests
- Maintain persistent memory across sessions
- Monitor application errors with Sentry

### Code Generation
- Complete CRUD APIs with validation
- Authentication systems with NextAuth.js
- UI components with shadcn/ui
- API endpoints with proper error handling
- Database models with Prisma

## 📊 Status Overview

Run `cce-info` to check:
- Environment detection (WSL/Native/VM)
- Architecture (AMD64/ARM64)
- Claude CLI installation
- API key configuration
- Node.js version
- MCP servers status

## 🤝 Contributing

Contributions are welcome! Please check the issues page or submit a pull request.

## 📄 License

MIT License - See LICENSE file for details

## 🔗 Links

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [MCP Protocol Specification](https://modelcontextprotocol.io)
- [Repository](https://github.com/Spen-Zosky/cce)

---

**CCE v1.0.0** - Complete AI-Powered Development Environment with 9 MCP Servers & 6 AI Agents