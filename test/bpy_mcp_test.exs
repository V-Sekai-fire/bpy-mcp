defmodule BpyMcpTest do
  use ExUnit.Case
  doctest BpyMcp

  test "greets the world" do
    assert BpyMcp.hello() == :world
  end
end
