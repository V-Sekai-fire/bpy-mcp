# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcpTest do
  use ExUnit.Case
  doctest BpyMcp

  test "greets the world" do
    assert BpyMcp.hello() == :world
  end
end
