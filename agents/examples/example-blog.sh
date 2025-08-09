#!/bin/bash
# Example: Create a blog with MCP agents

echo "📝 Creating a blog with MCP-enhanced agents"

# Use the fullstack workflow
cce-workflow fullstack "my-blog"

# Add specific blog features
cce-agent coder "add markdown support and syntax highlighting for blog posts"

# Generate blog-specific tests
cce-agent tester

# Create deployment configuration
cce-agent deployer vercel