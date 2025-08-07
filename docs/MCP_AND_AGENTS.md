# MCP Servers & Agents

## MCP Servers

MCP (Model Context Protocol) servers allow Claude to interact with external services.

### Available Servers

- filesystem: Access and modify files
- postgresql: Query PostgreSQL databases
- sqlite: Work with SQLite databases
- github: Interact with GitHub API

### Usage Examples

List available servers:
    cce-mcp list

Install a server:
    cce-mcp install postgresql

Enable in Claude:
    cce-mcp enable postgresql

## Agents System

Specialized AI agents for specific development tasks.

### Single Agent Commands

    cce-agent coder "create a REST API"
    cce-agent reviewer
    cce-agent tester
    cce-agent documenter
    cce-agent debugger "undefined variable error"
    cce-agent deployer "vercel"

### Multi-Agent Orchestration

    cce-multi-agent my-app fullstack

### Quick Shortcuts

    cce-coder "implement user auth"
    cce-review
    cce-test
    cce-docs
    cce-debug "error message"
    cce-deploy "aws"

## How It Works

Agents are specialized Claude prompts that focus on specific tasks.
Multi-agent runs multiple agents in sequence for complete project setup.
