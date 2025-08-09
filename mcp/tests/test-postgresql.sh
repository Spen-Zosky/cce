#!/bin/bash
echo "🐘 Testing PostgreSQL MCP..."
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  DATABASE_URL not set. Using default: postgresql://localhost/postgres"
fi
claude --mcp-config ~/.config/claude/config.json -p "Using the postgresql MCP, show the current database version"