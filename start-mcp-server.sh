#!/bin/bash
# Auto-start script for bpy-mcp server via Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first." >&2
    exit 1
fi

# Check if container is already running
if docker ps --format '{{.Names}}' | grep -q "^bpy-mcp-server$"; then
    echo "bpy-mcp server is already running"
    docker ps --filter "name=bpy-mcp-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit 0
fi

# Use the existing devcontainer setup
echo "Starting bpy-mcp server via Docker..."
cd .devcontainer

# Build and start the container
docker compose up -d --build 2>&1 | grep -v "the attribute \`version\` is obsolete" || true

# Wait for container to be ready
echo "Waiting for container to start..."
sleep 5

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^bpy-mcp-server$"; then
    echo "Error: Container failed to start. Check logs with: docker compose logs" >&2
    cd ..
    exit 1
fi

cd ..

echo "✅ bpy-mcp server starting in Docker container"
echo "📡 Server will be available at: http://localhost:4000"
echo "📡 SSE endpoint: http://localhost:4000/sse"
echo "💚 Health check: http://localhost:4000/health"
echo ""
echo "To view logs: docker logs -f bpy-mcp-server"

