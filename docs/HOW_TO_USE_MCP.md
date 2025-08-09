# How to Use MCP with Claude - Practical Guide

## 🚀 Quick Start

### 1. Install MCP Servers (Already Done!)
All 9 MCP servers are already installed in `~/.cce-universal/mcp-servers/`

### 2. Start Claude with MCP
```bash
# With MCP configuration file (RECOMMENDED)
claude --mcp-config ~/.claude/claude_desktop_config.json

# OR with specific servers
claude --mcp-servers filesystem,github,fetch

# OR with all installed servers
claude --mcp-servers filesystem,github,postgresql,fetch,memory,everything,sequential-thinking,sentry,firecrawl
```

### 3. Use MCP in Your Prompts
Simply prefix your request with "Using the [server-name] MCP"

## 📋 MCP Server Examples

### 🗂️ Filesystem MCP
Access and modify files on your system.

```bash
# List files
"Using the filesystem MCP, list all files in the current directory"

# Read files
"Using the filesystem MCP, read the package.json file"

# Create files
"Using the filesystem MCP, create a new config.yaml with these settings..."

# Search files
"Using the filesystem MCP, find all TODO comments in .js files"

# Modify files
"Using the filesystem MCP, rename all .css files to .scss"
```

### 🐙 GitHub MCP
Interact with GitHub repositories.

```bash
# Repository info
"Using the github MCP, show repository statistics"

# Pull requests
"Using the github MCP, list open pull requests"
"Using the github MCP, review PR #123"

# Issues
"Using the github MCP, create an issue titled 'Bug in login'"
"Using the github MCP, close issue #456"

# Commits
"Using the github MCP, show recent commits"
```

### 🐘 PostgreSQL MCP
Query and manage PostgreSQL databases.

```bash
# Database structure
"Using the postgresql MCP, show all tables"
"Using the postgresql MCP, describe the users table"

# Queries
"Using the postgresql MCP, SELECT * FROM products WHERE price < 100"
"Using the postgresql MCP, count users created this month"

# Modifications
"Using the postgresql MCP, create a new orders table"
"Using the postgresql MCP, add an index on email column"
```

### 🌐 Fetch MCP
Web scraping and HTTP requests.

```bash
# Get content
"Using the fetch MCP, get content from https://example.com"

# Extract data
"Using the fetch MCP, extract all links from this webpage"
"Using the fetch MCP, get all image URLs from the site"

# API calls
"Using the fetch MCP, make a GET request to the API endpoint"
"Using the fetch MCP, POST this data to the webhook"
```

### 🧠 Memory MCP
Persistent storage across sessions.

```bash
# Store information
"Using the memory MCP, remember this API configuration"
"Using the memory MCP, save these project requirements"

# Retrieve information
"Using the memory MCP, what did we discuss about authentication?"
"Using the memory MCP, recall the database schema we designed"

# Manage memory
"Using the memory MCP, list all stored items"
"Using the memory MCP, clear old project data"
```

### 🔥 Firecrawl MCP
Advanced web scraping with JavaScript support.

```bash
# SPA scraping
"Using the firecrawl MCP, scrape this React application"

# Dynamic content
"Using the firecrawl MCP, wait for content to load then extract data"

# Complex scraping
"Using the firecrawl MCP, navigate through pagination and collect all items"
```

### 🚨 Sentry MCP
Monitor application errors.

```bash
# Error monitoring
"Using the sentry MCP, show recent errors in production"
"Using the sentry MCP, analyze error patterns this week"

# Performance
"Using the sentry MCP, check performance metrics"
"Using the sentry MCP, identify slow endpoints"
```

### 🎯 Everything MCP
Comprehensive toolkit for various tasks.

```bash
"Using the everything MCP, analyze this codebase structure"
"Using the everything MCP, optimize this configuration"
```

### 🤔 Sequential-Thinking MCP
Step-by-step problem solving.

```bash
"Using the sequential-thinking MCP, solve this algorithm problem"
"Using the sequential-thinking MCP, plan the architecture for this feature"
```

## 🔄 Combining Multiple MCP Servers

You can use multiple MCP servers in a single session:

```bash
# Example: Full-stack development workflow
"Using the filesystem MCP, create a new Next.js project structure"
"Using the github MCP, check if similar projects exist"
"Using the postgresql MCP, design the database schema"
"Using the memory MCP, save this architecture for reference"
```

## 💡 Practical Workflows

### 📱 Web Development
```bash
# 1. Setup project
"Using the filesystem MCP, create React app structure"

# 2. Fetch inspiration
"Using the fetch MCP, get examples from design websites"

# 3. Save configuration
"Using the memory MCP, remember these design choices"

# 4. Version control
"Using the github MCP, create initial commit"
```

### 🔍 Research & Analysis
```bash
# 1. Gather data
"Using the fetch MCP, scrape data from these 5 websites"

# 2. Store in database
"Using the postgresql MCP, create tables and insert scraped data"

# 3. Analyze
"Using the postgresql MCP, run analysis queries"

# 4. Document findings
"Using the filesystem MCP, create a report.md with results"
```

### 🐛 Debugging
```bash
# 1. Check errors
"Using the sentry MCP, show recent errors"

# 2. Examine code
"Using the filesystem MCP, read the problematic file"

# 3. Check GitHub
"Using the github MCP, see if others reported this issue"

# 4. Fix and test
"Using the filesystem MCP, apply the fix"
```

### 📊 Database Management
```bash
# 1. Backup
"Using the postgresql MCP, export schema and data"

# 2. Migrate
"Using the filesystem MCP, create migration files"

# 3. Apply changes
"Using the postgresql MCP, run migrations"

# 4. Verify
"Using the postgresql MCP, validate data integrity"
```

