# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BMesh do
  @moduledoc """
  Shared utilities for BMesh operations.
  """

  @doc """
  Ensure Pythonx is available for operations.
  Since bpy is always available via pythonx, this always returns :ok.
  """
  @spec ensure_pythonx() :: :ok
  def ensure_pythonx do
    Application.ensure_all_started(:pythonx)
    :ok
  end
end
