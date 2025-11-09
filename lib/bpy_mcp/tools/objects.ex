# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Tools.Objects do
  @moduledoc """
  Object creation tools for (cubes, spheres, etc.)
  """

  alias BpyMcp.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Creates a cube object in the scene.
  """
  @spec create_cube(String.t(), [number()], number(), String.t()) :: result()
  def create_cube(name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0, temp_dir) do
    :ok = Utils.ensure_pythonx()
    create_cube_bpy(name, location, size, temp_dir)
  end

  defp create_cube_bpy(name, location, size, _temp_dir) do
    try do
      [x, y, z] = location

      code = """
      import bpy
      import bmesh

      # Clear existing mesh if it exists
      if "#{name}" in bpy.data.objects:
          bpy.data.objects.remove(bpy.data.objects["#{name}"], do_unlink=True)

      # Create new mesh
      mesh = bpy.data.meshes.new(name="#{name}")
      obj = bpy.data.objects.new("#{name}", mesh)

      # Link to scene
      bpy.context.collection.objects.link(obj)

      # Create cube using bmesh
      bm = bmesh.new()
      bmesh.ops.create_cube(bm, size=#{size})
      bm.to_mesh(mesh)
      bm.free()

      # Set location
      obj.location = (#{x}, #{y}, #{z})

      # Make active
      bpy.context.view_layer.objects.active = obj
      obj.select_set(True)

      result = f"Created cube '{name}' at [{x}, {y}, {z}] with size {size}"
      """

      result = Pythonx.eval(code, %{"working_directory" => _temp_dir})
      {:ok, result}
    rescue
      e ->
        {:error, "Failed to create cube: #{inspect(e)}"}
    end
  end

  @doc """
  Creates a sphere object in the scene.
  """
  @spec create_sphere(String.t(), [number()], number(), String.t()) :: result()
  def create_sphere(name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0, temp_dir) do
    :ok = Utils.ensure_pythonx()
    create_sphere_bpy(name, location, radius, temp_dir)
  end

  defp create_sphere_bpy(name, location, radius, _temp_dir) do
    try do
      [x, y, z] = location

      code = """
      import bpy
      import bmesh

      # Clear existing mesh if it exists
      if "#{name}" in bpy.data.objects:
          bpy.data.objects.remove(bpy.data.objects["#{name}"], do_unlink=True)

      # Create new mesh
      mesh = bpy.data.meshes.new(name="#{name}")
      obj = bpy.data.objects.new("#{name}", mesh)

      # Link to scene
      bpy.context.collection.objects.link(obj)

      # Create sphere using bmesh
      bm = bmesh.new()
      bmesh.ops.create_icosphere(bm, subdivisions=2, radius=#{radius})
      bm.to_mesh(mesh)
      bm.free()

      # Set location
      obj.location = (#{x}, #{y}, #{z})

      # Make active
      bpy.context.view_layer.objects.active = obj
      obj.select_set(True)

      result = f"Created sphere '{name}' at [{x}, {y}, {z}] with radius {radius}"
      """

      result = Pythonx.eval(code, %{"working_directory" => _temp_dir})
      {:ok, result}
    rescue
      e ->
        {:error, "Failed to create sphere: #{inspect(e)}"}
    end
  end
end
