# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

ExUnit.start()

# Helper to check if bpy is available
defmodule BpyMcp.TestHelper do
  @moduledoc """
  Test helpers for bpy-mcp tests.
  """

  @doc """
  Initializes pythonx with vendored bpy.
  Uses pythonx default initialization (no system Blender paths).
  """
  def init_pythonx_with_bpy do
    try do
      # Use default pythonx initialization (no system Blender paths)
      Application.ensure_all_started(:pythonx)
      :ok
    rescue
      e ->
        IO.warn("Failed to initialize pythonx with bpy: #{inspect(e)}")
        :error
    end
  end

  @doc """
  Checks if bpy is available via Pythonx.
  Since bpy is vendored, it should always be available once pythonx is started.
  Returns true if bpy can be imported, false otherwise.
  """
  def bpy_available? do
    try do
      # Ensure pythonx is initialized with bpy
      init_pythonx_with_bpy()

      case Application.ensure_all_started(:pythonx) do
        {:error, _reason} ->
          false

        {:ok, _} ->
          check_bpy_availability()
      end
    rescue
      _ -> false
    end
  end

  defp check_bpy_availability do
    try do
      code = """
      try:
          import bpy
          result = True
      except ImportError:
          result = False
      """

      case Pythonx.eval(code, %{}) do
        true -> true
        _ -> false
      end
    rescue
      _ -> false
    end
  end

  @doc """
  Setup callback that fails if bpy is not available.
  Use this in test modules that require bpy.
  Since bpy is a required dependency, tests will fail if it's not available.
  """
  def setup_require_bpy(context) do
    if bpy_available?() do
      :ok
    else
      raise "bpy is not available - this is a required dependency. Since bpy is vendored via pythonx, this indicates a configuration issue."
    end
  end
end

# Initialize pythonx with vendored bpy before tests
# Uses pythonx default initialization (no system Blender paths)
BpyMcp.TestHelper.init_pythonx_with_bpy()
