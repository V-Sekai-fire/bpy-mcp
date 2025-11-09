# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Tools do
  @moduledoc """
  tools exposed via MCP using Pythonx for 3D operations.

  This module provides a unified interface for all scene operations, delegating
  to specialized submodules:
  - `BpyMcp.Tools.Objects` - Object creation (cubes, spheres)
  - `BpyMcp.Tools.Materials` - Material operations
  - `BpyMcp.Tools.Rendering` - Rendering operations
  - `BpyMcp.Tools.Scene` - Scene management
  - `BpyMcp.Tools.Introspection` - API introspection tools
  - `BpyMcp.Tools.Utils` - Shared utilities
  """

  alias BpyMcp.Tools.{Objects, Materials, Rendering, Scene, Introspection}

  @type result :: {:ok, term()} | {:error, String.t()}

  # Object creation functions
  @doc """
  Creates a cube object in the scene.
  """
  @spec create_cube(String.t(), [number()], number(), String.t()) :: result()
  defdelegate create_cube(name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0, temp_dir),
    to: Objects

  @doc """
  Creates a sphere object in the scene.
  """
  @spec create_sphere(String.t(), [number()], number(), String.t()) :: result()
  defdelegate create_sphere(name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0, temp_dir),
    to: Objects

  # Material functions
  @doc """
  Sets a material on an object.
  """
  @spec set_material(String.t(), String.t(), [number()], String.t()) :: result()
  defdelegate set_material(
                object_name,
                material_name \\ "Material",
                color \\ [0.8, 0.8, 0.8, 1.0],
                temp_dir
              ),
              to: Materials

  # Rendering functions
  @doc """
  Renders the current scene to an image file.
  """
  @spec render_image(String.t(), integer(), integer(), String.t()) :: result()
  defdelegate render_image(
                filepath,
                resolution_x \\ 1920,
                resolution_y \\ 1080,
                temp_dir
              ),
              to: Rendering

  # Scene management functions
  @doc """
  Resets the scene to a clean state by removing all objects.
  """
  @spec reset_scene(String.t()) :: result()
  defdelegate reset_scene(temp_dir), to: Scene

  @doc """
  Gets information about the current scene.
  """
  @spec get_scene_info(String.t()) :: result()
  defdelegate get_scene_info(temp_dir), to: Scene

  # Introspection functions
  @doc """
  Introspects bpy/bmesh structure for debugging and understanding API.
  """
  @spec introspect_blender(String.t(), String.t()) :: result()
  defdelegate introspect_blender(object_path \\ "bmesh", temp_dir), to: Introspection

  @doc """
  Introspects any Python object/API structure for debugging and understanding Python APIs.
  """
  @spec introspect_python(String.t(), String.t() | nil, String.t()) :: result()
  defdelegate introspect_python(object_path, prep_code \\ nil, temp_dir), to: Introspection
end
