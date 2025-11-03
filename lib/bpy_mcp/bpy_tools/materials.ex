# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools.Materials do
  @moduledoc """
  Material manipulation tools for Blender objects.
  """

  alias BpyMcp.BpyTools.Utils

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Sets a material on an object.
  """
  @spec set_material(String.t(), String.t(), [number()], String.t()) :: bpy_result()
  def set_material(object_name, material_name \\ "Material", color \\ [0.8, 0.8, 0.8, 1.0], temp_dir) do
    case Utils.ensure_pythonx() do
      :ok ->
        do_set_material(object_name, material_name, color, temp_dir)

      :mock ->
        mock_set_material(object_name, material_name, color)
    end
  end

  defp mock_set_material(object_name, material_name, color) do
    {:ok, "Mock set material '#{material_name}' with color #{inspect(color)} on object '#{object_name}'"}
  end

  defp do_set_material(object_name, material_name, color, temp_dir) do
    # Escape single quotes in names for Python strings
    escaped_object_name = object_name |> String.replace("'", "\\'") |> String.replace("\\", "\\\\")
    escaped_material_name = material_name |> String.replace("'", "\\'") |> String.replace("\\", "\\\\")
    
    code = """
    import bpy

    # Find object
    obj = bpy.data.objects.get('#{escaped_object_name}')
    if not obj:
        result = f"Object '#{escaped_object_name}' not found"
    else:
        # Create or get material
        mat = bpy.data.materials.get('#{escaped_material_name}')
        if not mat:
            mat = bpy.data.materials.new('#{escaped_material_name}')
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes["Principled BSDF"]
            bsdf.inputs["Base Color"].default_value = #{inspect(color)}

        # Assign material
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)

        result = f"Set material '{mat.name}' on object '{obj.name}'"
    result
    """

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode set_material result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  # Test helper function
  @doc false
  def test_mock_set_material(object_name, material_name, color),
    do: mock_set_material(object_name, material_name, color)
end

