# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CCE (Claude Code Ecosystem) is a comprehensive AI-powered development environment that integrates deeply with Claude AI to provide rapid application development, code generation, and multi-agent orchestration capabilities.

## Build and Development Commands

### Core Setup Commands
```bash
# Initial setup (run once after cloning)
./install.sh
source ~/.bashrc

# Check system status
cce-info

# Initialize CCE in a project
cce-init
```

### Project Creation
```bash
# Create Next.js + PostgreSQL project
cce-create <project-name>

# Create super app with all features
cce-super
```

### Code Generation
```bash
# Generate CRUD API for a model
cce-crud <ModelName>

# Setup NextAuth.js authentication
cce-auth

# Generate UI components
cce-ui-gen <ComponentName>

# Generate API endpoints
cce-api-gen <endpoint-name>
```

### Database Operations
```bash
# Open Prisma Studio
cce-db

# Run migrations
cce-migrate

# Push schema changes
cce-db-push

# Reset database
cce-db-reset
```

### AI Agent Commands
```bash
# Single agent usage
cce-agent <agent-type> "<task>"
# Available agents: coder, reviewer, tester, documenter, debugger, deployer

# Multi-agent orchestration
cce-multi-agent <project-name> <workflow-type>
# Workflow types: fullstack, backend, frontend, api
```

### MCP Server Management
```bash
# List available MCP servers
cce-mcp list

# Install MCP server
cce-mcp install <server-name>

# Enable MCP server
cce-mcp enable <server-name>
```

## Architecture and Structure

### Directory Organization
- **scripts/**: Core utility scripts for environment setup and operations
- **agents/**: AI agent definitions and orchestration logic
- **mcp/**: Model Context Protocol server configurations
- **templates/**: Project templates (Next.js + PostgreSQL focus)
- **generators/**: Code generation scripts for CRUD, auth, UI, and APIs
- **adapters/**: Environment-specific adaptation scripts
- **config/**: Configuration files for CCE, Claude CLI, and MCP
- **web/**: Web dashboard components (Node.js server)
- **docs/**: Documentation for MCP and agent systems

### Technology Stack
The ecosystem is optimized for:
- **Frontend**: Next.js 14 App Router, TypeScript, Tailwind CSS, shadcn/ui
- **Backend**: Next.js API routes, Prisma ORM
- **Database**: PostgreSQL (primary), SQLite (development)
- **Authentication**: NextAuth.js
- **State Management**: React Query
- **Deployment**: Vercel-ready configurations

### Key Scripts

**Universal Formatter** (scripts/universal-format.sh):
- Handles cross-platform path formatting
- Manages line endings (LF/CRLF)
- Normalizes file operations

**Agent Manager** (agents/agent-manager.sh):
- Coordinates single-agent tasks
- Manages agent prompts and responses
- Integrates with Claude CLI

**Multi-Agent Orchestrator** (agents/multi-agent.sh):
- Coordinates multiple agents for complex workflows
- Implements fullstack, backend, frontend, and API workflows
- Manages inter-agent dependencies

**MCP Manager** (mcp/mcp-manager.sh):
- Manages MCP server installation and configuration
- Handles server enabling/disabling
- Updates Claude configuration

## Development Patterns

### When Creating New Features
1. Use existing templates in `templates/` as reference
2. Follow Next.js 14 App Router patterns
3. Use Prisma for database operations
4. Implement with TypeScript
5. Style with Tailwind CSS and shadcn/ui components

### When Generating Code
1. Check for existing generators in `generators/`
2. Use `cce-crud` for API endpoints with models
3. Use `cce-auth` for authentication setup
4. Follow RESTful API conventions

### Environment Considerations
- Always use `#!/usr/bin/env bash` for scripts
- Handle both WSL and native Linux environments
- Use forward slashes for paths
- Assume case-sensitive filesystems

### Database Workflow
1. Define models in `prisma/schema.prisma`
2. Run `cce-db-push` to update database
3. Use `cce-db` to view data in Prisma Studio
4. Generate CRUD operations with `cce-crud`

### Agent Usage Guidelines
- Use `coder` agent for implementation tasks
- Use `reviewer` agent before committing code
- Use `tester` agent to generate test suites
- Use `documenter` for API documentation
- Use `debugger` with specific error messages
- Use `deployer` for deployment configurations

## Important Environment Variables
```bash
CCE_ENV        # Environment type (wsl/vm/native)
CCE_ARCH       # Architecture (amd64/arm64)
CCE_HOME       # CCE installation directory (~/.cce-universal)
ANTHROPIC_API_KEY  # Required for Claude integration
```

## Cross-Platform Compatibility
- Scripts automatically detect and adapt to environment
- Path separators normalized to forward slashes
- Line endings handled appropriately per platform
- Architecture-specific optimizations applied automatically

## Testing Approach
While no specific test framework is configured by default, use:
- `cce-test` to generate comprehensive test suites
- The tester agent for test generation
- Multi-agent workflows include testing as standard step

## MCP Integration (9 Servers Installed)
Available MCP servers extend Claude's capabilities:
- **filesystem**: File system access and modification
- **github**: GitHub API integration
- **postgresql**: PostgreSQL database queries
- **fetch**: Web scraping and HTTP requests
- **memory**: Persistent memory storage
- **everything**: Comprehensive toolkit
- **sequential-thinking**: Step-by-step reasoning
- **sentry**: Error monitoring
- **firecrawl**: Advanced web scraping

Configure in `config/mcp-config.json` and manage with `cce-mcp` commands.

Start Claude with MCP servers:
```bash
claude --mcp-servers filesystem,github,postgresql,fetch,memory,everything,sequential-thinking,sentry,firecrawl
```