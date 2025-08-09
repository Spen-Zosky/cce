#!/usr/bin/env bash
# Sync CCE configuration across environments

SYNC_REPO="${CCE_SYNC_REPO:-}"
SYNC_BRANCH="${CCE_SYNC_BRANCH:-main}"

sync_push() {
    if [ -z "$SYNC_REPO" ]; then
        echo "❌ No sync repository configured"
        echo "Set CCE_SYNC_REPO environment variable"
        return 1
    fi
    
    echo "📤 Pushing CCE configuration..."
    
    # Create temporary sync directory
    SYNC_DIR=$(mktemp -d)
    cd "$SYNC_DIR" || exit 1
    
    # Initialize git repo
    git init
    git remote add origin "$SYNC_REPO"
    
    # Copy configuration files
    cp -r ~/.claude .claude
    cp -r ~/.cce-universal .cce-universal
    
    # Create sync manifest
    cat > sync-manifest.json << MANIFEST
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": "$(~/.cce-universal/scripts/detect-env.sh)",
  "hostname": "$(hostname)",
  "version": "1.0.0"
}
MANIFEST
    
    # Commit and push
    git add .
    git commit -m "CCE sync from $(hostname) at $(date -u +"%Y-%m-%d %H:%M UTC")"
    git push -u origin "$SYNC_BRANCH" --force
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$SYNC_DIR"
    
    echo "✅ Configuration synced"
}

sync_pull() {
    if [ -z "$SYNC_REPO" ]; then
        echo "❌ No sync repository configured"
        return 1
    fi
    
    echo "📥 Pulling CCE configuration..."
    
    # Backup current config
    BACKUP_DIR=~/.cce-backup-$(date +%Y%m%d-%H%M%S)
    mkdir -p "$BACKUP_DIR"
    [ -d ~/.claude ] && cp -r ~/.claude "$BACKUP_DIR/"
    [ -d ~/.cce-universal ] && cp -r ~/.cce-universal "$BACKUP_DIR/"
    
    # Pull configuration
    SYNC_DIR=$(mktemp -d)
    cd "$SYNC_DIR" || exit 1
    
    git clone "$SYNC_REPO" . --branch "$SYNC_BRANCH" --depth 1
    
    # Apply configuration
    [ -d .claude ] && cp -r .claude ~/
    [ -d .cce-universal ] && cp -r .cce-universal ~/
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$SYNC_DIR"
    
    echo "✅ Configuration pulled"
    echo "📁 Backup saved to: $BACKUP_DIR"
}

case "${1:-}" in
    push) sync_push ;;
    pull) sync_pull ;;
    *)
        echo "Usage: $0 {push|pull}"
        echo ""
        echo "Configure with:"
        echo "  export CCE_SYNC_REPO='git@github.com:username/cce-config.git'"
        echo "  export CCE_SYNC_BRANCH='main'"
        ;;
esac
