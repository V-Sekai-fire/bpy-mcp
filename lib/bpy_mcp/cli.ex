# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.CLI do
  @moduledoc """
  Command-line interface for the bpy MCP server.
  """

  def main(_args) do
    # Start the application
    {:ok, _} = Application.ensure_all_started(:bpy_mcp)

    # Keep the application running
    Process.sleep(:infinity)
  end
end
