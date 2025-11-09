# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Application do
  @moduledoc false

  use Application

  @doc """
  Configure environment variables for headless operation.
  This prevents GUI initialization and console output that would break MCP stdio protocol.
  """
  @spec configure_headless() :: :ok
  def configure_headless do
    # Set to run in headless/background mode
    System.put_env("SCENE_HEADLESS", "1")

    # Prevent X11 display issues
    System.put_env("DISPLAY", "")

    # Force Vulkan backend for headless rendering
    System.put_env(
      "VK_ICD_FILENAMES",
      "/usr/share/vulkan/icd.d/intel_icd.x86_64.json:/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
    )

    System.put_env("VULKAN_SDK", "")
    System.put_env("VK_LAYER_PATH", "")

    # Disable audio and verbose output
    System.put_env("SCENE_NO_AUDIO", "1")
    System.put_env("SCENE_VERBOSE", "0")

    # Additional Vulkan-specific settings
    System.put_env("ENABLE_VULKAN_VALIDATION", "0")
    System.put_env("VK_KHRONOS_VALIDATION", "0")

    :ok
  end

  @spec start(:normal | :permanent | :transient, any()) :: {:ok, pid()}
  @impl true
  def start(_type, _args) do
    # Configure for headless operation to prevent GUI initialization
    # and console output that breaks MCP stdio protocol
    configure_headless()

    # Ensure required dependencies are started
    Application.ensure_all_started(:pythonx)
    Application.ensure_all_started(:briefly)
    Application.ensure_all_started(:aria_storage)

    # Check if running in a release (Mix not available)
    is_release = not Code.ensure_loaded?(Mix)

    # Determine transport type from environment
    # Default to http if PORT is set (container deployment like Smithery), otherwise stdio
    transport_type = 
      case System.get_env("MCP_TRANSPORT") do
        "stdio" -> :stdio
        "http" -> :http
        "sse" -> :sse
        _ ->
          # Default to http if PORT is set (Smithery deployment), otherwise stdio
          if System.get_env("PORT"), do: :http, else: :stdio
      end
    
    # Configure for stdio mode when using stdio transport
    if transport_type == :stdio do
      # Logger is already set to emergency in vm.args/ELIXIR_ERL_OPTIONS
      # But configure it again here as a safeguard to ensure no warnings escape
      # This must be the FIRST thing we do to prevent any warnings
      Logger.configure(level: :emergency)
      
      # Suppress all stdout output - critical for JSON-RPC over stdio
      # Redirect any potential stdout writes to stderr (though logger should handle this)
      Application.put_env(:ex_mcp, :stdio_mode, true)
      Application.put_env(:ex_mcp, :stdio_startup_delay, 10)
      
      # Distributed Erlang is disabled for stdio mode, so no node name conflicts possible
      
      # DO NOT output anything to stdout/stderr here - the MCP server handles initialization
      # Any output before ExMCP is ready will break the JSON-RPC protocol
    end

    children = [
      # Registry for scene managers
      {Registry, keys: :unique, name: AriaForge.SceneRegistry},

      # Dynamic supervisor for scene manager processes
      {DynamicSupervisor, name: AriaForge.SceneSupervisor, strategy: :one_for_one}
    ]

    # Start MCP server with appropriate transport
    children =
      if not is_release and Code.ensure_loaded?(Mix) and Mix.env() == :test do
        # In test, start with native transport
        children ++ [
          {AriaForge.NativeService, [transport: :native, name: AriaForge.NativeService]}
        ]
      else
        # For stdio transport, no port needed
        server_opts = [
          transport: transport_type,
          name: AriaForge.NativeService
        ]
        
        # Add port and host only for HTTP transport
        server_opts =
          if transport_type == :http do
            port = 
              case System.get_env("PORT") do
                nil -> 4000
                port_str -> String.to_integer(port_str)
              end
            
            # Use 0.0.0.0 for Docker/container deployments to accept external connections
            # Use localhost for local development
            host = 
              case System.get_env("HOST") do
                nil ->
                  # Default to 0.0.0.0 if PORT is set (container deployment), otherwise localhost
                  if System.get_env("PORT"), do: "0.0.0.0", else: "localhost"
                host -> host
              end
            
            server_opts
            |> Keyword.put(:port, port)
            |> Keyword.put(:host, host)
          else
            server_opts
          end
        
        children ++ [
          {AriaForge.NativeService, server_opts}
        ]
      end

    opts = [strategy: :one_for_one, name: AriaForge.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
