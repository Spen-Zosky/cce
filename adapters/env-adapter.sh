#!/bin/bash
# Environment-specific adaptations

get_home_dir() {
    echo "$HOME"
}

get_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/package.json" ] || [ -f "$dir/.git/config" ] || [ -f "$dir/.claude/settings.json" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

normalize_path() {
    local path="$1"
    # Convert Windows paths if in WSL
    if [[ "$path" =~ ^[A-Za-z]: ]]; then
        if command -v wslpath &> /dev/null; then
            wslpath -u "$path"
        else
            echo "$path"
        fi
    else
        echo "$path"
    fi
}

detect_line_ending() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "auto"  # Let git handle it
    else
        echo "lf"
    fi
}
