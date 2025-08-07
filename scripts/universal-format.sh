#!/usr/bin/env bash
# Universal formatter - works across all platforms

FILE="$1"
[ ! -f "$FILE" ] && exit 0

# Source environment adapter
source ~/.cce-universal/adapters/env-adapter.sh

# Normalize path for cross-platform
FILE=$(normalize_path "$FILE")

# Get file extension
EXT="${FILE##*.}"
FILENAME=$(basename "$FILE")

# Detect and apply appropriate formatter
format_javascript() {
    if command -v prettier &> /dev/null; then
        prettier --write "$FILE" 2>/dev/null
    elif command -v npx &> /dev/null; then
        npx -y prettier --write "$FILE" 2>/dev/null
    fi
}

format_python() {
    if command -v black &> /dev/null; then
        black "$FILE" 2>/dev/null
    elif command -v autopep8 &> /dev/null; then
        autopep8 --in-place "$FILE" 2>/dev/null
    elif command -v ruff &> /dev/null; then
        ruff format "$FILE" 2>/dev/null
    fi
}

format_rust() {
    if command -v rustfmt &> /dev/null; then
        rustfmt "$FILE" 2>/dev/null
    fi
}

format_go() {
    if command -v gofmt &> /dev/null; then
        gofmt -w "$FILE" 2>/dev/null
    elif command -v goimports &> /dev/null; then
        goimports -w "$FILE" 2>/dev/null
    fi
}

# Apply formatting based on extension
case "$EXT" in
    js|jsx|ts|tsx|json|md|mdx|yaml|yml)
        format_javascript ;;
    py|pyw)
        format_python ;;
    rs)
        format_rust ;;
    go)
        format_go ;;
    sh|bash)
        if command -v shfmt &> /dev/null; then
            shfmt -w "$FILE" 2>/dev/null
        fi ;;
esac

# TypeScript type checking
if [[ "$EXT" =~ ^(ts|tsx)$ ]]; then
    if [ -f "tsconfig.json" ] && command -v npx &> /dev/null; then
        npx -y tsc --noEmit --skipLibCheck "$FILE" 2>/dev/null || true
    fi
fi
