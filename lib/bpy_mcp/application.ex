# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Application do
  @moduledoc false

  use Application

  @spec start(:normal | :permanent | :transient, any()) :: {:ok, pid()}
  @impl true
  def start(_type, _args) do
    # Ensure Pythonx is started for Blender support
    Application.ensure_all_started(:pythonx)

    children = [
      {BpyMcp.NativeService, [name: BpyMcp.NativeService]},
      {BpyMcp.StdioServer, []}
    ]

    opts = [strategy: :one_for_one, name: BpyMcp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
