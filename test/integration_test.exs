# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.IntegrationTest do
  use ExUnit.Case, async: false
  alias BpyMcp.NativeService
  alias BpyMcp.TestHelper

  defp require_bpy(context) do
    TestHelper.setup_require_bpy(context)
  end

  describe "end-to-end tool call flow" do
    setup :require_bpy

    test "complete tool call cycle works", %{} do
      # Test a complete tool call from invocation to response using individual tools
      tool_name = "create_cube"

      args = %{
        "name" => "IntegrationTestCube",
        "location" => [10, 20, 30],
        "size" => 3.0
      }

      initial_state = %{test: true}

      result = NativeService.handle_tool_call(tool_name, args, initial_state)

      assert {:ok, response, returned_state} = result
      assert is_map(response)
      assert Map.has_key?(response, :content)
      assert is_list(response.content)
      assert length(response.content) >= 1

      content = hd(response.content)
      assert content["type"] == "text"
      assert String.contains?(content["text"], "IntegrationTestCube")
      assert String.contains?(content["text"], "[10, 20, 30]")
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
end
