# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Mcp.Server do
  @moduledoc """
  Mix task to run the MCP Blender bpy HTTP server.

  This task starts the MCP server that provides Blender 3D modeling
  capabilities via the Model Context Protocol over HTTP.

  ## Usage

      mix mcp.server

  The server will run on port 4000 (or PORT environment variable),
  providing MCP capabilities via HTTP endpoints.

  ## Endpoints

  - POST /mcp - MCP protocol endpoint
  - GET /health - Health check endpoint
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # Parse command line arguments
    {opts, _} = OptionParser.parse!(args, strict: [port: :integer])

    # Set port from command line or environment
    port = opts[:port] || System.get_env("PORT", "4000") |> String.to_integer()
    System.put_env("PORT", to_string(port))

    Mix.Task.run("app.start")

    # Start the MCP application
    Application.ensure_all_started(:bpy_mcp)

    IO.puts("🚀 bpy-mcp HTTP server started on port #{port}")
    IO.puts("📡 MCP endpoint: http://localhost:#{port}/mcp")
    IO.puts("💚 Health check: http://localhost:#{port}/health")

    # Keep the process running
    Process.sleep(:infinity)
  end
end
