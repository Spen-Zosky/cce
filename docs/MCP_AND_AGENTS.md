# MCP Servers & AI Agents - Complete Guide

## 🔌 MCP Servers (9 Installed)

MCP (Model Context Protocol) servers extend Claude's capabilities to interact with external services and tools.

### ✅ Installed MCP Servers

#### 1. **filesystem** (`@modelcontextprotocol/server-filesystem`)
Access and modify files on your system.
```bash
# Usage in Claude
"Using the filesystem MCP, list all JavaScript files in src/"
"Using the filesystem MCP, create a new config.json file"
```

#### 2. **github** (`@modelcontextprotocol/server-github`)
Interact with GitHub repositories, issues, and pull requests.
```bash
# Usage in Claude
"Using the github MCP, show recent pull requests"
"Using the github MCP, create an issue for this bug"
```

#### 3. **postgresql** (`postgres-mcp-server`)
Query and manage PostgreSQL databases.
```bash
# Usage in Claude
"Using the postgresql MCP, show all tables in the database"
"Using the postgresql MCP, run SELECT * FROM users"
```

#### 4. **fetch** (`@mokei/mcp-fetch`)
Web scraping and HTTP requests.
```bash
# Usage in Claude
"Using the fetch MCP, get content from https://example.com"
"Using the fetch MCP, extract all links from this webpage"
```

#### 5. **memory** (`@modelcontextprotocol/server-memory`)
Persistent memory storage across Claude sessions.
```bash
# Usage in Claude
"Using the memory MCP, remember this configuration for next time"
"Using the memory MCP, what did we discuss last session?"
```

#### 6. **everything** (`@modelcontextprotocol/server-everything`)
Comprehensive toolkit with multiple capabilities.
```bash
# Usage in Claude
"Using the everything MCP, perform a complex analysis"
```

#### 7. **sequential-thinking** (`@modelcontextprotocol/server-sequential-thinking`)
Step-by-step reasoning for complex problems.
```bash
# Usage in Claude
"Using the sequential-thinking MCP, solve this algorithm problem"
```

#### 8. **sentry** (`@sentry/mcp-server`)
Monitor application errors and performance.
```bash
# Usage in Claude
"Using the sentry MCP, show recent errors in production"
"Using the sentry MCP, analyze error trends this week"
```

#### 9. **firecrawl** (`firecrawl-mcp`)
Advanced web scraping with JavaScript rendering.
```bash
# Usage in Claude
"Using the firecrawl MCP, scrape this SPA website"
"Using the firecrawl MCP, extract data from dynamic content"
```

### 📦 Installation & Management

```bash
# List all available MCP servers
cce-mcp list

# Install a specific server (already done)
cce-mcp install <server-name>

# Enable server in Claude
cce-mcp enable <server-name>
```

### 🚀 Using MCP Servers with Claude

```bash
# Start Claude with specific MCP servers
claude --mcp-servers filesystem,github,fetch

# Start with all servers
claude --mcp-servers filesystem,github,postgresql,fetch,memory,everything,sequential-thinking,sentry,firecrawl
```

### 💡 Practical MCP Examples

#### File Management
```
"Using the filesystem MCP, find all TODO comments in the project"
"Using the filesystem MCP, rename all .js files to .ts"
```

#### Database Operations
```
"Using the postgresql MCP, create a users table with id, name, email"
"Using the postgresql MCP, backup the database schema"
```

#### Web Scraping
```
"Using the fetch MCP, monitor this URL for changes"
"Using the firecrawl MCP, extract product prices from e-commerce site"
```

#### GitHub Integration
```
"Using the github MCP, merge the latest pull request"
"Using the github MCP, list all open issues with 'bug' label"
```

## 🤖 AI Agents System (6 Agents)

Specialized AI agents for different development tasks, each optimized for specific workflows.

### Available Agents

#### 1. **Coder Agent** 🔨
Writes code for specific tasks and features.
```bash
# Command
cce-agent coder "implement user authentication"
cce-coder "create REST API for products"

# Capabilities
- Write new features
- Implement algorithms
- Create APIs
- Build UI components
```

#### 2. **Reviewer Agent** 👀
Reviews code for quality, bugs, and best practices.
```bash
# Command
cce-agent reviewer
cce-review

# Capabilities
- Code quality analysis
- Security vulnerability detection
- Performance optimization suggestions
- Best practices compliance
```

#### 3. **Tester Agent** 🧪
Generates comprehensive test suites.
```bash
# Command
cce-agent tester
cce-test

# Capabilities
- Unit test generation
- Integration test creation
- E2E test scenarios
- Test coverage analysis
```

