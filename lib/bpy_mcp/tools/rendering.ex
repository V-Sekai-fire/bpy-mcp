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
  Maximum resolution is limited to 512x512 pixels.
  """
  @spec render_image(String.t(), integer(), integer(), String.t()) :: result()
  def render_image(filepath, resolution_x \\ 1920, resolution_y \\ 1080, temp_dir) do
    :ok = Utils.ensure_pythonx()
    # Limit resolution to max 512x512
    resolution_x = min(resolution_x, 512)
    resolution_y = min(resolution_y, 512)
    render_image_bpy(filepath, resolution_x, resolution_y, temp_dir)
  end

  defp render_image_bpy(filepath, resolution_x, resolution_y, temp_dir) do
    try do
      code = """
      import bpy
      import os
      import base64

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

      # Read image data and encode as base64
      if os.path.exists("#{filepath}"):
          with open("#{filepath}", "rb") as f:
              image_data = f.read()
              image_base64 = base64.b64encode(image_data).decode('utf-8')
              result = {
                  "filepath": "#{filepath}",
                  "resolution": [#{resolution_x}, #{resolution_y}],
                  "format": "PNG",
                  "data": image_base64
              }
              import json
              json.dumps(result)
      else:
          result = {"error": f"Render completed but file not found at {filepath}"}
          import json
          json.dumps(result)
      """

      result_json = Pythonx.eval(code, %{"working_directory" => temp_dir})
      result = Jason.decode!(result_json)
      {:ok, result}
    rescue
      e ->
        {:error, "Failed to render image: #{inspect(e)}"}
    end
  end
end
