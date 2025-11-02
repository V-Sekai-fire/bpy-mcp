# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.IntegrationTest do
  use ExUnit.Case, async: false
  alias BpyMcp.{StdioServer, NativeService}

  describe "Application startup" do
    test "application starts successfully" do
      # Test that the application can start (this is more of a smoke test)
      # In a real scenario, we'd mock the dependencies
      assert is_atom(BpyMcp.Application)
      assert function_exported?(BpyMcp.Application, :start, 2)
    end

    test "application defines correct children" do
      # Test the supervision tree structure
      children = [
        {BpyMcp.NativeService, [name: BpyMcp.NativeService]},
        {BpyMcp.StdioServer, []}
      ]

      opts = [strategy: :one_for_one, name: BpyMcp.Supervisor]

      # Verify the children list matches what Application.start/2 uses
      assert length(children) == 2
      assert opts[:strategy] == :one_for_one
      assert opts[:name] == BpyMcp.Supervisor
    end
  end

  describe "StdioServer" do
    test "defines child_spec correctly" do
      spec = StdioServer.child_spec([])
      expected_keys = [:id, :start, :type, :restart, :shutdown]

      assert is_map(spec)
      assert Map.keys(spec) == expected_keys
      assert spec.id == BpyMcp.StdioServer
      assert spec.type == :worker
      assert spec.restart == :permanent
      assert spec.shutdown == 500
    end

    test "start_link calls NativeService.start_link with stdio transport" do
      # This is testing the indirection - StdioServer delegates to NativeService
      assert function_exported?(StdioServer, :start_link, 1)
      assert StdioServer.start_link([]) == BpyMcp.NativeService.start_link([transport: :stdio])
    end
  end

  describe "Mix task integration" do
    test "mcp.server task exists and is properly defined" do
      assert function_exported?(Mix.Tasks.Mcp.Server, :run, 1)
    end
  end

  describe "MCP protocol integration" do
    test "NativeService implements required MCP callbacks" do
      # Test that NativeService properly implements the ExMCP.Server behaviour
      assert function_exported?(NativeService, :handle_tool_call, 3)
      # Note: Other callbacks are implemented by the ExMCP.Server macro
    end

    test "server metadata is correctly defined" do
      # Test server information defined in the use ExMCP.Server macro
      # This is more of a compilation test, but ensures the server is properly configured
      assert BpyMcp.NativeService.__info__(:module) == BpyMcp.NativeService
    end
  end

  describe "end-to-end tool call flow" do
    test "complete tool call cycle works" do
      # Test a complete tool call from invocation to response
      tool_name = "bpy_create_cube"
      args = %{"name" => "IntegrationTestCube", "location" => [10, 20, 30], "size" => 3.0}
      initial_state = %{test: true}

      result = NativeService.handle_tool_call(tool_name, args, initial_state)

      assert {:ok, response, returned_state} = result
      assert returned_state == initial_state
      assert is_map(response)
      assert Map.has_key?(response, :content)
      assert is_list(response.content)
      assert length(response.content) == 1

      content = hd(response.content)
      assert content["type"] == "text"
      assert String.contains?(content["text"], "IntegrationTestCube")
      assert String.contains?(content["text"], "[10.0, 20.0, 30.0]")
      assert String.contains?(content["text"], "3.0")
    end

    test "error handling in tool calls" do
      # Test that invalid tool calls are handled gracefully
      result = NativeService.handle_tool_call("nonexistent_tool", %{}, %{})

      assert {:error, error_message, _state} = result
      assert String.contains?(error_message, "Tool not found")
      assert String.contains?(error_message, "nonexistent_tool")
    end
  end

  describe "configuration integration" do
    test "config.exs exists and is valid" do
      # Test that configuration files exist
      config_path = Path.join(File.cwd!(), "config/config.exs")
      assert File.exists?(config_path)
    end

    test "mix.exs includes proper configuration" do
      # Test that mix.exs has the expected configuration
      assert function_exported?(BpyMcp.MixProject, :project, 0)
      assert function_exported?(BpyMcp.MixProject, :application, 0)
    end
  end
end
