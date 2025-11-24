#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Settings (you can override via environment variables)
# ------------------------------------------------------------
SCUDA_REPO_URL="${SCUDA_REPO_URL:-https://github.com/kevmo314/scuda.git}"
SCUDA_DIR="${SCUDA_DIR:-$HOME/scuda}"
INSTALL_DIR="${INSTALL_DIR:-/opt/scuda}"

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------
log() {
  printf '[SCUDA] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    log "Please install it with your package manager and re-run this script."
    exit 1
  fi
}

# ------------------------------------------------------------
# Checks
# ------------------------------------------------------------
require_cmd git
require_cmd cmake
require_cmd python3

# nvcc optional but recommended
if ! command -v nvcc >/dev/null 2>&1; then
  log "Warning: nvcc not found in PATH. Make sure CUDA toolkit is installed."
fi

# ------------------------------------------------------------
# Clone or update SCUDA repo
# ------------------------------------------------------------
if [ -d "$SCUDA_DIR/.git" ]; then
  log "SCUDA directory already exists at: $SCUDA_DIR"
  log "Updating repository..."
  git -C "$SCUDA_DIR" pull --ff-only
else
  log "Cloning SCUDA into: $SCUDA_DIR"
  git clone "$SCUDA_REPO_URL" "$SCUDA_DIR"
fi

cd "$SCUDA_DIR"

# ------------------------------------------------------------
# Run codegen
# ------------------------------------------------------------
if [ -d "codegen" ]; then
  log "Running codegen..."
  cd codegen
  python3 codegen.py
  cd ..
else
  log "ERROR: codegen directory not found in SCUDA repo."
  exit 1
fi

# ------------------------------------------------------------
# Configure & build
# ------------------------------------------------------------
log "Configuring SCUDA with CMake..."
cmake .

log "Building SCUDA..."
cmake --build .

# ------------------------------------------------------------
# Locate artifacts
# ------------------------------------------------------------
log "Searching for built libscuda and server binaries..."

LIB_FILES=()
SERVER_FILES=()

while IFS= read -r -d '' f; do
  LIB_FILES+=("$f")
done < <(find . -maxdepth 2 -type f -name "libscuda_*.so" -print0)

while IFS= read -r -d '' f; do
  SERVER_FILES+=("$f")
done < <(find . -maxdepth 2 -type f -name "server_*.so" -print0)

if [ "${#LIB_FILES[@]}" -eq 0 ]; then
  log "ERROR: No libscuda_*.so files found after build."
  exit 1
fi

if [ "${#SERVER_FILES[@]}" -eq 0 ]; then
  log "ERROR: No server_*.so files found after build."
  exit 1
fi

log "Found libscuda libraries:"
for f in "${LIB_FILES[@]}"; do
  log "  $f"
done

log "Found server binaries:"
for f in "${SERVER_FILES[@]}"; do
  log "  $f"
done

# ------------------------------------------------------------
# Install to INSTALL_DIR
# ------------------------------------------------------------
log "Installing to: $INSTALL_DIR (may require sudo)"

if [ ! -d "$INSTALL_DIR" ]; then
  sudo mkdir -p "$INSTALL_DIR"
fi

for f in "${LIB_FILES[@]}"; do
  sudo cp -f "$f" "$INSTALL_DIR/"
done

for f in "${SERVER_FILES[@]}"; do
  sudo cp -f "$f" "$INSTALL_DIR/"
done

log "Installation complete."

# Pick the first libscuda as default
DEFAULT_LIB="${LIB_FILES[0]}"
BASENAME_LIB="$(basename "$DEFAULT_LIB")"
INSTALLED_LIB="$INSTALL_DIR/$BASENAME_LIB"

DEFAULT_SERVER="${SERVER_FILES[0]}"
BASENAME_SERVER="$(basename "$DEFAULT_SERVER")"
INSTALLED_SERVER="$INSTALL_DIR/$BASENAME_SERVER"

cat <<EOF

[SCUDA] Summary
  SCUDA source directory : $SCUDA_DIR
  Installed directory    : $INSTALL_DIR
  Client library         : $INSTALLED_LIB
  Server binary          : $INSTALLED_SERVER

Usage examples:

1) On GPU server machine (run SCUDA server):

   $ sudo "$INSTALLED_SERVER"
   # or, if you want a specific port:
   # SCUDA_PORT=14833 sudo "$INSTALLED_SERVER"

2) On client machine (where you run ComfyUI / your app):

   export SCUDA_SERVER="GPU_HOST_IP:14833"
   export LD_PRELOAD="$INSTALLED_LIB"

   # Test with PyTorch:
   python3 -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"

   # Or run ComfyUI:
   # cd /path/to/ComfyUI
   # SCUDA_SERVER="GPU_HOST_IP:14833" \\
   # LD_PRELOAD="$INSTALLED_LIB" \\
   # python3 main.py --listen 0.0.0.0:8188

EOF