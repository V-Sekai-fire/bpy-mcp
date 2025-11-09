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

  defp create_cube_bpy(name, location, size, temp_dir) do
    try do
      [x, y, z] = location

      code = """
      import bpy

      # Clear existing mesh if it exists
      if "#{name}" in bpy.data.objects:
          bpy.data.objects.remove(bpy.data.objects["#{name}"], do_unlink=True)

      # Create cube using bpy primitives
      bpy.ops.mesh.primitive_cube_add(size=#{size}, location=(#{x}, #{y}, #{z}))
      obj = bpy.context.active_object
      obj.name = "#{name}"

      result = f"Created cube '{name}' at [{x}, {y}, {z}] with size {size}"
      """

      result = Pythonx.eval(code, %{"working_directory" => temp_dir})
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

  defp create_sphere_bpy(name, location, radius, temp_dir) do
    try do
      [x, y, z] = location

      code = """
      import bpy

      # Clear existing mesh if it exists
      if "#{name}" in bpy.data.objects:
          bpy.data.objects.remove(bpy.data.objects["#{name}"], do_unlink=True)

      # Create sphere using bpy primitives
      bpy.ops.mesh.primitive_uv_sphere_add(radius=#{radius}, location=(#{x}, #{y}, #{z}))
      obj = bpy.context.active_object
      obj.name = "#{name}"

      result = f"Created sphere '{name}' at [{x}, {y}, {z}] with radius {radius}"
      """

      result = Pythonx.eval(code, %{"working_directory" => temp_dir})
      {:ok, result}
    rescue
      e ->
        {:error, "Failed to create sphere: #{inspect(e)}"}
    end
  end
end
