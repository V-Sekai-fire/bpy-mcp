# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BMesh do
  @moduledoc """
  Shared utilities for BMesh operations.
  """

  @doc """
  Ensure Pythonx is available for operations.
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
