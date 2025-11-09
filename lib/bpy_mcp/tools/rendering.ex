# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Tools.Rendering do
  @moduledoc """
  Rendering tools for scenes.
  """

  alias BpyMcp.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Renders the current scene to an image file.
  """
  @spec render_image(String.t(), integer(), integer(), String.t()) :: result()
  def render_image(filepath, resolution_x \\ 1920, resolution_y \\ 1080, temp_dir) do
    :ok = Utils.ensure_pythonx()
    render_image_bpy(filepath, resolution_x, resolution_y, temp_dir)
  end

  defp render_image_bpy(filepath, resolution_x, resolution_y, _temp_dir) do
    try do
      code = """
      import bpy
      import os

      # Set render settings
      scene = bpy.context.scene
      scene.render.resolution_x = #{resolution_x}
      scene.render.resolution_y = #{resolution_y}
      scene.render.resolution_percentage = 100
      scene.render.image_settings.file_format = 'PNG'

      # Set output path
      scene.render.filepath = "#{filepath}"

      # Render
      bpy.ops.render.render(write_still=True)

      # Verify file was created
      if os.path.exists("#{filepath}"):
          result = f"Rendered image to {filepath} at {resolution_x}x{resolution_y}"
      else:
          result = f"Render completed but file not found at {filepath}"
      """

      result = Pythonx.eval(code, %{"working_directory" => _temp_dir})
      {:ok, result}
    rescue
      e ->
        {:error, "Failed to render image: #{inspect(e)}"}
    end
  end
end
