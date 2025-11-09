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
      # Start pythonx application
      Application.ensure_all_started(:pythonx)

      # Check if pythonx is already initialized (from config)
      # If not, it will be initialized when we try to use it
      # The application may have already initialized it via config
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
      # Wait a moment for pythonx to auto-initialize if configured
      Process.sleep(200)

      # Try to use pythonx - it will auto-initialize if configured
      # or raise an error if not initialized
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
      RuntimeError ->
        # Pythonx not initialized yet - wait longer and retry once
        Process.sleep(2000)

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

      _ ->
        false
    end
  end

  @doc """
  Setup callback that ensures bpy is available.
  Since bpy is always available via pythonx, we ensure pythonx is initialized.
  """
  def setup_require_bpy(_context) do
    # Ensure pythonx application is started
    Application.ensure_all_started(:pythonx)

    # Wait for pythonx to auto-initialize from config
    # Pythonx auto-initialization happens asynchronously, so we need to wait
    wait_for_pythonx_initialization()

    :ok
  end

  defp wait_for_pythonx_initialization do
    # Try to use pythonx - it will raise if not initialized
    # Retry with exponential backoff up to 5 seconds
    wait_for_pythonx_initialization(0, 10)
  end

  defp wait_for_pythonx_initialization(attempt, max_attempts) when attempt >= max_attempts do
    # Give up after max attempts
    Process.sleep(500)
  end

  defp wait_for_pythonx_initialization(attempt, max_attempts) do
    try do
      # Try a simple pythonx operation to see if it's initialized
      _ = Pythonx.eval("1 + 1", %{})
      # If we get here, pythonx is initialized
      :ok
    rescue
      RuntimeError ->
        # Not initialized yet, wait and retry
        Process.sleep(500)
        wait_for_pythonx_initialization(attempt + 1, max_attempts)

      _ ->
        Process.sleep(500)
        wait_for_pythonx_initialization(attempt + 1, max_attempts)
    end
  end
end

# Initialize pythonx with vendored bpy before tests
# Uses pythonx default initialization (no system Blender paths)
BpyMcp.TestHelper.init_pythonx_with_bpy()
