# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Tools.Scene do
  @moduledoc """
  Scene management tools for (reset, get info, etc.)
  """

  alias BpyMcp.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Resets the scene to a clean state by removing all objects.
  """
  @spec reset_scene(String.t()) :: result()
  def reset_scene(temp_dir) do
    :ok = Utils.ensure_pythonx()
    reset_scene_bpy(temp_dir)
  end

  defp reset_scene_bpy(_temp_dir) do
    try do
      code = """
      import bpy

      # Select all objects
      bpy.ops.object.select_all(action='SELECT')

      # Delete all selected objects
      bpy.ops.object.delete(use_global=False)

      result = "Reset scene - cleared all objects"
      """

      result = Pythonx.eval(code, %{})
      {:ok, result}
    rescue
      e ->
        {:error, "Failed to reset scene: #{inspect(e)}"}
    end
  end

  @doc """
  Gets information about the current scene.
  """
  @spec get_scene_info(String.t()) :: result()
  def get_scene_info(temp_dir) do
    :ok = Utils.ensure_pythonx()
    get_scene_info_bpy(temp_dir)
  end

  defp get_scene_info_bpy(_temp_dir) do
    try do
      code = """
      import bpy
      import json

      scene = bpy.context.scene
      objects = [obj.name for obj in scene.objects]
      active_obj = scene.objects.active.name if scene.objects.active else None

      info = {
          "scene_name": scene.name,
          "frame_current": scene.frame_current,
          "frame_start": scene.frame_start,
          "frame_end": scene.frame_end,
          "fps": scene.render.fps,
          "fps_base": scene.render.fps_base,
          "objects": objects,
          "active_object": active_obj
      }

      result = json.dumps(info)
      """

      result_json = Pythonx.eval(code, %{})
      {:ok, Jason.decode!(result_json)}
    rescue
      e ->
        {:error, "Failed to get scene info: #{inspect(e)}"}
    end
  end
end
