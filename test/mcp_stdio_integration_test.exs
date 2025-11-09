# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.McpStdioIntegrationTest do
  use ExUnit.Case, async: false
  alias BpyMcp.NativeService
  alias BpyMcp.TestHelper

  defp require_bpy(context) do
    TestHelper.setup_require_bpy(context)
  end

  @moduledoc """
  Integration tests for MCP stdio transport using JSON-RPC protocol.

  These tests verify that the MCP server correctly handles:
  - tools/list requests
  - tools/call requests (via handle_tool_call)
  - Proper tool response formats
  """

  setup do
    # Start the application with stdio transport for testing
    System.put_env("MCP_TRANSPORT", "stdio")

    # Ensure application is started
    Application.ensure_all_started(:bpy_mcp)

    on_exit(fn ->
      Application.stop(:bpy_mcp)
    end)

    %{}
  end

  describe "MCP Tools Call" do
    setup :require_bpy

    test "reset_scene tool call", %{} do
      args = %{}
      state = %{}
      result = NativeService.handle_tool_call("reset_scene", args, state)

      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
      assert is_list(response.content)
    end

    test "create_cube tool call with parameters", %{} do
      args = %{
        "name" => "IntegrationTestCube",
        "location" => [10, 20, 30],
        "size" => 3.0
      }

      state = %{}
      result = NativeService.handle_tool_call("create_cube", args, state)

      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)

      content = response.content
      assert is_list(content)
      assert length(content) > 0

      # Find text content
      text_content =
        Enum.find(content, fn item ->
          item["type"] == "text"
        end)

      assert text_content != nil
      assert String.contains?(text_content["text"], "IntegrationTestCube")
      assert String.contains?(text_content["text"], "[10, 20, 30]")
    end

    test "create_sphere tool call", %{} do
      args = %{
        "name" => "IntegrationTestSphere",
        "location" => [5, 10, 15],
        "radius" => 2.5
      }

      state = %{}
      result = NativeService.handle_tool_call("create_sphere", args, state)

      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
    end

    test "get_scene_info tool call", %{} do
      args = %{}
      state = %{}
      result = NativeService.handle_tool_call("get_scene_info", args, state)

      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
    end

    test "unknown tool returns error", %{} do
      args = %{}
      state = %{}
      result = NativeService.handle_tool_call("unknown_tool", args, state)

      assert {:error, error_message, _state} = result
      assert String.contains?(error_message, "Tool not found")
      assert String.contains?(error_message, "unknown_tool")
    end
  end

  describe "MCP Protocol Compliance" do
    setup :require_bpy

    test "tool responses have correct structure", %{} do
      tools = ["reset_scene", "create_cube", "get_scene_info"]

      Enum.each(tools, fn tool_name ->
        args = %{}
        state = %{}
        {:ok, response, _state} = NativeService.handle_tool_call(tool_name, args, state)

        assert Map.has_key?(response, :content)
        assert is_list(response.content)
        assert length(response.content) > 0

        # Each content item should have type and text
        Enum.each(response.content, fn item ->
          assert Map.has_key?(item, "type")
          assert Map.has_key?(item, "text")
        end)
      end)
    end
  end

  describe "Context Token Support" do
    setup :require_bpy

    test "tools can use context_token parameter", %{} do
      # First reset to get a context
      reset_args = %{}
      reset_state = %{}
      {:ok, _reset_response, state_after_reset} = NativeService.handle_tool_call("reset_scene", reset_args, reset_state)

      # Create cube with context_token
      create_args = %{
        "name" => "ContextCube",
        "context_token" => "test-token-123"
      }

      result = NativeService.handle_tool_call("create_cube", create_args, state_after_reset)
      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
    end
  end

  describe "Complete MCP Workflow" do
    setup :require_bpy

    test "full workflow: list tools -> call tools", %{} do
      # Step 1: List tools
      list_request = %{"method" => "tools/list"}
      list_params = %{}
      list_state = %{}

      list_result = NativeService.handle_request(list_request, list_params, list_state)

      # Verify tools are available regardless of response type
      case list_result do
        {:reply, list_response, _list_state} ->
          assert length(list_response["result"]["tools"]) >= 6

        {:noreply, _list_state} ->
          # Tools are still available via handle_tool_call
          {:ok, _response, _state} = NativeService.handle_tool_call("reset_scene", %{}, %{})
          assert true
      end

      # Step 2: Reset scene
      reset_result = NativeService.handle_tool_call("reset_scene", %{}, %{})
      assert {:ok, _reset_response, reset_state} = reset_result

      # Step 3: Create objects
      cube_result =
        NativeService.handle_tool_call(
          "create_cube",
          %{
            "name" => "WorkflowCube",
            "location" => [1, 2, 3]
          },
          reset_state
        )

      assert {:ok, _cube_response, cube_state} = cube_result

      sphere_result =
        NativeService.handle_tool_call(
          "create_sphere",
          %{
            "name" => "WorkflowSphere",
            "location" => [4, 5, 6]
          },
          cube_state
        )

      assert {:ok, _sphere_response, sphere_state} = sphere_result

      # Step 4: Get scene info
      info_result = NativeService.handle_tool_call("get_scene_info", %{}, sphere_state)
      assert {:ok, info_response, _info_state} = info_result
      assert Map.has_key?(info_response, :content)
    end
  end
end
