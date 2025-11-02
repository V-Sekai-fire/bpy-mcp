# BpyMcp

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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bpy_mcp>.
