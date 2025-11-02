# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService do
  @moduledoc """
  Native BEAM service for Blender bpy MCP using ex_mcp library.
  Provides 3D modeling and rendering tools via MCP protocol.
  """

  # Suppress warnings from ex_mcp DSL generated code
  @compile {:no_warn_undefined, :no_warn_pattern}

  use ExMCP.Server,
    name: "Blender bpy MCP Server",
    version: "0.1.0"

  # Define bpy tools using ex_mcp DSL
  deftool "bpy_create_cube" do
    meta do
      name("Create Cube")
      description("Create a cube object in the Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{
        name: %{
          type: "string",
          description: "Name for the cube object",
          default: "Cube"
        },
        location: %{
          type: "array",
          items: %{type: "number"},
          description: "Location as [x, y, z] coordinates",
          default: [0, 0, 0]
        },
        size: %{
          type: "number",
          description: "Size of the cube",
          default: 2.0
        }
      }
    })
  end

  deftool "bpy_create_sphere" do
    meta do
      name("Create Sphere")
      description("Create a sphere object in the Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{
        name: %{
          type: "string",
          description: "Name for the sphere object",
          default: "Sphere"
        },
        location: %{
          type: "array",
          items: %{type: "number"},
          description: "Location as [x, y, z] coordinates",
          default: [0, 0, 0]
        },
        radius: %{
          type: "number",
          description: "Radius of the sphere",
          default: 1.0
        }
      }
    })
  end

  deftool "bpy_set_material" do
    meta do
      name("Set Material")
      description("Set a material on an object")
    end

    input_schema(%{
      type: "object",
      properties: %{
        object_name: %{
          type: "string",
          description: "Name of the object to apply material to"
        },
        material_name: %{
          type: "string",
          description: "Name of the material",
          default: "Material"
        },
        color: %{
          type: "array",
          items: %{type: "number"},
          description: "RGBA color as [r, g, b, a]",
          default: [0.8, 0.8, 0.8, 1.0]
        }
      },
      required: ["object_name"]
    })
  end

  deftool "bpy_render_image" do
    meta do
      name("Render Image")
      description("Render the current scene to an image file")
    end

    input_schema(%{
      type: "object",
      properties: %{
        filepath: %{
          type: "string",
          description: "Output file path for the rendered image"
        },
        resolution_x: %{
          type: "integer",
          description: "Render resolution width",
          default: 1920
        },
        resolution_y: %{
          type: "integer",
          description: "Render resolution height",
          default: 1080
        }
      },
      required: ["filepath"]
    })
  end

  deftool "bpy_get_scene_info" do
    meta do
      name("Get Scene Info")
      description("Get information about the current Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{}
    })
  end

  # Tool call handlers
  @impl true
  def handle_tool_call("bpy_create_cube", %{"name" => name, "location" => location, "size" => size}, state) do
    case BpyMcp.BpyTools.create_cube(name, location, size) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}

      {:error, reason} ->
        {:error, "Failed to create cube: #{reason}", state}
    end
  end

  @impl true
  def handle_tool_call("bpy_create_cube", args, state) do
    # Handle cases with missing parameters using defaults
    name = Map.get(args, "name", "Cube")
    location = Map.get(args, "location", [0, 0, 0])
    size = Map.get(args, "size", 2.0)

    case BpyMcp.BpyTools.create_cube(name, location, size) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}

      {:error, reason} ->
        {:error, "Failed to create cube: #{reason}", state}
    end
  end

  @impl true
  def handle_tool_call("bpy_create_sphere", %{"name" => name, "location" => location, "radius" => radius}, state) do
    case BpyMcp.BpyTools.create_sphere(name, location, radius) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}

      {:error, reason} ->
        {:error, "Failed to create sphere: #{reason}", state}
    end
  end

  @impl true
  def handle_tool_call("bpy_create_sphere", args, state) do
    # Handle cases with missing parameters using defaults
    name = Map.get(args, "name", "Sphere")
    location = Map.get(args, "location", [0, 0, 0])
    radius = Map.get(args, "radius", 1.0)

    case BpyMcp.BpyTools.create_sphere(name, location, radius) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}

      {:error, reason} ->
        {:error, "Failed to create sphere: #{reason}", state}
    end
  end

  @impl true
  def handle_tool_call("bpy_set_material", %{"object_name" => object_name} = args, state) do
    material_name = Map.get(args, "material_name", "Material")
    color = Map.get(args, "color", [0.8, 0.8, 0.8, 1.0])

    case BpyMcp.BpyTools.set_material(object_name, material_name, color) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}

      {:error, reason} ->
        {:error, "Failed to set material: #{reason}", state}
    end
  end

  @impl true
  def handle_tool_call("bpy_render_image", %{"filepath" => filepath} = args, state) do
    resolution_x = Map.get(args, "resolution_x", 1920)
    resolution_y = Map.get(args, "resolution_y", 1080)

    case BpyMcp.BpyTools.render_image(filepath, resolution_x, resolution_y) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}

      {:error, reason} ->
        {:error, "Failed to render image: #{reason}", state}
    end
  end

  @impl true
  def handle_tool_call("bpy_get_scene_info", _args, state) do
    case BpyMcp.BpyTools.get_scene_info() do
      {:ok, info} ->
        {:ok, %{content: [text("Scene info: #{inspect(info)}")]}, state}

      {:error, reason} ->
        {:error, "Failed to get scene info: #{reason}", state}
    end
  end

  # Fallback for unknown tools
  @impl true
  def handle_tool_call(tool_name, _args, state) do
    {:error, "Tool not found: #{tool_name}", state}
  end
end
