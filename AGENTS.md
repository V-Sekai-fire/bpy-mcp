# Setting up bpy-mcp with AI Agents (VS Code & Cursor)

This guide shows you how to configure AI agents in VS Code and Cursor to use the bpy-mcp server for Blender 3D modeling operations.

## Prerequisites

1. **VS Code** or **Cursor IDE** installed and running
2. **Elixir and Mix** installed on your system
3. **bpy-mcp** project dependencies installed (`mix deps.get`)
4. MCP extension/feature enabled in your editor

## Configuration Methods

Both VS Code and Cursor support MCP servers through configuration files. The recommended method is stdio transport.

### Method 1: Stdio Transport (Recommended)

This is the standard MCP transport method that works with most MCP clients.

#### Step 1: Open MCP Settings

**For Cursor:**
1. Open Cursor IDE
2. Press `Shift + Command + P` (macOS) or `Shift + Ctrl + P` (Windows/Linux)
3. Type "Open MCP Settings" and select it
4. This opens the `mcp.json` configuration file

**For VS Code:**
1. Open VS Code
2. Install the MCP extension (if available) or use the built-in MCP support
3. Open Command Palette: `Shift + Command + P` (macOS) or `Shift + Ctrl + P` (Windows/Linux)
4. Type "Open MCP Settings" or navigate to MCP configuration
5. Edit the `mcp.json` configuration file

The configuration file is typically located at:
- **macOS/Linux**: `~/.config/mcp.json` or `~/.config/Code/User/mcp.json`
- **Windows**: `%APPDATA%\Code\User\mcp.json` or `%APPDATA%\mcp.json`

#### Step 2: Configure the Server

Add the following configuration to your `mcp.json` file:

```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "/path/to/bpy-mcp",
      "env": {
        "MIX_ENV": "dev"
      }
    }
  }
}
```

**Important:** 
- Update the `cwd` path to match your actual project directory path
- Use absolute paths (e.g., `/Users/username/Developer/bpy-mcp` on macOS/Linux or `C:\Users\username\Developer\bpy-mcp` on Windows)

#### Step 3: Save and Restart

1. Save the `mcp.json` file
2. Restart your editor (or reload the window)
3. The server should appear in the MCP settings and show as "Connected" or "Available"

### Method 2: HTTP Transport (Alternative)

If your editor supports HTTP-based MCP servers, you can use this configuration:

#### Step 1: Start the HTTP Server

First, start the MCP server in a terminal:

```bash
cd /path/to/bpy-mcp
mix mcp.server --port 4000
```

Keep this terminal running.

#### Step 2: Configure Your Editor

In your editor's `mcp.json`, add:

```json
{
  "mcpServers": {
    "bpy-mcp": {
      "url": "http://localhost:4000"
    }
  }
}
```

## Verifying the Connection

1. Open your editor's MCP settings
2. Check that "bpy-mcp" appears in the list of configured servers
3. The server should show as "Connected" or "Available"
4. You should see the tools listed:
   - `bpy_list_commands` - List available Blender commands
   - `bpy_execute_command` - Execute Blender commands

## Using the MCP Tools in Your Editor

Once configured, the MCP tools become available to AI agents in your editor.

### VS Code Usage

1. **Open the AI Chat Panel** (GitHub Copilot Chat, Cursor-like features, or MCP-enabled extensions)
2. **Start a conversation** with the AI agent
3. The MCP tools should be automatically available for the AI to use

### Cursor Usage

1. **Open the Chat/Agent Panel** in Cursor
2. **Ensure you're in Agent mode** (if applicable)
3. The MCP tools should be available for the AI to use

### Example Usage

You can now ask your AI agent to:

- **"Create a cube in Blender"**
- **"List all available Blender commands"**
- **"Create a sphere at position [2, 0, 0] with radius 1.5"**
- **"Get information about the current scene"**
- **"Create a cube named 'MyCube' at [1, 2, 3] with size 3.0"**
- **"Reset the Blender scene"**

The AI will automatically use the `bpy_execute_command` tool to execute these operations.

### Example Tool Execution

When you ask for something like "create a cube", the AI agent will use:

```json
{
  "name": "bpy_execute_command",
  "arguments": {
    "commands": [
      {
        "command": "create_cube",
        "args": {
          "name": "Cube",
          "location": [0, 0, 0],
          "size": 2.0
        }
      }
    ]
  }
}
```

## Troubleshooting

### Server Not Starting

