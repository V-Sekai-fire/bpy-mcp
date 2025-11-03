#!/bin/bash
# Wrapper script for Cursor MCP that stops any existing instances before starting

RELEASE_BIN="/Users/ernest.lee/Developer/bpy-mcp/_build/prod/rel/bpy_mcp/bin/bpy_mcp"

# Stop any existing instances
if [ -f "$RELEASE_BIN" ]; then
  # Try graceful stop first
  "$RELEASE_BIN" stop 2>/dev/null || true
  
  # Also kill any processes that might be hanging
  pkill -f "bpy_mcp.*start" 2>/dev/null || true
  pkill -f "beam.*bpy_mcp" 2>/dev/null || true
  
  # Wait a moment for processes to fully stop
  sleep 0.3
fi

# Start the release
exec "$RELEASE_BIN" start "$@"

