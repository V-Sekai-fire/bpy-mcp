# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService do
  @moduledoc """
  Native BEAM service for Blender bpy MCP using ex_mcp library.
  Provides 3D modeling and rendering tools via MCP protocol.
  """

  alias BpyMcp.NativeService.Context
  alias BpyMcp.NativeService.SchemaConverter
  alias BpyMcp.ResourceStorage

  # Suppress warnings from ex_mcp DSL generated code
  @compile {:no_warn_undefined, :no_warn_pattern}

  use ExMCP.Server,
    name: "Blender bpy MCP Server",
    version: "0.1.0"

  # Helper function to create text content for MCP responses
  # Use text_content to avoid conflict with ExMCP.Server's text/2
  defp text_content(content) when is_binary(content) do
    %{"type" => "text", "text" => content}
  end

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

  deftool "introspect_bpy" do
    meta do
      name("Introspect bpy")
      description("Introspect Blender bpy/bmesh structure and methods for debugging and understanding API")
    end

    input_schema(%{
      type: "object",
      properties: %{
        object_path: %{
          type: "string",
          description: "Path to introspect (e.g., 'bmesh', 'bmesh.ops', 'bpy.data.objects')",
          default: "bmesh"
        },
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

  deftool "introspect_python" do
    meta do
      name("Introspect Python")
      description("Introspect any Python object/API structure, methods, and attributes for debugging and understanding Python APIs. READ-ONLY: No code execution or state modification.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        object_path: %{
          type: "string",
          description: "Python object path to introspect (e.g., 'json', 'sys', 'math', 'collections.defaultdict'). Only alphanumeric characters, dots, and underscores allowed for security.",
          default: "json"
        },
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      },
      required: ["object_path"]
    })
  end

  deftool "acquire_context" do
    meta do
      name("Acquire Context")
      description("Acquire a scene context (create new or get existing) and return a context token. Can acquire from stored resources with optional exclusive access.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        scene_id: %{
          type: "string",
          description: "Scene ID to acquire. If not provided and no resource_uri, uses 'default'.",
          default: "default"
        },
        resource_uri: %{
          type: "string",
          description: "Resource URI (e.g., blender://stored/{storage_ref} or blender://scene/{scene_id}) to acquire from"
        },
        exclusive: %{
          type: "boolean",
          description: "Whether to acquire exclusive access (lock) to the context. Default: false.",
          default: false
        },
        timeout: %{
          type: "number",
          description: "Lock timeout in seconds (only applies when exclusive=true). Default: 300 (5 minutes).",
          default: 300
        }
      }
    })
  end

  deftool "fork_resource" do
    meta do
      name("Fork Resource")
      description("Fork a stored resource into a new scene context. Creates an independent copy of the stored scene for editing.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        resource_uri: %{
          type: "string",
          description: "Resource URI (e.g., blender://stored/{storage_ref}) to fork from"
        },
        storage_ref: %{
          type: "string",
          description: "Storage reference from AriaStorage to fork from"
        },
        new_scene_id: %{
          type: "string",
          description: "New scene ID for the forked context. If not provided, generates a unique ID."
        },
        exclusive: %{
          type: "boolean",
          description: "Whether to acquire exclusive access (lock) to the forked context. Default: false.",
          default: false
        },
        timeout: %{
          type: "number",
          description: "Lock timeout in seconds (only applies when exclusive=true). Default: 300 (5 minutes).",
          default: 300
        }
      },
      required: []
    })
  end

  deftool "get_context" do
    meta do
      name("Get Context")
      description("Get information about a context from a context token, scene ID, or resource URI")
    end

    input_schema(%{
      type: "object",
      properties: %{
        context_token: %{
          type: "string",
          description: "Context token (macaroon) to decode and get context information"
        },
        scene_id: %{
          type: "string",
          description: "Scene ID to get context information for. If not provided and no token, uses 'default'.",
          default: "default"
        },
        resource_uri: %{
          type: "string",
          description: "Resource URI (e.g., blender://scene/{scene_id}) to get context token from"
        }
      }
    })
  end

  deftool "get_context_token" do
    meta do
      name("Get Context Token")
      description("Get a context token for a scene from a resource URI or scene ID. Use this token in other tools to operate on that specific scene.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        resource_uri: %{
          type: "string",
          description: "Resource URI (e.g., blender://scene/{scene_id}) to get context token for"
        },
        scene_id: %{
          type: "string",
          description: "Scene ID to get context token for. If not provided and no URI, uses 'default'.",
          default: "default"
        }
      }
    })
  end

  deftool "list_contexts" do
    meta do
      name("List Contexts")
      description("List all active scene contexts with their scene IDs and operation counts")
    end

    input_schema(%{
      type: "object",
      properties: %{}
    })
  end

  deftool "stop_context" do
    meta do
      name("Stop Context")
      description("Stop and remove a scene context by scene ID or context token")
    end

    input_schema(%{
      type: "object",
      properties: %{
        context_token: %{
          type: "string",
          description: "Context token (macaroon) to decode and stop the associated context"
        },
        scene_id: %{
          type: "string",
          description: "Scene ID to stop. If not provided and no token, uses 'default'.",
          default: "default"
        }
      }
    })
  end



  # Override handle_request to intercept resources/list and tools/list
  @impl true
  def handle_request(%{"method" => "resources/list"} = request, _params, state) do
    # List all active Blender scene contexts as resources
    active_resources = 
      case BpyMcp.list_contexts() do
        {:ok, contexts} ->
          Enum.map(contexts, fn %{scene_id: scene_id, pid: pid, operation_count: op_count} ->
            # Generate context token for this scene to include in resource
            context_token = 
              case Context.encode_context_token(pid, %{scene_id: scene_id, operation_count: op_count}) do
                {:ok, token} -> token
                _ -> nil
              end
            
            %{
              "uri" => "blender://scene/#{scene_id}",
              "name" => "Scene: #{scene_id}",
              "description" => "Blender scene context with #{op_count} operations#{if context_token, do: " (context_token available)", else: ""}",
              "mimeType" => "application/json"
            }
          end)
        
        {:error, _reason} ->
          []
      end
    
    # Also list stored resources from AriaStorage
    stored_resources =
      case ResourceStorage.list_scene_resources(limit: 100) do
        {:ok, storage_refs} ->
          Enum.map(storage_refs, fn storage_ref ->
            %{
              "uri" => "blender://stored/#{storage_ref}",
              "name" => "Stored Scene: #{storage_ref}",
              "description" => "Persisted Blender scene resource stored in AriaStorage",
              "mimeType" => "application/json"
            }
          end)
        
        {:error, _reason} ->
          []
      end
    
    # Combine active and stored resources
    all_resources = active_resources ++ stored_resources
    
    id = Map.get(request, "id", nil)
    response = 
      %{
        "jsonrpc" => "2.0",
        "result" => %{
          "resources" => all_resources
        }
      }
      |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
    
    {:reply, response, state}
  end

  def handle_request(%{"method" => "resources/read"} = request, params, state) do
    uri = Map.get(params, "uri", "")
    
    cond do
      # Handle stored resources from AriaStorage
      String.starts_with?(uri, "blender://stored/") ->
        storage_ref = String.replace_prefix(uri, "blender://stored/", "")
        case ResourceStorage.get_scene_resource(storage_ref, format: :json) do
          {:ok, content} ->
            id = Map.get(request, "id", nil)
            response = 
              %{
                "jsonrpc" => "2.0",
                "result" => %{
                  "contents" => [
                    %{
                      "uri" => uri,
                      "mimeType" => "application/json",
                      "text" => if(is_map(content), do: Jason.encode!(content), else: content)
                    }
                  ]
                }
              }
              |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
            
            {:reply, response, state}
          
          {:error, reason} ->
            id = Map.get(request, "id", nil)
            response = 
              %{
                "jsonrpc" => "2.0",
                "error" => %{
                  "code" => -32603,
                  "message" => "Failed to read stored resource: #{reason}"
                }
              }
              |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
            
            {:reply, response, state}
        end
      
      # Handle active scene resources
      String.starts_with?(uri, "blender://scene/") ->
        case parse_scene_uri(uri) do
          {:ok, scene_id} ->
            case get_scene_resource(scene_id) do
              {:ok, content} ->
                # Optionally store to AriaStorage for persistence (async)
                # This creates a backup copy of the scene
                Task.start(fn ->
                  store_scene_to_aria_storage(scene_id, content)
                end)
                
                id = Map.get(request, "id", nil)
                response = 
                  %{
                    "jsonrpc" => "2.0",
                    "result" => %{
                      "contents" => [
                        %{
                          "uri" => uri,
                          "mimeType" => "application/json",
                          "text" => Jason.encode!(content)
                        }
                      ]
                    }
                  }
                  |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
                
                {:reply, response, state}
              
              {:error, reason} ->
                id = Map.get(request, "id", nil)
                response = 
                  %{
                    "jsonrpc" => "2.0",
                    "error" => %{
                      "code" => -32603,
                      "message" => "Failed to read resource: #{reason}"
                    }
                  }
                  |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
                
                {:reply, response, state}
            end
          
          {:error, reason} ->
            id = Map.get(request, "id", nil)
            response = 
              %{
                "jsonrpc" => "2.0",
                "error" => %{
                  "code" => -32602,
                  "message" => "Invalid resource URI: #{reason}"
                }
              }
              |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
            
            {:reply, response, state}
        end
      
      true ->
        id = Map.get(request, "id", nil)
        response = 
          %{
            "jsonrpc" => "2.0",
            "error" => %{
              "code" => -32602,
              "message" => "Invalid resource URI format"
            }
          }
          |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
        
        {:reply, response, state}
    end
  end

  # Override handle_request to intercept tools/list and convert input_schema to inputSchema
  # This ensures tools returned have camelCase keys as required by MCP specification
  @impl true
  def handle_request(%{"method" => "tools/list"} = request, _params, state) do
    # Get tools directly using get_tools() from ex_mcp
    tools_map = get_tools()
    
    # Convert tools map to list format required by MCP spec
    tools_list = 
      tools_map
      |> Map.values()
      |> Enum.map(fn tool ->
        # Convert tool to MCP format with camelCase keys
        %{
          "name" => tool.name,
          "description" => tool.description,
          "inputSchema" => SchemaConverter.convert_keys_to_camel_case(tool.input_schema)
        }
      end)
    
    # Get id from request if present
    id = Map.get(request, "id", nil)
    
    # Build proper JSON-RPC response
    response = 
      %{
        "jsonrpc" => "2.0",
        "result" => %{
          "tools" => tools_list
        }
      }
      |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
    
    {:reply, response, state}
  end

  # Individual tool handlers - each command is now handled directly

  @impl true
  def handle_tool_call("reset_scene", args, state) do
    with {:ok, temp_dir, context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.reset_scene(temp_dir) do
      # Encode context token with updated metadata
      case Context.encode_context_token(context_pid, %{scene_id: Context.get_scene_id(context_pid), operation_count: 0}) do
        {:ok, _token} ->
          {:ok, %{content: [text_content("Scene reset successfully")]}, state}
        _ ->
          {:ok, %{content: [text_content("Result: #{result}")]}, state}
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

    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.create_cube(name, location, size, temp_dir) do
      {:ok, %{content: [text_content("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("create_sphere", args, state) do
    name = Map.get(args, "name", "Sphere")
    location = Map.get(args, "location", [0, 0, 0])
    radius = Map.get(args, "radius", 1.0)

    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.create_sphere(name, location, radius, temp_dir) do
      {:ok, %{content: [text_content("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("get_scene_info", args, state) do
    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, info} <- BpyMcp.BpyTools.get_scene_info(temp_dir) do
      {:ok, %{content: [text_content("Scene info: #{inspect(info)}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("export_bmesh", args, state) do
    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, bmesh_data} <- BpyMcp.BpyMesh.export_bmesh_scene(temp_dir) do
      # Format as JSON string for better readability
      json_text = Jason.encode!(bmesh_data, pretty: true)
      {:ok, %{content: [%{"type" => "text", "text" => json_text}]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("import_bmesh", args, state) do
    gltf_data = Map.get(args, "gltf_data", "")

    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyMesh.import_bmesh_scene(gltf_data, temp_dir) do
      {:ok, %{content: [text_content("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("introspect_bpy", args, state) do
    object_path = Map.get(args, "object_path", "bmesh")

    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.introspect_bpy(object_path, temp_dir) do
      {:ok, %{content: [text_content("Introspection result:\n#{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("introspect_python", args, state) do
    object_path = Map.get(args, "object_path")

    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.introspect_python(object_path, nil, temp_dir) do
      {:ok, %{content: [text_content("Introspection result:\n#{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("acquire_context", args, state) do
    scene_id = Map.get(args, "scene_id", "default")
    resource_uri = Map.get(args, "resource_uri")
    exclusive = Map.get(args, "exclusive", false)
    timeout = Map.get(args, "timeout", 300)
    
    cond do
      # Acquire from stored resource: load from AriaStorage
      resource_uri != nil and String.starts_with?(resource_uri, "blender://stored/") ->
        handle_acquire_from_stored(resource_uri, scene_id, exclusive, timeout, state)
      
      # Acquire from active scene resource: get existing context
      resource_uri != nil and String.starts_with?(resource_uri, "blender://scene/") ->
        case parse_scene_uri(resource_uri) do
          {:ok, sid} ->
            handle_set_context_with_exclusive(sid, exclusive, timeout, state)
          
          {:error, reason} ->
            {:error, "Invalid resource URI: #{reason}", state}
        end
      
      # Standard acquire_context: create or get by scene_id
      true ->
        handle_set_context_with_exclusive(scene_id, exclusive, timeout, state)
    end
  end

  @impl true
  def handle_tool_call("fork_resource", args, state) do
    resource_uri = Map.get(args, "resource_uri")
    storage_ref = Map.get(args, "storage_ref")
    new_scene_id = Map.get(args, "new_scene_id")
    exclusive = Map.get(args, "exclusive", false)
    timeout = Map.get(args, "timeout", 300)
    
    # Determine storage_ref from URI or direct parameter
    target_storage_ref = 
      if resource_uri do
        String.replace_prefix(resource_uri, "blender://stored/", "")
      else
        storage_ref
      end
    
    if not target_storage_ref or target_storage_ref == "" do
      {:error, "Must provide either resource_uri or storage_ref", state}
    else
      # Generate new scene_id if not provided
      final_scene_id = new_scene_id || "forked_#{target_storage_ref}_#{System.unique_integer([:positive])}"
      
      # Retrieve the stored resource and fork it
      case ResourceStorage.get_scene_resource(target_storage_ref, format: :json) do
        {:ok, stored_data} ->
          case BpyMcp.set_context(final_scene_id) do
            {:ok, pid} ->
              # Store the forked scene to AriaStorage as a new independent resource
              case ResourceStorage.store_scene_resource(final_scene_id, stored_data, 
                format: :json, 
                compression: :zstd
              ) do
                {:ok, _forked_ref} ->
                  metadata = %{
                    scene_id: final_scene_id, 
                    operation_count: 0, 
                    forked_from: target_storage_ref
                  }
                  
                  metadata = if exclusive do
                    Map.merge(metadata, %{
                      exclusive: true,
                      locked_until: DateTime.add(DateTime.utc_now(), timeout, :second)
                    })
                  else
                    metadata
                  end
                  
                  case Context.encode_context_token(pid, metadata) do
                    {:ok, token} ->
                      info = %{
                        scene_id: final_scene_id,
                        context_token: token,
                        forked_from: target_storage_ref,
                        exclusive: exclusive,
                        resource_uri: "blender://scene/#{final_scene_id}"
                      }
                      
                      info = if exclusive do
                        Map.put(info, :locked_until, DateTime.add(DateTime.utc_now(), timeout, :second) |> DateTime.to_iso8601())
                      else
                        info
                      end
                      
                      {:ok, %{content: [text_content("Resource forked successfully: #{Jason.encode!(info)}")]}, Map.put(state, :context_token, token)}
                    
                    {:error, reason} ->
                      {:error, "Failed to encode context token: #{reason}", state}
                  end
                
                {:error, reason} ->
                  {:error, "Failed to store forked resource: #{reason}", state}
              end
            
            {:error, reason} ->
              {:error, "Failed to create forked context: #{reason}", state}
          end
        
        {:error, reason} ->
          {:error, "Failed to retrieve stored resource: #{reason}", state}
      end
    end
  end

  # Helper to handle standard context setting with optional exclusive access
  defp handle_set_context_with_exclusive(scene_id, exclusive, timeout, state) do
    with {:ok, pid} <- BpyMcp.set_context(scene_id) do
      metadata = %{
        scene_id: scene_id, 
        operation_count: 0
      }
      
      metadata = if exclusive do
        Map.merge(metadata, %{
          exclusive: true,
          locked_until: DateTime.add(DateTime.utc_now(), timeout, :second)
        })
      else
        metadata
      end
      
      case Context.encode_context_token(pid, metadata) do
        {:ok, token} ->
          pid_str = :erlang.pid_to_list(pid) |> List.to_string()
          info = %{
            scene_id: scene_id,
            context_token: token,
            pid: pid_str,
            exclusive: exclusive
          }
          
          info = if exclusive do
            Map.put(info, :locked_until, DateTime.add(DateTime.utc_now(), timeout, :second) |> DateTime.to_iso8601())
          else
            info
          end
          
          {:ok, %{content: [text_content("Context set successfully: #{Jason.encode!(info)}")]}, Map.put(state, :context_token, token)}
        
        {:error, reason} ->
          {:error, "Failed to encode context token: #{reason}", state}
      end
    else
      {:error, reason} -> 
        {:error, "Failed to set context: #{reason}", state}
    end
  end

  # Helper to acquire context from stored resource
  defp handle_acquire_from_stored(resource_uri, scene_id, exclusive, timeout, state) do
    storage_ref = String.replace_prefix(resource_uri, "blender://stored/", "")
    final_scene_id = if scene_id == "default", do: storage_ref, else: scene_id
    
    case ResourceStorage.get_scene_resource(storage_ref, format: :json) do
      {:ok, stored_data} ->
        case BpyMcp.set_context(final_scene_id) do
          {:ok, pid} ->
            # Import scene data if available (async, don't block)
            if is_map(stored_data) and Map.has_key?(stored_data, "scene_info") do
              Task.start(fn ->
                # TODO: Import scene data into Blender context
                :ok
              end)
            end
            
            metadata = %{
              scene_id: final_scene_id, 
              operation_count: 0,
              acquired_from: storage_ref
            }
            
            metadata = if exclusive do
              Map.merge(metadata, %{
                exclusive: true,
                locked_until: DateTime.add(DateTime.utc_now(), timeout, :second)
              })
            else
              metadata
            end
            
            case Context.encode_context_token(pid, metadata) do
              {:ok, token} ->
                info = %{
                  scene_id: final_scene_id,
                  context_token: token,
                  exclusive: exclusive,
                  acquired_from: storage_ref,
                  resource_uri: "blender://scene/#{final_scene_id}"
                }
                
                info = if exclusive do
                  Map.put(info, :locked_until, DateTime.add(DateTime.utc_now(), timeout, :second) |> DateTime.to_iso8601())
                else
                  info
                end
                
                {:ok, %{content: [text_content("Context acquired from stored resource: #{Jason.encode!(info)}")]}, Map.put(state, :context_token, token)}
              
              {:error, reason} ->
                {:error, "Failed to encode context token: #{reason}", state}
            end
          
          {:error, reason} ->
            {:error, "Failed to create context from stored resource: #{reason}", state}
        end
      
      {:error, reason} ->
        {:error, "Failed to retrieve stored resource: #{reason}", state}
    end
  end


  @impl true
  def handle_tool_call("get_context", args, state) do
    context_token = Map.get(args, "context_token")
    resource_uri = Map.get(args, "resource_uri")
    scene_id = Map.get(args, "scene_id", "default")
    
    cond do
      resource_uri != nil ->
        # Parse resource URI to get scene_id
        case parse_scene_uri(resource_uri) do
          {:ok, sid} ->
            # Get context by scene_id from URI
            case BpyMcp.set_context(sid) do
              {:ok, pid} ->
                scene_id_from_pid = Context.get_scene_id(pid)
                case Context.encode_context_token(pid, %{scene_id: scene_id_from_pid, operation_count: 0}) do
                  {:ok, token} ->
                    info = %{
                      resource_uri: resource_uri,
                      scene_id: scene_id_from_pid,
                      context_token: token,
                      pid: :erlang.pid_to_list(pid) |> List.to_string(),
                      status: "active"
                    }
                    {:ok, %{content: [text_content("Context info from resource: #{Jason.encode!(info)}")]}, state}
                  
                  {:error, reason} ->
                    {:error, "Failed to encode context token: #{reason}", state}
                end
              
              {:error, reason} ->
                {:error, "Failed to get context from resource URI: #{reason}", state}
            end
          
          {:error, reason} ->
            {:error, "Invalid resource URI: #{reason}", state}
        end
      
      context_token != nil ->
        # Decode token to get context info
        case Context.decode_context_token(context_token) do
          {:ok, %{pid: pid, metadata: metadata}} ->
            if Process.alive?(pid) do
              scene_id_from_pid = Context.get_scene_id(pid)
              info = %{
                scene_id: scene_id_from_pid,
                pid: :erlang.pid_to_list(pid) |> List.to_string(),
                metadata: metadata,
                status: "active"
              }
              {:ok, %{content: [text_content("Context info: #{Jason.encode!(info)}")]}, state}
            else
              {:error, "Context token refers to a dead process", state}
            end
          
          {:error, reason} ->
            {:error, "Failed to decode context token: #{reason}", state}
        end
      
      true ->
        # Get context by scene_id
        case BpyMcp.set_context(scene_id) do
          {:ok, pid} ->
            scene_id_from_pid = Context.get_scene_id(pid)
            case Context.encode_context_token(pid, %{scene_id: scene_id_from_pid, operation_count: 0}) do
              {:ok, token} ->
                info = %{
                  scene_id: scene_id_from_pid,
                  context_token: token,
                  pid: :erlang.pid_to_list(pid) |> List.to_string(),
                  status: "active"
                }
                {:ok, %{content: [text_content("Context info: #{Jason.encode!(info)}")]}, state}
              
              {:error, reason} ->
                {:error, "Failed to encode context token: #{reason}", state}
            end
          
          {:error, reason} ->
            {:error, "Failed to get context: #{reason}", state}
        end
    end
  end

  @impl true
  def handle_tool_call("get_context_token", args, state) do
    resource_uri = Map.get(args, "resource_uri")
    scene_id = Map.get(args, "scene_id", "default")
    
    # Determine scene_id from resource_uri or use provided scene_id
    target_scene_id = 
      if resource_uri do
        case parse_scene_uri(resource_uri) do
          {:ok, sid} -> {:ok, sid}
          error -> error
        end
      else
        {:ok, scene_id}
      end
    
    case target_scene_id do
      {:ok, sid} ->
        case BpyMcp.set_context(sid) do
          {:ok, pid} ->
            scene_id_actual = Context.get_scene_id(pid)
            case Context.encode_context_token(pid, %{scene_id: scene_id_actual, operation_count: 0}) do
              {:ok, token} ->
                info = %{
                  resource_uri: if(resource_uri, do: resource_uri, else: "blender://scene/#{sid}"),
                  scene_id: scene_id_actual,
                  context_token: token,
                  usage: "Use this context_token in other tools (create_cube, create_sphere, etc.) to operate on this scene"
                }
                {:ok, %{content: [text_content("Context token for scene: #{Jason.encode!(info)}")]}, state}
              
              {:error, reason} ->
                {:error, "Failed to generate context token: #{reason}", state}
            end
          
          {:error, reason} ->
            {:error, "Failed to get context: #{reason}", state}
        end
      
      {:error, reason} ->
        {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("list_contexts", _args, state) do
    case BpyMcp.list_contexts() do
      {:ok, contexts} ->
        # Format contexts for display
        formatted_contexts =
          Enum.map(contexts, fn %{scene_id: scene_id, pid: pid, operation_count: op_count} ->
            %{
              scene_id: scene_id,
              pid: :erlang.pid_to_list(pid) |> List.to_string(),
              operation_count: op_count,
              status: if(Process.alive?(pid), do: "active", else: "dead")
            }
          end)
        
        {:ok, %{content: [text_content("Active contexts: #{Jason.encode!(formatted_contexts)}")]}, state}
      
      {:error, reason} ->
        {:error, "Failed to list contexts: #{reason}", state}
    end
  end

  @impl true
  def handle_tool_call("stop_context", args, state) do
    context_token = Map.get(args, "context_token")
    scene_id = Map.get(args, "scene_id", "default")
    
    # Determine which scene to stop
    target_scene_id = 
      if context_token do
        case Context.decode_context_token(context_token) do
          {:ok, %{pid: pid, metadata: _metadata}} ->
            if Process.alive?(pid) do
              Context.get_scene_id(pid)
            else
              {:error, "Context token refers to a dead process"}
            end
          
          {:error, reason} ->
            {:error, "Failed to decode context token: #{reason}"}
        end
      else
        {:ok, scene_id}
      end
    
    case target_scene_id do
      {:ok, sid} ->
        # Stop the context by terminating its process
        case Registry.lookup(BpyMcp.SceneRegistry, sid) do
          [{pid, _}] ->
            if Process.alive?(pid) do
              # Stop the process via DynamicSupervisor
              case DynamicSupervisor.terminate_child(BpyMcp.SceneSupervisor, pid) do
                :ok ->
                  {:ok, %{content: [text_content("Context stopped successfully: #{sid}")]}, state}
                
                {:error, :not_found} ->
                  # Process already gone, remove from registry if possible
                  {:ok, %{content: [text_content("Context already stopped: #{sid}")]}, state}
                
                {:error, reason} ->
                  {:error, "Failed to stop context: #{inspect(reason)}", state}
              end
            else
              {:ok, %{content: [text_content("Context already stopped (process dead): #{sid}")]}, state}
            end
          
          [] ->
            {:error, "Context not found: #{sid}", state}
        end
      
      {:error, reason} ->
        {:error, reason, state}
    end
  end



  # Fallback for unknown tools
  @impl true
  def handle_tool_call(tool_name, _args, state) do
    {:error, "Tool not found: #{tool_name}", state}
  end

  # Helper functions for resource handling

  defp parse_scene_uri("blender://scene/" <> scene_id) when scene_id != "" do
    {:ok, scene_id}
  end
  defp parse_scene_uri(_uri), do: {:error, "Invalid URI format. Expected: blender://scene/{scene_id}"}

  # Store scene to AriaStorage for persistence
  defp store_scene_to_aria_storage(scene_id, scene_data) do
    case ResourceStorage.store_scene_resource(scene_id, scene_data, 
      format: :json, 
      compression: :zstd
    ) do
      {:ok, storage_ref} ->
        {:ok, storage_ref}
      
      {:error, reason} ->
        # Log error but don't fail the request
        {:error, reason}
    end
  end

  defp get_scene_resource(scene_id) do
    case Registry.lookup(BpyMcp.SceneRegistry, scene_id) do
      [{pid, _}] ->
        if Process.alive?(pid) do
          # Get scene info from the scene manager
          scene_id_actual = Context.get_scene_id(pid)
          
          # Try to get scene info via BpyTools
          # First, get or create a temp dir for this context
          temp_dir = Context.create_temp_dir()
          
          # Generate context token for this scene
          context_token = 
            case Context.encode_context_token(pid, %{scene_id: scene_id_actual, operation_count: 0}) do
              {:ok, token} -> token
              _ -> nil
            end
          
          case BpyMcp.BpyTools.get_scene_info(temp_dir) do
            {:ok, scene_info} ->
              # Combine scene manager info with Blender scene info
              resource_data = %{
                scene_id: scene_id_actual,
                pid: :erlang.pid_to_list(pid) |> List.to_string(),
                status: "active",
                context_token: context_token,
                scene_info: scene_info
              }
              
              # Store to AriaStorage for persistence (async, don't wait)
              Task.start(fn ->
                store_scene_to_aria_storage(scene_id_actual, resource_data)
              end)
              
              {:ok, resource_data}
            
            {:error, _reason} ->
              # Fallback to basic info if Blender query fails
              resource_data = %{
                scene_id: scene_id_actual,
                pid: :erlang.pid_to_list(pid) |> List.to_string(),
                status: "active",
                context_token: context_token,
                note: "Scene exists but detailed info unavailable"
              }
              
              # Store to AriaStorage for persistence (async, don't wait)
              Task.start(fn ->
                store_scene_to_aria_storage(scene_id_actual, resource_data)
              end)
              
              {:ok, resource_data}
          end
        else
          {:error, "Scene context process is not alive"}
        end
      
      [] ->
        {:error, "Scene not found: #{scene_id}"}
    end
  end
end
