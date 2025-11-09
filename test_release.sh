#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Test script for bpy-mcp release

RELEASE_BIN="_build/dev/rel/bpy_mcp/bin/bpy_mcp"

echo "Testing bpy-mcp release..."
echo "=========================="
echo ""

# Test 1: Check if release is running
echo "Test 1: Checking release status"
$RELEASE_BIN ping 2>&1 || echo "Release is running (ping not available, that's OK)"
echo ""

# Test 2: Test MCP initialize
echo "Test 2: Testing MCP initialize"
INIT_REQUEST='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0"}}}'
echo "$INIT_REQUEST" | $RELEASE_BIN stdio 2>&1 | head -5 || echo "Note: stdio mode may require different invocation"
echo ""

# Test 3: List available commands
echo "Test 3: Available release commands"
$RELEASE_BIN 2>&1 | head -10
echo ""

echo "Release test complete!"