If the stdio server doesn't start:

1. **Verify Elixir is installed**: `elixir --version`
2. **Verify Mix is available**: `mix --version`
3. **Check dependencies are installed**: 
   ```bash
   cd /path/to/bpy-mcp
   mix deps.get
   ```
4. **Try running manually**:
   ```bash
   cd /path/to/bpy-mcp
   mix mcp.stdio
   ```
   You should see server startup messages (or silence, which is normal for stdio mode)

### Server Not Appearing in Editor

1. **Check the `cwd` path** is correct in `mcp.json` (use absolute path)
2. **Verify the server starts** without errors when run manually
3. **Check editor's developer console** for errors:
   - VS Code: Help → Toggle Developer Tools
   - Cursor: Help → Toggle Developer Tools
4. **Ensure the project has been compiled**: `mix compile`
5. **Check file permissions** - ensure the editor can execute `mix`

### Tools Not Working

1. **Verify Blender is installed** (if using real Blender, not mock mode)
2. **Check Python and Pythonx are properly configured**
3. **Test the server manually** with curl:
   ```bash
   curl -X POST http://localhost:4000 \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}'
   ```
4. **Check for errors** in the server output when running manually
5. **Verify environment variables** are set correctly (see Advanced Configuration)

### Editor-Specific Issues

**VS Code:**
- Ensure you have the MCP extension installed and enabled
- Check VS Code's output panel for MCP-related messages
- Try reloading the window after configuration changes

**Cursor:**
- Cursor has built-in MCP support, but ensure you're using a compatible version
- Check Cursor's settings for MCP-related options
- Verify the MCP server shows as "active" in Cursor's MCP panel

## Advanced Configuration

### Custom Port

For HTTP transport, you can specify a custom port:

```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.server", "--port", "8080"],
      "cwd": "/path/to/bpy-mcp"
    }
  }
}
```

### Environment Variables

You can set environment variables for the server:

```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "/path/to/bpy-mcp",
      "env": {
        "MIX_ENV": "dev",
        "BLENDER_HEADLESS": "1",
        "PORT": "4000",
        "PYTHON_PATH": "/path/to/python"
      }
    }
  }
}
```

### Multiple MCP Servers

You can configure multiple MCP servers in the same configuration file:

```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "/path/to/bpy-mcp"
    },
    "other-mcp-server": {
      "command": "node",
      "args": ["/path/to/other-server.js"]
    }
  }
}
```

### Platform-Specific Paths

**macOS/Linux:**
```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "/Users/username/Developer/bpy-mcp"
    }
  }
}
```

**Windows:**
```json
{
  "mcpServers": {
    "bpy-mcp": {
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "C:\\Users\\username\\Developer\\bpy-mcp"
    }
  }
}
```

## Available Tools

The bpy-mcp server provides the following MCP tools:

### `bpy_list_commands`
Lists all available Blender commands with their schemas.

**Example usage:**
- "What Blender commands are available?"
- "List all bpy commands"

### `bpy_execute_command`
Executes one or more Blender commands with their arguments.

**Available commands:**
- `create_cube` - Create a cube object
  - Parameters: `name` (string), `location` (array), `size` (number)
- `create_sphere` - Create a sphere object
  - Parameters: `name` (string), `location` (array), `radius` (number)
- `get_scene_info` - Get information about the current scene
- `reset_scene` - Reset the scene to a clean state
- `export_bmesh` - Export scene as BMesh data
- `import_bmesh` - Import BMesh data from glTF JSON

**Example usage:**
- "Create a cube named 'Box' at position [1, 2, 3] with size 2.5"
- "Create a sphere with radius 1.5"
- "Get the current scene information"

## Testing the Configuration

After configuration, test the setup:

1. **Verify server appears** in your editor's MCP settings
2. **Check server status** - should show as "Connected" or "Active"
3. **Try a simple query**: "List available Blender commands"
4. **Test command execution**: "Create a test cube"

If these work, your configuration is successful!

## Next Steps

- Explore the available Blender commands via `bpy_list_commands`
- Try creating objects and scenes through your AI agent
- Check the main [README.md](./README.md) for more information about the server capabilities
- Experiment with different Blender operations through natural language

## Additional Resources

- **Main Documentation**: [README.md](./README.md)
- **MCP Protocol**: [Model Context Protocol Specification](https://modelcontextprotocol.io)
- **Blender Python API**: [Blender bpy Documentation](https://docs.blender.org/api/current/)

