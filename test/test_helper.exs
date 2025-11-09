# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

ExUnit.start()

# Helper to check if bpy is available
defmodule BpyMcp.TestHelper do
  @moduledoc """
  Test helpers for bpy-mcp tests.
  """

  @doc """
  Checks if bpy is available via Pythonx.
  Returns true if bpy can be imported, false otherwise.
  """
  def bpy_available? do
    try do
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
  def setup_require_bpy(_context) do
    if bpy_available?() do
      :ok
    else
      raise "bpy is not available - this is a required dependency. Please ensure bpy is available via Pythonx."
    end
  end
end
