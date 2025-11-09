# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeServiceTest do
  use ExUnit.Case, async: true
  alias BpyMcp.NativeService

  describe "module structure" do
    test "defines handle_tool_call function" do
      assert function_exported?(NativeService, :handle_tool_call, 3)
    end

    test "is a GenServer" do
      assert BpyMcp.NativeService.__info__(:attributes)[:behaviour] == [GenServer]
    end
  end

  describe "tool call error handling" do
    test "returns error for unknown tool" do
      args = %{}
      state = %{}

      result = NativeService.handle_tool_call("unknown_tool", args, state)

      assert {:error, "Tool not found: unknown_tool", ^state} = result
    end

    test "returns error for empty tool name" do
      args = %{}
      state = %{}

      result = NativeService.handle_tool_call("", args, state)

      assert {:error, "Tool not found: ", ^state} = result
    end
  end
end
