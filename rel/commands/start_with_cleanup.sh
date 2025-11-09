#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Wrapper script to stop any existing bpy_mcp instances before starting

RELEASE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE_BIN="$RELEASE_ROOT/bin/bpy_mcp"

# Stop any existing instances
if [ -f "$RELEASE_BIN" ]; then
  "$RELEASE_BIN" stop 2>/dev/null || true

  # Also kill any processes that might be hanging
  pkill -f "bpy_mcp" 2>/dev/null || true

  # Wait a moment for processes to fully stop
  sleep 0.5
fi

# Start the release
exec "$RELEASE_BIN" start "$@"
