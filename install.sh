#!/bin/sh
# Install remotecli — Remote.com partner API CLI.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/remoteoss/remote-cli/main/install.sh | sh
#
# Env overrides:
#   INSTALL_DIR   default: /usr/local/bin
#   VERSION       default: latest (e.g. v1.2.0 to pin)
#   REPO          default: remoteoss/remote-cli (rarely needed)

set -eu

REPO="${REPO:-remoteoss/remote-cli}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
VERSION="${VERSION:-latest}"

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    darwin|linux) ;;
    *)
        printf 'unsupported OS: %s\n' "$OS" >&2
        exit 1
        ;;
esac

ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
    arm64|aarch64) ARCH=arm64 ;;
    x86_64|amd64)  ARCH=amd64 ;;
    *)
        printf 'unsupported architecture: %s\n' "$ARCH_RAW" >&2
        exit 1
        ;;
esac

# Published binaries today: darwin/arm64 and linux/amd64. Other combos error early.
case "$OS-$ARCH" in
    darwin-arm64|linux-amd64) ;;
    *)
        printf 'no published binary for %s-%s\n' "$OS" "$ARCH" >&2
        printf 'published: darwin-arm64, linux-amd64\n' >&2
        exit 1
        ;;
esac

ASSET="remotecli-${OS}-${ARCH}"
if [ "$VERSION" = "latest" ]; then
    URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"
else
    URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT INT TERM

printf 'Downloading %s\n' "$URL"
if ! curl -fsSL -o "$TMP" "$URL"; then
    printf 'download failed: %s\n' "$URL" >&2
    exit 1
fi

chmod +x "$TMP"

DEST="$INSTALL_DIR/remotecli"
mkdir -p "$INSTALL_DIR" 2>/dev/null || true

if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP" "$DEST"
else
    printf 'Installing to %s requires elevated permissions.\n' "$INSTALL_DIR"
    sudo mv "$TMP" "$DEST"
fi

# mv consumed the tempfile; clear the trap so EXIT doesn't try to remove a missing path.
trap - EXIT INT TERM

printf 'Installed: %s\n' "$DEST"
"$DEST" --version
