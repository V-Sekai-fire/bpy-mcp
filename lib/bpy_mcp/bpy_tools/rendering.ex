# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools.Rendering do
  @moduledoc """
  Rendering tools for Blender scenes.
  """

  alias BpyMcp.BpyTools.Utils

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Renders the current scene to an image file.
  """
  @spec render_image(String.t(), integer(), integer(), String.t()) :: bpy_result()
  def render_image(filepath, resolution_x \\ 1920, resolution_y \\ 1080, temp_dir) do
    case Utils.ensure_pythonx() do
      :ok ->
        do_render_image(filepath, resolution_x, resolution_y, temp_dir)

      :mock ->
        mock_render_image(filepath, resolution_x, resolution_y)
    end
  end

  defp mock_render_image(filepath, resolution_x, resolution_y) do
    {:ok, "Mock rendered image to #{filepath} at #{resolution_x}x#{resolution_y}"}
  end

  defp do_render_image(filepath, resolution_x, resolution_y, temp_dir) do
    # Ensure scene FPS is set to 30
    Utils.ensure_scene_fps()

    code = """
    import bpy

    # Set render settings
    bpy.context.scene.render.resolution_x = #{resolution_x}
    bpy.context.scene.render.resolution_y = #{resolution_y}
    bpy.context.scene.render.filepath = '#{filepath}'

    # Render
    bpy.ops.render.render(write_still=True)

    result = f"Rendered image to #{filepath} at #{resolution_x}x#{resolution_y}"
    result
    """

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode render_image result"}
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
  def test_mock_render_image(filepath, resolution_x, resolution_y),
    do: mock_render_image(filepath, resolution_x, resolution_y)
end

