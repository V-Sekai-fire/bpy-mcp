# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools.Utils do
  @moduledoc """
  Utility functions for bpy tools - Pythonx availability checking and scene setup.
  """

  require Logger

  @doc """
  Ensures Pythonx is available for Blender operations.
  Returns :ok if available, :mock if not.
  """
  @spec ensure_pythonx() :: :ok | :mock
  def ensure_pythonx do
    # Force mock mode during testing to avoid Blender initialization
    if Application.get_env(:bpy_mcp, :force_mock, false) or System.get_env("MIX_ENV") == "test" do
      :mock
    else
      case Application.ensure_all_started(:pythonx) do
        {:error, _reason} ->
          :mock

        {:ok, _} ->
          check_pythonx_availability()
      end
    end
  rescue
    _ -> :mock
  end

  @doc """
  Ensures the Blender scene is set to 30 FPS for animations.
  Only executes when Pythonx/Blender is available and not in test mode.
  """
  @spec ensure_scene_fps() :: :ok
  def ensure_scene_fps do
    # In test mode, never execute Python code
    if Mix.env() == :test do
      :ok
    else
      # Only try to set FPS if Pythonx is actually available
      case check_pythonx_availability() do
        :ok ->
          code = """
          import bpy

          # Set scene FPS to 30
          bpy.context.scene.render.fps = 30
          bpy.context.scene.render.fps_base = 1
          """

          case Pythonx.eval(code, %{}) do
            {_result, _globals} -> :ok
            # Continue even if setting FPS fails
            _ -> :ok
          end

        :mock ->
          # In mock mode, just return ok
          :ok
      end
    end
  rescue
    # Continue even if Pythonx fails
    _ -> :ok
  end

  defp check_pythonx_availability do
    # In test mode, never try to execute Python code
    if Mix.env() == :test do
      :mock
    else
      # Test if both Pythonx works and bpy is available
      # Redirect stderr to prevent EGL errors from corrupting stdio
      try do
        code = """
        import bpy
        result = bpy.context.scene is not None
        result
        """

        # Use /dev/null to suppress Blender's output from corrupting stdio
        null_device = File.open!("/dev/null", [:write])

        case Pythonx.eval(code, %{}, stdout_device: null_device, stderr_device: null_device) do
          {result, _globals} ->
            case Pythonx.decode(result) do
              true -> :ok
              _ -> :mock
            end

          _ ->
            :mock
        end
      rescue
        _ -> :mock
      end
    end
  end
end

