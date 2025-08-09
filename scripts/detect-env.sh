#!/usr/bin/env bash
# Detect current environment

ENV_TYPE="unknown"
ARCH=$(uname -m)

# Normalize architecture
case "$ARCH" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
esac

# Detect environment type
if grep -qi microsoft /proc/version 2>/dev/null; then
    ENV_TYPE="wsl"
elif [ -f /.dockerenv ]; then
    ENV_TYPE="docker"
elif [ -f /sys/class/dmi/id/product_name ] 2>/dev/null; then
    PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
    if [[ "$PRODUCT" == *"Virtual"* ]] || [[ "$PRODUCT" == *"VM"* ]]; then
        ENV_TYPE="vm"
    else
        ENV_TYPE="native"
    fi
else
    ENV_TYPE="native"
fi

echo "$ENV_TYPE:$ARCH"
