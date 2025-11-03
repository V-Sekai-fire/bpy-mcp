# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Mcp.Stdio do
  @moduledoc """
  Mix task to run the MCP Blender bpy stdio server.

  This task starts the MCP server that provides Blender 3D modeling
  capabilities via the Model Context Protocol over stdin/stdout.

  ## Usage

      mix mcp.stdio

  The server will communicate via standard input/output, making it suitable
  for MCP clients that use stdio transport.

  ## Configuration

  For stdio mode, logging is automatically suppressed to stdout to prevent
  contamination of the JSON-RPC protocol stream.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    # Configure for STDIO mode before starting
    System.put_env("MCP_TRANSPORT", "stdio")
    
    # Suppress logging to stdout for stdio transport
    Logger.configure(level: :emergency)
    Application.put_env(:ex_mcp, :stdio_mode, true)
    Application.put_env(:ex_mcp, :stdio_startup_delay, 10)

    Mix.Task.run("app.start")

    # Start the MCP application
    Application.ensure_all_started(:bpy_mcp)

    # Output to stderr to avoid contaminating stdout JSON stream
    IO.puts(:stderr, "🚀 bpy-mcp stdio server started")
    IO.puts(:stderr, "📡 Ready to accept MCP protocol messages via stdin/stdout")

    # Keep the process running
    Process.sleep(:infinity)
  end
end

