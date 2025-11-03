# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService do
  import Briefly

  @moduledoc """
  Native BEAM service for Blender bpy MCP using ex_mcp library.
  Provides 3D modeling and rendering tools via MCP protocol.
  """

  # Suppress warnings from ex_mcp DSL generated code
  @compile {:no_warn_undefined, :no_warn_pattern}

  use ExMCP.Server,
    name: "Blender bpy MCP Server",
    version: "0.1.0"

  # Whitelist of allowed commands
  @allowed_commands MapSet.new([
                      "create_cube",
                      "create_sphere",
                      "get_scene_info",
                      "reset_scene",
                      "export_bmesh",
                      "import_bmesh"
                    ])

  # Command registry - maps command names to handler functions and schemas
  @commands %{
    "reset_scene" => %{
      handler: :handle_reset_scene,
      schema: %{type: "object", properties: %{}},
      description: "Resets the Blender scene to a clean state"
    },
    "create_cube" => %{
      handler: :handle_create_cube,
      schema: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Name for the cube object", default: "Cube"},
          location: %{
            type: "array",
            items: %{type: "number"},
            description: "Location as [x, y, z] coordinates",
            default: [0, 0, 0]
          },
          size: %{type: "number", description: "Size of the cube", default: 2.0}
        }
      },
      description: "Create a cube object in the Blender scene"
    },
    "create_sphere" => %{
      handler: :handle_create_sphere,
      schema: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Name for the sphere object", default: "Sphere"},
          location: %{
            type: "array",
            items: %{type: "number"},
            description: "Location as [x, y, z] coordinates",
            default: [0, 0, 0]
          },
          radius: %{type: "number", description: "Radius of the sphere", default: 1.0}
        }
      },
      description: "Create a sphere object in the Blender scene"
    },
    "get_scene_info" => %{
      handler: :handle_get_scene_info,
      schema: %{type: "object", properties: %{}},
      description: "Get information about the current Blender scene"
    },
    "export_bmesh" => %{
      handler: :handle_export_bmesh,
      schema: %{type: "object", properties: %{}},
      description: "Export the current Blender scene as BMesh data in EXT_mesh_bmesh format"
    },
    "import_bmesh" => %{
      handler: :handle_import_bmesh,
      schema: %{
        type: "object",
        properties: %{
          gltf_data: %{type: "string", description: "glTF JSON data with EXT_mesh_bmesh extension to import"}
        }
      },
      description: "Import BMesh data from glTF JSON with EXT_mesh_bmesh extension"
    }
  }

  # Override handle_request to intercept tools/list and convert input_schema to inputSchema
  # This ensures tools returned have camelCase keys as required by MCP specification
  @impl true
  def handle_request(%{"method" => "tools/list"} = request, params, state) do
    # Handle tools/list specially to convert input_schema to inputSchema
    # Call parent first to get the standard response
    case super(request, params, state) do
      {:reply, response, new_state} ->
        # Convert input_schema to inputSchema in the response
        converted_response = convert_response_keys(response)
        {:reply, converted_response, new_state}
      
      other ->
        other
    end
  end
  
  # Convert input_schema to inputSchema in tools/list response
  defp convert_response_keys(%{"jsonrpc" => "2.0", "result" => %{"tools" => tools}} = response) do
    converted_tools = 
      tools
      |> Enum.map(fn tool -> 
          # Handle both map formats (with string or atom keys)
          tool
          |> convert_map_keys()
          |> convert_keys_to_camel_case()
        end)
    Map.put(response, "result", %{"tools" => converted_tools})
  end
  
  defp convert_response_keys(response), do: response
  
  # Convert all atom keys to string keys first for consistent processing
  defp convert_map_keys(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end
  
  defp convert_map_keys(value), do: value
  
  # Helper to get attribute map (from ExMCP.Server)
  defp get_attribute_map(attr_name) do
    Module.get_attribute(__MODULE__, attr_name) || %{}
  end

  # Convert snake_case keys to camelCase for MCP spec
  defp convert_keys_to_camel_case(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {:input_schema, value} -> {"inputSchema", convert_keys_to_camel_case(value)}
      {"input_schema", value} -> {"inputSchema", convert_keys_to_camel_case(value)}
      {:inputSchema, value} -> {"inputSchema", convert_keys_to_camel_case(value)}  # Already correct
      {"inputSchema", value} -> {"inputSchema", convert_keys_to_camel_case(value)}  # Already correct
      {:output_schema, value} -> {"outputSchema", convert_keys_to_camel_case(value)}
      {"output_schema", value} -> {"outputSchema", convert_keys_to_camel_case(value)}
      {:outputSchema, value} -> {"outputSchema", convert_keys_to_camel_case(value)}  # Already correct
      {"outputSchema", value} -> {"outputSchema", convert_keys_to_camel_case(value)}  # Already correct
      {key, value} when is_atom(key) -> {Atom.to_string(key), convert_keys_to_camel_case(value)}
      {key, value} -> {key, convert_keys_to_camel_case(value)}
    end)
  end

  defp convert_keys_to_camel_case(list) when is_list(list) do
    Enum.map(list, &convert_keys_to_camel_case/1)
  end

  defp convert_keys_to_camel_case(value), do: value

  # Individual command tools - each command is now a separate MCP tool

  deftool "reset_scene" do
    meta do
      name("Reset Scene")
      description("Resets the Blender scene to a clean state")
    end

    input_schema(%{
      type: "object",
      properties: %{
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "create_cube" do
    meta do
      name("Create Cube")
      description("Create a cube object in the Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{
        name: %{type: "string", description: "Name for the cube object", default: "Cube"},
        location: %{
          type: "array",
          items: %{type: "number"},
          description: "Location as [x, y, z] coordinates",
          default: [0, 0, 0]
        },
        size: %{type: "number", description: "Size of the cube", default: 2.0},
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "create_sphere" do
    meta do
      name("Create Sphere")
      description("Create a sphere object in the Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{
        name: %{type: "string", description: "Name for the sphere object", default: "Sphere"},
        location: %{
          type: "array",
          items: %{type: "number"},
          description: "Location as [x, y, z] coordinates",
          default: [0, 0, 0]
        },
        radius: %{type: "number", description: "Radius of the sphere", default: 1.0},
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "get_scene_info" do
    meta do
      name("Get Scene Info")
      description("Get information about the current Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "export_bmesh" do
    meta do
      name("Export BMesh")
      description("Export the current Blender scene as BMesh data in EXT_mesh_bmesh format")
    end

    input_schema(%{
      type: "object",
      properties: %{
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "import_bmesh" do
    meta do
      name("Import BMesh")
      description("Import BMesh data from glTF JSON with EXT_mesh_bmesh extension")
    end

    input_schema(%{
      type: "object",
      properties: %{
        gltf_data: %{type: "string", description: "glTF JSON data with EXT_mesh_bmesh extension to import"},
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      },
      required: ["gltf_data"]
    })
  end

  # Individual tool handlers - each command is now handled directly

  @impl true
  def handle_tool_call("reset_scene", args, state) do
    with {:ok, temp_dir, context_pid} <- get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.reset_scene(temp_dir) do
      # Encode context token with updated metadata
      case encode_context_token(context_pid, %{scene_id: get_scene_id(context_pid), operation_count: 0}) do
        {:ok, token} ->
          {:ok, %{content: [text("Scene reset successfully. Context token: #{token}")]}, Map.put(state, :context_token, token)}
        _ ->
          {:ok, %{content: [text("Result: #{result}")]}, state}
      end
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("create_cube", args, state) do
    name = Map.get(args, "name", "Cube")
    location = Map.get(args, "location", [0, 0, 0])
    size = Map.get(args, "size", 2.0)

    with {:ok, temp_dir, context_pid} <- get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.create_cube(name, location, size, temp_dir) do
      {:ok, %{content: [text("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("create_sphere", args, state) do
    name = Map.get(args, "name", "Sphere")
    location = Map.get(args, "location", [0, 0, 0])
    radius = Map.get(args, "radius", 1.0)

    with {:ok, temp_dir, context_pid} <- get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.create_sphere(name, location, radius, temp_dir) do
      {:ok, %{content: [text("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("get_scene_info", args, state) do
    with {:ok, temp_dir, _context_pid} <- get_or_create_context(args, state),
         {:ok, info} <- BpyMcp.BpyTools.get_scene_info(temp_dir) do
      {:ok, %{content: [text("Scene info: #{inspect(info)}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("export_bmesh", args, state) do
    with {:ok, temp_dir, _context_pid} <- get_or_create_context(args, state),
         {:ok, bmesh_data} <- BpyMcp.BpyMesh.export_bmesh_scene(temp_dir) do
      {:ok, %{content: [%{"type" => "text", "text" => Jason.encode!(bmesh_data)}]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("import_bmesh", args, state) do
    gltf_data = Map.get(args, "gltf_data", "")

    with {:ok, _temp_dir, _context_pid} <- get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyMesh.import_bmesh_scene(gltf_data) do
      {:ok, %{content: [text("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  # Context management helpers

  # Get or create context from token or scene_id
  defp get_or_create_context(args, state) do
    # Try to get context from token first
    context_token = Map.get(args, "context_token") || Map.get(state, :context_token)
    scene_id = Map.get(args, "scene_id", "default")

    case context_token do
      nil ->
        # No token, create or get context by scene_id
        create_or_get_context(scene_id, state)

      token when is_binary(token) ->
        # Decode token to get PID
        case decode_context_token(token) do
          {:ok, %{pid: pid, metadata: metadata}} ->
            # Verify PID is still alive
            if Process.alive?(pid) do
              # Get or create temp_dir for this context
              temp_dir = Map.get(state, :temp_dir) || create_temp_dir()
              {:ok, temp_dir, pid}
            else
              # PID is dead, create new context
              create_or_get_context(scene_id, state)
            end

          {:error, _reason} ->
            # Token invalid, create new context
            create_or_get_context(scene_id, state)
        end
    end
  end

  # Create or get context by scene_id
  defp create_or_get_context(scene_id, state) do
    case BpyMcp.set_context(scene_id) do
      {:ok, pid} ->
        # Create temp_dir for this context
        temp_dir = Map.get(state, :temp_dir) || create_temp_dir()
        
        # Encode context token
        case encode_context_token(pid, %{scene_id: scene_id, operation_count: 0}) do
          {:ok, token} ->
            {:ok, temp_dir, pid}
          _ ->
            {:ok, temp_dir, pid}
        end

      {:error, reason} ->
        {:error, "Failed to create context: #{reason}"}
    end
  end

  # Get scene_id from PID
  defp get_scene_id(pid) do
    try do
      BpyMcp.SceneManager.get_scene_id(pid)
    rescue
      _ -> "default"
    end
  end

  # Create temporary directory
  defp create_temp_dir do
    case Briefly.create(type: :directory) do
      {:ok, temp_dir} -> temp_dir
      {:error, _} -> System.tmp_dir!()
    end
  end

  # Fallback for unknown tools
  @impl true
  def handle_tool_call(tool_name, _args, state) do
    {:error, "Tool not found: #{tool_name}", state}
  end

  # Helper functions to encode/decode PID data in macaroon tokens
  @doc """
  Encodes PID and optional metadata into a macaroon token for context strings.
  
  ## Parameters
    - pid: Process ID to encode
    - metadata: Optional map of additional context data (scene_id, operation_count, etc.)
  
  ## Returns
    - `{:ok, token}` - Base64-encoded macaroon token containing PID data
    - `{:error, reason}` - Error if encoding fails
  """
  @spec encode_context_token(pid(), map()) :: {:ok, String.t()} | {:error, String.t()}
  defp encode_context_token(pid, metadata \\ %{}) when is_pid(pid) do
    try do
      # Serialize PID and metadata as JSON for storage in caveat
      pid_str = :erlang.pid_to_list(pid) |> List.to_string()
      data = Map.merge(metadata, %{pid: pid_str})
      data_json = Jason.encode!(data)
      
      # Create macaroon with context data stored in location and as encoded data
      location = "bpy-mcp-context"
      secret_key = get_or_create_secret_key()
      
      # Generate a unique kid (key ID) - we'll store the data in a Mutations caveat
      # Mutations caveat accepts a list of strings, so we'll encode our JSON as base64
      kid = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      
      # Store PID data in a Mutations caveat (which accepts list of strings)
      # Encode the JSON data and store it as a mutation entry
      encoded_data = Base.encode64(data_json)
      # Use struct construction at runtime to avoid compile-time dependency issues
      context_caveat = struct(Macfly.Caveat.Mutations, mutations: [encoded_data])
      
      # Create macaroon with the caveat containing our context data
      macaroon = Macfly.Macaroon.new(secret_key, kid, location, [context_caveat])
      
      # Encode macaroon to string
      token = Macfly.Macaroon.encode(macaroon)
      {:ok, token}
    rescue
      e -> {:error, "Failed to encode context token: #{Exception.message(e)}"}
    end
  end

  @doc """
  Decodes a macaroon token to extract PID and metadata from context string.
  
  ## Parameters
    - token: Base64-encoded macaroon token
  
  ## Returns
    - `{:ok, %{pid: pid(), metadata: map()}}` - Decoded PID and metadata
    - `{:error, reason}` - Error if decoding fails
  """
  @spec decode_context_token(String.t()) :: {:ok, %{pid: pid(), metadata: map()}} | {:error, String.t()}
  defp decode_context_token(token) when is_binary(token) do
    try do
      # Decode macaroon from string
      case Macfly.Macaroon.decode(token) do
        {:ok, macaroon} ->
          # Extract PID data from Mutations caveat
          mutations_caveat = 
            Enum.find(macaroon.caveats, fn caveat ->
              case caveat do
                %Macfly.Caveat.Mutations{} -> true
                _ -> false
              end
            end)
          
          case mutations_caveat do
            nil ->
              {:error, "No context data found in token"}
            
            %Macfly.Caveat.Mutations{mutations: [encoded_data | _]} ->
              # Decode the base64-encoded JSON data
              case Base.decode64(encoded_data) do
                {:ok, data_json} ->
                  case Jason.decode(data_json) do
                    {:ok, data} ->
                      pid_str = Map.get(data, "pid")
                      
                      # Convert PID string back to PID
                      pid = 
                        try do
                          :erlang.list_to_pid(String.to_charlist(pid_str))
                        rescue
                          _ -> {:error, "Invalid PID format"}
                        end
                      
                      case pid do
                        {:error, reason} -> {:error, reason}
                        pid when is_pid(pid) ->
                          metadata = Map.drop(data, ["pid"])
                          {:ok, %{pid: pid, metadata: metadata}}
                        _ ->
                          {:error, "Failed to parse PID"}
                      end
                    
                    error ->
                      {:error, "Failed to decode PID data: #{inspect(error)}"}
                  end
                
                :error ->
                  {:error, "Invalid token format: context data is not base64 encoded"}
              end
            
            _ ->
              {:error, "Invalid Mutations caveat format"}
          end
        
        error ->
          {:error, "Failed to decode macaroon: #{inspect(error)}"}
      end
    rescue
      e -> {:error, "Failed to decode context token: #{Exception.message(e)}"}
    end
  end

  # Get or create a secret key for macaroon signing
  # In production, this should be configured securely
  defp get_or_create_secret_key do
    Application.get_env(:bpy_mcp, :macaroon_secret_key) ||
      System.get_env("BPY_MCP_MACAROON_SECRET") ||
      :crypto.strong_rand_bytes(32)
  end
end
