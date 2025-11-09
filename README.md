# BpyMcp

[![smithery badge](https://smithery.ai/badge/@V-Sekai-fire/bpy-mcp)](https://smithery.ai/server/@V-Sekai-fire/bpy-mcp)

A Model Context Protocol (MCP) server that provides Blender Python (bpy) tools for 3D modeling and rendering operations. This server allows MCP clients to interact with Blender through a standardized protocol, enabling programmatic control of 3D scenes, objects, materials, and rendering.

## Features

- **Object Creation**: Create cubes and spheres with customizable parameters
- **Material Management**: Apply materials with custom colors to objects
- **Scene Rendering**: Render scenes to image files with configurable resolution
- **Scene Information**: Query current scene details including objects and settings
- **Mock Mode**: Fallback functionality when Python/Blender is not available

## MCP Tools

- `bpy_create_cube`: Create a cube object in the Blender scene
- `bpy_create_sphere`: Create a sphere object in the Blender scene
- `bpy_set_material`: Apply a material to an existing object
- `bpy_render_image`: Render the current scene to an image file
- `bpy_get_scene_info`: Retrieve information about the current scene

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bpy_mcp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bpy_mcp, "~> 0.1.0"}
  ]
end
```

## Docker Setup

The project includes Docker support for both development and production environments.

### Prerequisites

- Docker and Docker Compose
- At least 4GB of available RAM for Blender operations

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd bpy-mcp

# Start development environment
./docker-run.sh dev

# Or start production environment
./docker-run.sh prod
```

### Development

```bash
# Start development server with hot reload
./docker-run.sh dev

# View logs
./docker-run.sh logs -f

# Open shell in container
./docker-run.sh shell

# Stop development server
./docker-run.sh stop
```

### Production

```bash
# Build and start production server
./docker-run.sh prod

# View production logs
./docker-run.sh logs

# Stop production server
docker-compose -f docker-compose.prod.yml down
```

### Manual Docker Commands

```bash
# Development
docker-compose up --build

# Production
docker-compose -f docker-compose.prod.yml up -d --build

# Clean up
docker-compose down -v
```

### Architecture

The Docker setup uses a multi-stage build:

- **Base**: Common dependencies (Erlang, Elixir, Blender)
- **Builder** (sidecar): Builds the Elixir release (discarded after build)
- **Runtime**: Minimal production image with only the release

This approach minimizes the final image size while ensuring reproducible builds.

## Development

This project includes a dev container configuration for a consistent development environment.

### Using Dev Containers

1. Ensure you have Docker and the Dev Containers extension for VS Code installed
2. Open the project in VS Code
3. When prompted, select "Reopen in Container" or use Command Palette: `Dev Containers: Reopen in Container`
4. The container will automatically set up the complete development environment

The dev container includes:

- Elixir 1.17.3 with OTP 26
- Pre-installed dependencies and Hex package manager
- VS Code extensions for Elixir development
- Proper Python environment with uv for Blender integration

### Manual Setup

If you prefer not to use dev containers, you can build and run the Docker container manually:

```bash
# Build the container
docker build --platform linux/amd64 -t bpy-mcp .

# Run with source mounting
docker run --rm -it --platform linux/amd64 -v $(pwd):/workspace -w /workspace bpy-mcp bash
```

Inside the container:

```bash
mix deps.get
mix compile

# Start HTTP server (recommended for testing)
mix mcp.server

# Or start with stdio transport (recommended for IDEs)
mix mcp.stdio
```

The HTTP server will be available at:

- MCP endpoint: `http://localhost:4000` (POST requests)
- Health check: `http://localhost:4000/.well-known/health` (via ex_mcp)

**Note:** For IDE integration (VS Code/Cursor), stdio transport (`mix mcp.stdio`) is recommended.

## Connecting with MCP Clients

### AI Agent Setup (VS Code & Cursor)

**Setup Guide**: See [AGENTS.md](./AGENTS.md) for detailed instructions on configuring VS Code and Cursor to use this MCP server.

**Quick Start:**
1. Open your editor → Command Palette (`Shift + Cmd/Ctrl + P`) → "Open MCP Settings"
2. Add to `mcp.json`:
```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "/path/to/bpy-mcp"
    }
  }
}
```
3. Save and restart your editor

See [AGENTS.md](./AGENTS.md) for detailed setup instructions.

### HTTP Transport

To connect with an MCP client using HTTP transport, configure the client with:

- **Server URL**: `http://localhost:4000`
- **Protocol**: MCP JSON-RPC 2.0

Example client configuration (for Claude Desktop or other MCP clients):

```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.server", "--transport", "http"],
      "env": {
        "PORT": "4000"
      }
    }
  }
}
```

### Stdio Transport

For stdio-based clients:

```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.stdio"]
    }
  }
}
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bpy_mcp>.