#!/usr/bin/env bash
# Build a Docker Sandboxes template image with NanoClaw prerequisites baked in.
#
# Usage: ./build-template.sh [TAG]   (default: nanoclaw:dev)
#
# Produces:
#   - a local sandbox image tagged ${TAG}
#   - ./out/${TAG//:/_}.tar          (shareable, importable via `sbx template load`)
set -euo pipefail

TAG="${1:-nanoclaw:dev}"
SBX_NAME="nanoclaw-tpl-build-$$"
WORKDIR="$(mktemp -d -t nanoclaw-tpl.XXXXXX)"

cleanup() {
  sbx rm -f "$SBX_NAME" >/dev/null 2>&1 || true
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

# 1. Provision a shell sandbox
sbx create --name "$SBX_NAME" shell "$WORKDIR"

# 2. Install OS toolchain, Node (matching upstream .nvmrc), pnpm, warm pnpm store
sbx exec -u root "$SBX_NAME" bash -s <<'BAKE'
set -euxo pipefail
apt-get update
apt-get install -y --no-install-recommends \
  build-essential python3 python3-pip git curl ca-certificates jq

NODE_MAJOR=$(curl -fsSL https://raw.githubusercontent.com/qwibitai/nanoclaw/main/.nvmrc | tr -d 'v\n' | cut -d. -f1)
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
apt-get install -y nodejs
corepack enable
corepack prepare pnpm@latest --activate
npm config set strict-ssl false --global

# Warm pnpm content-addressable store with nanoclaw deps
git clone --depth=1 -b sandbox-ready https://github.com/ealeyner/nanoclaw.git /opt/nanoclaw-reference || \
  git clone --depth=1 https://github.com/qwibitai/nanoclaw.git /opt/nanoclaw-reference
( cd /opt/nanoclaw-reference && pnpm install --prefer-offline ) || true

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache/node-gyp /root/.npm/_logs
BAKE

# 3. Install the nanoclaw-init helper
sbx exec -u root "$SBX_NAME" bash -c 'cat > /usr/local/bin/nanoclaw-init' < scripts/nanoclaw-init
sbx exec -u root "$SBX_NAME" chmod +x /usr/local/bin/nanoclaw-init

# 4. Snapshot
mkdir -p out
OUT_TAR="out/${TAG//:/_}.tar"
sbx template save "$SBX_NAME" "$TAG" --output "$OUT_TAR"
sbx template ls
echo "✓ Template saved: $TAG"
echo "✓ Tarball:        $OUT_TAR"
