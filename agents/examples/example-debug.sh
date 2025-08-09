#!/bin/bash
# Example: Debug a complex issue

echo "🐛 Debugging authentication issue"

# Use debug workflow
cce-workflow debug "users cannot login after password reset"

# Run additional analysis
cce-agent analyzer

# Ensure fix is tested
cce-chain quality