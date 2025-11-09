# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Tools.Utils do
  @moduledoc """
  Utility functions for bpy tools - Pythonx availability checking and scene setup.
  """

  require Logger

  @doc """
  Ensures Pythonx is available for operations.
  Returns :ok if available, :mock if not.
  """
  @spec ensure_pythonx() :: :ok | :mock
  def ensure_pythonx do
    case Application.ensure_all_started(:pythonx) do
      {:error, _reason} ->
        :mock

      {:ok, _} ->
        check_pythonx_availability()
    end
  rescue
    _ -> :mock
  end

  @doc """
  Ensures the scene is set to 30 FPS for animations.
  Only executes when Pythonx is available and not in test mode.
  """
  @spec ensure_scene_fps() :: :ok
  def ensure_scene_fps do
    :ok = ensure_pythonx()

    try do
      code = """
      import bpy
      bpy.context.scene.render.fps = 30
      bpy.context.scene.render.fps_base = 1.0
      """

      Pythonx.exec(code)
      :ok
    rescue
      _ -> :ok
    end
  end

  defp check_pythonx_availability do
    try do
      # Check if bpy is available by trying to import it
      code = """
      try:
          import bpy
          result = True
      except ImportError:
          result = False
      """

      case Pythonx.eval(code, %{}) do
        true -> :ok
        _ -> :mock
      end
    rescue
      _ -> :mock
    end
  end
end
