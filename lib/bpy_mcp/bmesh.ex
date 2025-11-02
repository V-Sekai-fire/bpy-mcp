# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BMesh do
  @moduledoc """
  Shared utilities for BMesh operations.
  """

  @doc """
  Ensure Pythonx is available for Blender operations.
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
