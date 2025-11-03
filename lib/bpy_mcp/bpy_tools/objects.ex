# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools.Objects do
  @moduledoc """
  Object creation tools for Blender (cubes, spheres, etc.)
  """

  alias BpyMcp.BpyTools.Utils

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Creates a cube object in the Blender scene.
  """
  @spec create_cube(String.t(), [number()], number(), String.t()) :: bpy_result()
  def create_cube(name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0, temp_dir) do
    case Utils.ensure_pythonx() do
      :ok ->
        do_create_cube(name, location, size, temp_dir)

      :mock ->
        mock_create_cube(name, location, size)
    end
  end

  defp mock_create_cube(name, location, size) do
    {:ok, "Mock created cube '#{name}' at #{inspect(location)} with size #{size}"}
  end

  defp do_create_cube(name, location, size, temp_dir) do
    # Ensure scene FPS is set to 30
    Utils.ensure_scene_fps()

    # Format location as Python tuple
    location_str = location |> Enum.map(&to_string/1) |> Enum.join(", ")
    
    # Escape single quotes in name for Python string
    escaped_name = name |> String.replace("'", "\\'") |> String.replace("\\", "\\\\")

    code = """
    import bpy

    # Ensure we have a scene
    if not bpy.context.scene:
        bpy.ops.scene.new(type='NEW')

    # Create cube
    bpy.ops.mesh.primitive_cube_add(size=#{size}, location=(#{location_str}))

    # Safely get the active object
    try:
        cube = bpy.context.active_object
        if cube:
            cube.name = '#{escaped_name}'
            result = f"Created cube '{cube.name}' at {list(cube.location)} with size #{size}"
        else:
            result = f"Failed to create cube - no active object after creation"
    except AttributeError:
        result = f"Failed to create cube - context error accessing active object"
    result
    """

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode create_cube result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  @doc """
  Creates a sphere object in the Blender scene.
  """
  @spec create_sphere(String.t(), [number()], number(), String.t()) :: bpy_result()
  def create_sphere(name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0, temp_dir) do
    case Utils.ensure_pythonx() do
      :ok ->
        do_create_sphere(name, location, radius, temp_dir)

      :mock ->
        mock_create_sphere(name, location, radius)
    end
  end

  defp mock_create_sphere(name, location, radius) do
    {:ok, "Mock created sphere '#{name}' at #{inspect(location)} with radius #{radius}"}
  end

  defp do_create_sphere(name, location, radius, temp_dir) do
    # Ensure scene FPS is set to 30
    Utils.ensure_scene_fps()

    # Format location as Python tuple
    location_str = location |> Enum.map(&to_string/1) |> Enum.join(", ")
    
    # Escape single quotes in name for Python string
    escaped_name = name |> String.replace("'", "\\'") |> String.replace("\\", "\\\\")

    code = """
    import bpy

    # Ensure we have a scene
    if not bpy.context.scene:
        bpy.ops.scene.new(type='NEW')

    # Ensure we're in OBJECT mode
    if bpy.context.active_object and bpy.context.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')

    # Create sphere
    bpy.ops.mesh.primitive_uv_sphere_add(radius=#{radius}, location=(#{location_str}))

    # Safely get the active object
    try:
        sphere = bpy.context.active_object
        if sphere:
            sphere.name = '#{escaped_name}'
            result = f"Created sphere '{sphere.name}' at {list(sphere.location)} with radius #{radius}"
        else:
            result = f"Failed to create sphere - no active object after creation"
    except AttributeError as e:
        result = f"Failed to create sphere - context error accessing active object: {str(e)}"
    result
    """

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode create_sphere result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  # Test helper functions
  @doc false
  def test_mock_create_cube(name, location, size), do: mock_create_cube(name, location, size)
  @doc false
  def test_mock_create_sphere(name, location, radius), do: mock_create_sphere(name, location, radius)
end

