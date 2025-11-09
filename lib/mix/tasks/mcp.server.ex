# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Mcp.Server do
  @moduledoc """
  Mix task to run the MCP bpy HTTP server with SSE streaming.

  This task starts the MCP server that provides 3D modeling
  capabilities via the Model Context Protocol over HTTP with
  Server-Sent Events (SSE) for real-time streaming.

  ## MCP Compliance

  The server uses ExMCP.HttpPlug which is MCP spec compliant:
  - Only sends "message" events for actual MCP protocol messages
  - No extra events like "connect", "ping", or "endpoint"
  - Session ID provided via HTTP headers (mcp-session-id)
  - No heartbeats or keep-alive events

  ## Usage

      mix mcp.server

  The server will run on port 4000 (or PORT environment variable),
  providing MCP capabilities via HTTP endpoints with SSE streaming.

  ## Endpoints

  - POST /mcp - MCP protocol endpoint
  - GET /sse - SSE endpoint for streaming responses (MCP compliant)
  - GET /health - Health check endpoint
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # Parse command line arguments
    {opts, _} = OptionParser.parse!(args, strict: [port: :integer, transport: :string])

    # Determine transport type
    transport =
      case Keyword.get(opts, :transport) || System.get_env("MCP_TRANSPORT", "http") do
        "stdio" -> :stdio
        _ -> :http
      end

    # Set port from command line or environment (for HTTP transport)
    port = opts[:port] || System.get_env("PORT", "4000") |> String.to_integer()
    System.put_env("PORT", to_string(port))
    System.put_env("MCP_TRANSPORT", to_string(transport))

    Mix.Task.run("app.start")

    # Start the MCP application
    Application.ensure_all_started(:bpy_mcp)

    case transport do
      :stdio ->
        IO.puts(:stderr, "🚀 bpy-mcp stdio server started")
        IO.puts(:stderr, "📡 Ready to accept MCP protocol messages via stdin/stdout")

      :http ->
        IO.puts("🚀 bpy-mcp HTTP server started on port #{port} (with SSE streaming)")
        IO.puts("📡 MCP endpoint: http://localhost:#{port}")
        IO.puts("📡 SSE endpoint: http://localhost:#{port}/sse (for streaming)")
        IO.puts("💚 Health check: http://localhost:#{port}/health")
    end

    # Keep the process running
    Process.sleep(:infinity)
  end
end