## 🎯 Pro Tips

### 1. **Be Specific**
```bash
# Good
"Using the filesystem MCP, read src/components/Header.jsx"

# Better
"Using the filesystem MCP, read the Header component and identify state management"
```

### 2. **Chain Operations**
```bash
"Using the filesystem MCP, find all .env files, then using the memory MCP, store their locations"
```

### 3. **Use Memory for Context**
```bash
"Using the memory MCP, remember this is a Next.js 14 project with TypeScript"
```

### 4. **Combine with Agents**
```bash
# Use MCP to gather info, then agents to act
"Using the github MCP, check open issues"
cce-coder "fix the authentication bug from issue #123"
```

## 🛠️ Configuration

### Quick Setup
```bash
# Check MCP status
cce-mcp list

# Test MCP integration
cce-mcp test

# Setup environment variables (optional)
cp ~/.cce-universal/config/mcp-env.template ~/.bashrc
# Edit ~/.bashrc to add your API keys
source ~/.bashrc
```

### Environment Variables
Some MCP servers require configuration:

```bash
# GitHub (for github MCP)
export GITHUB_TOKEN="ghp_your_token_here"

# PostgreSQL (for postgresql MCP)
export DATABASE_URL="postgresql://user:pass@localhost:5432/db"

# Sentry (for sentry MCP)
export SENTRY_AUTH_TOKEN="your_sentry_token"
export SENTRY_ORG="your_org_slug"
export SENTRY_PROJECT="your_project_slug"

# Firecrawl (for firecrawl MCP)
export FIRECRAWL_API_KEY="fc_your_api_key"
```

### Configuration Files
- **Claude MCP Config**: `~/.claude/claude_desktop_config.json` (auto-created)
- **Environment Template**: `~/.cce-universal/config/mcp-env.template`
- **CCE MCP Config**: `~/.cce-universal/config/mcp-config.json`

## ⚠️ Troubleshooting

### MCP Not Working
```bash
# Check MCP status and installation
cce-mcp list

# Test all components
cce-mcp test

# Check Claude configuration
ls -la ~/.claude/claude_desktop_config.json
```

### Server Not Working
```bash
# Check installation status
cce-mcp list

# Check specific server installation
ls -la ~/.cce-universal/mcp-servers/node_modules/@modelcontextprotocol/server-*

# Reinstall specific server
cce-mcp install filesystem

# Reinstall all servers
cce-mcp install all
```

### Agent Integration Issues
```bash
# Test agent system
cce-agent

# Test with MCP integration
cce-agent analyzer "analyze this directory"
```

### Environment Variable Issues
```bash
# Check current environment
echo $GITHUB_TOKEN
echo $DATABASE_URL

# Load environment template
source ~/.cce-universal/config/mcp-env.template

# Test API connections
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

### Permission Issues
```bash
# Filesystem MCP needs file permissions
chmod +r file.txt  # Read permission
chmod +w file.txt  # Write permission

# Check CCE permissions
ls -la ~/.cce-universal/bin/
```

## 📚 Advanced Examples

### Complete Project Setup
```bash
# 1. Create structure
"Using the filesystem MCP, create a Next.js project structure with src/, components/, pages/"

# 2. Setup database
"Using the postgresql MCP, create database schema for e-commerce"

# 3. Generate code
cce-crud Product

# 4. Add to GitHub
"Using the github MCP, create repository and initial commit"

# 5. Document
"Using the filesystem MCP, create comprehensive README.md"
```

### Data Pipeline
```bash
# 1. Scrape data
"Using the firecrawl MCP, scrape product data from e-commerce sites"

# 2. Process
"Using the sequential-thinking MCP, clean and normalize the data"

# 3. Store
"Using the postgresql MCP, insert processed data into products table"

# 4. Monitor
"Using the sentry MCP, track any errors in the pipeline"
```

## 🎉 Quick Commands Reference

```bash
# Check MCP status and list servers
cce-mcp list

# Test MCP integration
cce-mcp test

# Start Claude with MCP configuration (RECOMMENDED)
claude --mcp-config ~/.claude/claude_desktop_config.json

# OR start Claude with specific servers
claude --mcp-servers filesystem,github,postgresql,fetch,memory

# Use CCE agents with MCP integration
cce-agent coder "create a new component"
cce-agent analyzer "analyze the codebase"
cce-agent reviewer "review recent changes"

# Common MCP patterns
"Using the [server] MCP, [action]"
```

### MCP Management Commands
```bash
cce-mcp list          # Show all servers and status
cce-mcp test          # Test configuration and installation  
cce-mcp install all   # Install all MCP servers
cce-mcp setup         # Create Claude configuration
cce-mcp enable        # Check if servers are enabled
```

---

## ✅ Setup Verification

Your MCP and Agents systems are now **fully configured and activated**!

**Status**: 
- ✅ **Claude Configuration**: `~/.claude/claude_desktop_config.json` created
- ✅ **All 9 MCP Servers**: Installed and configured
- ✅ **Agents Integration**: Ready with MCP enhancement
- ✅ **Environment Template**: Available in `config/mcp-env.template`

**Next Steps**:
1. **Optional**: Add API keys to enable servers that need them (GitHub, Sentry, etc.)
2. **Test**: Run `cce-agent coder "create a hello world app"` to test integration
3. **Use**: Start Claude with `claude --mcp-config ~/.claude/claude_desktop_config.json`

**Remember**: MCP servers extend Claude's capabilities. Use them to interact with external systems, automate tasks, and build complex workflows!

**CCE Version**: 1.0.0 | **Total MCP Servers**: 9 | **Status**: ✅ **FULLY ACTIVATED**