#### 4. **Documenter Agent** 📚
Creates complete documentation.
```bash
# Command
cce-agent documenter
cce-docs

# Capabilities
- README generation
- API documentation
- Code comments
- Usage examples
- Architecture diagrams (as text)
```

#### 5. **Debugger Agent** 🐛
Finds and fixes bugs.
```bash
# Command
cce-agent debugger "undefined variable error"
cce-debug "application crashes on startup"

# Capabilities
- Error analysis
- Root cause identification
- Bug fixes
- Performance debugging
```

#### 6. **Deployer Agent** 🚀
Prepares deployment configurations.
```bash
# Command
cce-agent deployer "vercel"
cce-deploy "aws"

# Capabilities
- Dockerfile creation
- CI/CD pipeline setup
- Deployment scripts
- Environment configuration
- Cloud platform setup (Vercel, AWS, etc.)
```

### 🎭 Multi-Agent Orchestration

Coordinate multiple agents for complex projects:

```bash
# Create a full-stack application
cce-multi-agent my-app fullstack

# Workflow stages:
# 1. Coder Agent - Creates project structure
# 2. Enhancer Agent - Adds auth, database, APIs
# 3. Tester Agent - Generates test suites
# 4. Documenter Agent - Creates documentation
```

### 📋 Agent Usage Patterns

#### Sequential Workflow
```bash
# 1. Write code
cce-coder "implement shopping cart"

# 2. Review the code
cce-review

# 3. Generate tests
cce-test

# 4. Document
cce-docs
```

#### Debugging Workflow
```bash
# 1. Debug error
cce-debug "TypeError: Cannot read property"

# 2. Review fix
cce-review

# 3. Test fix
cce-test
```

#### Deployment Workflow
```bash
# 1. Review code
cce-review

# 2. Generate tests
cce-test

# 3. Create deployment
cce-deploy "vercel"
```

### 🔧 Advanced Agent Features

#### Custom Agent Chains
Combine agents for specific workflows:
```bash
# Development cycle
cce-coder "new feature" && cce-test && cce-review

# Documentation update
cce-docs && cce-review
```

#### Agent Context Sharing
Agents can build on each other's work:
```bash
# Coder creates, tester validates
cce-coder "API endpoint"
cce-test  # Tests the newly created endpoint
```

## 🌟 Best Practices

### MCP Servers
1. **Start with essential servers**: filesystem, github, fetch
2. **Add specialized servers as needed**: postgresql for DB work
3. **Use memory server** for maintaining context across sessions
4. **Combine servers** for complex tasks

### AI Agents
1. **Use the right agent** for each task
2. **Chain agents** for complete workflows
3. **Review after coding** to catch issues early
4. **Test before deploying** always
5. **Document as you go** for maintainability

## 📊 Performance Tips

### MCP Optimization
- Use specific file paths with filesystem MCP
- Batch database queries with postgresql MCP
- Cache results with memory MCP
- Use firecrawl for JavaScript-heavy sites

### Agent Efficiency
- Provide clear, specific instructions
- Use multi-agent for large projects
- Run review agent before committing
- Generate tests for critical code

## 🚨 Troubleshooting

### MCP Issues
```bash
# Server not responding
cce-mcp list  # Check installation
claude --mcp-servers <server>  # Test specific server

# Permission errors
# Ensure proper file permissions for filesystem MCP
```

### Agent Issues
```bash
# Agent not found
cce-agent  # List available agents

# Agent timeout
# Break large tasks into smaller ones
```

## 📚 Examples Gallery

### Full-Stack Development
```bash
# Create project
cce-multi-agent todo-app fullstack

# Add specific features
cce-coder "add user authentication"
cce-coder "implement task categories"

# Test everything
cce-test

# Deploy
cce-deploy "vercel"
```

### API Development
```bash
# Design API
cce-coder "REST API for blog posts"

# Generate tests
cce-test

# Document API
cce-docs

# Review security
cce-review
```

### Bug Fixing
```bash
# Debug issue
cce-debug "users cannot login"

# Test fix
cce-test

# Document change
cce-docs
```

## 🔗 Resources

- [MCP Protocol Documentation](https://modelcontextprotocol.io)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Agent Patterns Guide](https://github.com/Spen-Zosky/cce/wiki/agents)

---

**Last Updated**: 2025 | **CCE Version**: 1.0.0 | **Total MCP Servers**: 9 | **Total Agents**: 6