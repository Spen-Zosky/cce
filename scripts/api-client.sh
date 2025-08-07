#!/usr/bin/env bash
# CCE API Client Helper

API_BASE="http://localhost:3456/api/v1"

# Get current port if server is running
if [ -f ~/.cce-universal/web/server.pid ]; then
    PORT=$(lsof -p $(cat ~/.cce-universal/web/server.pid) -P -n 2>/dev/null | grep LISTEN | awk '{print $9}' | cut -d: -f2 | head -1)
    API_BASE="http://localhost:${PORT:-3456}/api/v1"
fi

call_api() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="$3"
    
    if [ "$method" = "GET" ]; then
        curl -s "$API_BASE/$endpoint" | jq '.' 2>/dev/null || curl -s "$API_BASE/$endpoint"
    else
        curl -s -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_BASE/$endpoint" | jq '.' 2>/dev/null || curl -s -X "$method" -H "Content-Type: application/json" -d "$data" "$API_BASE/$endpoint"
    fi
}

# Convenience functions
cce_api_health() {
    call_api "health"
}

cce_api_system() {
    call_api "system"
}

cce_api_projects() {
    call_api "projects"
}

cce_api_config() {
    call_api "config"
}

cce_api_execute() {
    local command="$1"
    shift
    local args="$*"
    call_api "execute" "POST" "{\"command\":\"$command\",\"args\":[\"$args\"]}"
}

# Export functions if sourced
export -f call_api cce_api_health cce_api_system cce_api_projects cce_api_config cce_api_execute
