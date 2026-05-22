#!/usr/bin/env bash
set -euo pipefail

# Swift toolchain for Ubuntu 24.04 (x86_64) — installs once, then cached.
# REQUIRES the environment's Network access = Full (or Custom incl. swift.org).

# Linux-x86_64-only installer: only run in Claude Code on the web.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  echo "Not a remote (web) session — skipping Swift toolchain install."
  exit 0
fi

SWIFT_VERSION="6.3.2"
TAG="swift-${SWIFT_VERSION}-RELEASE"
BRANCH="swift-${SWIFT_VERSION}-release"
PLATDIR="ubuntu2404"
UBUNTU="ubuntu24.04"
INSTALL_DIR="/opt/swift"
URL="https://download.swift.org/${BRANCH}/${PLATDIR}/${TAG}/${TAG}-${UBUNTU}.tar.gz"

# Already installed (warm cache)? Done.
if swift --version >/dev/null 2>&1; then
  echo "Swift present: $(swift --version | head -1)"; exit 0
fi

SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
export DEBIAN_FRONTEND=noninteractive

# Dependencies (in background)...
$SUDO apt-get update -qq
$SUDO apt-get install -y --no-install-recommends \
  binutils git unzip gnupg2 ca-certificates curl \
  libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev \
  libpython3-dev libstdc++-13-dev libxml2-dev libz3-dev \
  libncurses-dev pkg-config tzdata zlib1g-dev &
apt_pid=$!

# ...while the toolchain downloads in parallel
echo "Downloading $URL"
curl -fSL --retry 4 --retry-delay 2 -o /tmp/swift.tar.gz "$URL"
wait "$apt_pid"

# Install
$SUDO mkdir -p "$INSTALL_DIR"
$SUDO tar -xzf /tmp/swift.tar.gz -C "$INSTALL_DIR" --strip-components=1
rm -f /tmp/swift.tar.gz

# Make available in every shell (profile + symlinks as a fallback)
echo "export PATH=${INSTALL_DIR}/usr/bin:\$PATH" | $SUDO tee /etc/profile.d/swift.sh >/dev/null
$SUDO ln -sf "${INSTALL_DIR}/usr/bin/swift"  /usr/local/bin/swift
$SUDO ln -sf "${INSTALL_DIR}/usr/bin/swiftc" /usr/local/bin/swiftc

# Persist PATH for the rest of this session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=${INSTALL_DIR}/usr/bin:\$PATH" >> "$CLAUDE_ENV_FILE"
fi

export PATH="${INSTALL_DIR}/usr/bin:$PATH"
swift --version
echo "Swift ${SWIFT_VERSION} ready."
