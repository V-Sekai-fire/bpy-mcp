# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Tools.Utils do
  @moduledoc """
  Utility functions for bpy tools - Pythonx availability checking and scene setup.
  """

  require Logger

  @doc """
  Ensures Pythonx is available for operations.
  Since bpy is always available via pythonx, this always returns :ok.
  """
  @spec ensure_pythonx() :: :ok
  def ensure_pythonx do
    Application.ensure_all_started(:pythonx)
    :ok
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

      _ = Pythonx.eval(code, %{})
      :ok
    rescue
      _ -> :ok
    end
  end
end
