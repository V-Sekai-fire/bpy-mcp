# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools.Scene do
  @moduledoc """
  Scene management tools for Blender (reset, get info, etc.)
  """

  alias BpyMcp.BpyTools.Utils

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Resets the Blender scene to a clean state by removing all objects.
  """
  @spec reset_scene(String.t()) :: bpy_result()
  def reset_scene(temp_dir) do
    case Utils.ensure_pythonx() do
      :ok ->
        do_reset_scene(temp_dir)

      :mock ->
        mock_reset_scene()
    end
  end

  defp mock_reset_scene do
    {:ok, "Mock reset scene - cleared all objects"}
  end

  defp do_reset_scene(temp_dir) do
    code = """
    import bpy

    # Ensure we have a scene
    if not bpy.context.scene:
        bpy.ops.scene.new(type='NEW')

    # Select all objects
    bpy.ops.object.select_all(action='SELECT')

    # Delete all selected objects
    bpy.ops.object.delete(use_global=False)

    result = "Reset scene - cleared all objects"
    result
    """

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode reset_scene result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  @doc """
  Gets information about the current Blender scene.
  """
  @spec get_scene_info(String.t()) :: bpy_result()
  def get_scene_info(temp_dir) do
    case Utils.ensure_pythonx() do
      :ok ->
        do_get_scene_info(temp_dir)

      :mock ->
        mock_get_scene_info()
    end
  end

  defp mock_get_scene_info do
    {:ok,
     %{
       "scene_name" => "Mock Scene",
       "frame_current" => 1,
       "frame_start" => 1,
       "frame_end" => 250,
       "fps" => 30,
       "fps_base" => 1,
       "objects" => ["Cube", "Light", "Camera"],
       "active_object" => "Cube"
     }}
  end

  defp do_get_scene_info(temp_dir) do
    # Ensure scene FPS is set to 30 before getting info
    Utils.ensure_scene_fps()

    code = """
    import bpy

    # Ensure we have a valid scene and context
    if not bpy.context.scene:
        bpy.ops.scene.new(type='NEW')

    scene = bpy.context.scene
    objects = [obj.name for obj in scene.objects]

    # Safely get active object
    try:
        active_object = bpy.context.active_object
        active_object_name = active_object.name if active_object else None
    except AttributeError:
        active_object_name = None

    result = {
        "scene_name": scene.name,
        "frame_current": scene.frame_current,
        "frame_start": scene.frame_start,
        "frame_end": scene.frame_end,
        "fps": scene.render.fps,
        "fps_base": scene.render.fps_base,
        "objects": objects,
        "active_object": active_object_name
    }
    result
    """

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_map(result) -> {:ok, result}
          _ -> {:error, "Failed to decode scene info"}
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
  def test_mock_get_scene_info(), do: mock_get_scene_info()
  @doc false
  def test_mock_reset_scene(), do: mock_reset_scene()
end

