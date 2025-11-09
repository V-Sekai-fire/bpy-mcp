# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Tools.Materials do
  @moduledoc """
  Material manipulation tools for objects.
  """

  alias BpyMcp.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Sets a material on an object.
  """
  @spec set_material(String.t(), String.t(), [number()], String.t()) :: result()
  def set_material(object_name, material_name \\ "Material", color \\ [0.8, 0.8, 0.8, 1.0], temp_dir) do
    :ok = Utils.ensure_pythonx()
    set_material_bpy(object_name, material_name, color, temp_dir)
  end

  defp set_material_bpy(object_name, material_name, color, temp_dir) do
    try do
      [r, g, b, a] = color

      code = """
      import bpy

      # Get the object
      if "#{object_name}" not in bpy.data.objects:
          raise ValueError(f"Object '{object_name}' not found")

      obj = bpy.data.objects["#{object_name}"]

      # Remove existing material if it exists
      if "#{material_name}" in bpy.data.materials:
          mat = bpy.data.materials["#{material_name}"]
      else:
          # Create new material
          mat = bpy.data.materials.new(name="#{material_name}")
          mat.use_nodes = True

      # Set up Principled BSDF
      if mat.node_tree:
          bsdf = mat.node_tree.nodes.get("Principled BSDF")
          if bsdf:
              bsdf.inputs["Base Color"].default_value = (#{r}, #{g}, #{b}, #{a})
              bsdf.inputs["Alpha"].default_value = #{a}

      # Assign material to object
      if len(obj.data.materials) == 0:
          obj.data.materials.append(mat)
      else:
          obj.data.materials[0] = mat

      result = f"Set material '{material_name}' with color [{r}, {g}, {b}, {a}] on object '{object_name}'"
      """

      result = Pythonx.eval(code, %{"working_directory" => temp_dir})
      {:ok, result}
    rescue
      e ->
        {:error, "Failed to set material: #{inspect(e)}"}
    end
  end
end
