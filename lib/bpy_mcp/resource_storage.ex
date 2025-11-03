# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.ResourceStorage do
  @moduledoc """
  Resource storage for Blender scenes using AriaStorage.
  
  This module provides persistent storage for Blender scene resources,
  allowing scenes to be saved, retrieved, and managed as resources.
  """

  @doc """
  Store a Blender scene resource using AriaStorage.
  
  ## Parameters
  - `scene_id`: Unique identifier for the scene
  - `scene_data`: Scene data (can be JSON, BMesh, or file path)
  - `options`: Storage options
    - `:format`: Data format (:json, :bmesh, :file)
    - `:compression`: Compression algorithm (:zstd, :none)
  
  ## Returns
  - `{:ok, storage_ref}` - Storage reference for the scene
  - `{:error, reason}` - Error if storage fails
  """
  @spec store_scene_resource(String.t(), binary() | map() | String.t(), keyword()) :: 
    {:ok, String.t()} | {:error, String.t()}
  def store_scene_resource(scene_id, scene_data, options \\ []) do
    format = Keyword.get(options, :format, :json)
    compression = Keyword.get(options, :compression, :zstd)
    
    # Prepare data for storage
    data_to_store = case format do
      :json when is_map(scene_data) ->
        Jason.encode!(scene_data)
      
      :json when is_binary(scene_data) ->
        scene_data
      
      :file when is_binary(scene_data) ->
        case File.read(scene_data) do
          {:ok, data} -> data
          {:error, reason} -> {:error, "Failed to read file: #{reason}"}
        end
      
      _ ->
        {:error, "Unsupported format: #{format}"}
    end
    
    case data_to_store do
      {:error, reason} ->
        {:error, reason}
      
      data when is_binary(data) ->
        # Create temporary file for AriaStorage
        temp_file = create_temp_file(scene_id, data)
        
        # Store using AriaStorage with chunking
        case AriaStorage.process_file(temp_file, 
          backend: :local,
          compression: compression,
          chunk_options: [avg_size: 64 * 1024]
        ) do
          {:ok, %{chunks: _chunks, index: _index, storage_result: storage_result}} ->
            # Clean up temp file
            File.rm(temp_file)
            
            # Store metadata linking scene_id to storage_ref
            _storage_ref = Map.get(storage_result, :chunk_id) || 
              Map.get(storage_result, :file_ref) || 
              "#{scene_id}_#{System.unique_integer([:positive])}"
            
            # Return scene_id as the storage reference for easier lookup
            {:ok, scene_id}
          
          {:error, reason} ->
            File.rm(temp_file)
            {:error, "AriaStorage failed: #{inspect(reason)}"}
        end
      
      _ ->
        {:error, "Invalid data format"}
    end
  end

  @doc """
  Retrieve a stored Blender scene resource.
  
  ## Parameters
  - `storage_ref`: Storage reference from store_scene_resource
  - `options`: Retrieval options
    - `:format`: Desired format (:json, :binary)
  
  ## Returns
  - `{:ok, data}` - Scene data
  - `{:error, reason}` - Error if retrieval fails
  """
  @spec get_scene_resource(String.t(), keyword()) :: 
    {:ok, binary() | map()} | {:error, String.t()}
  def get_scene_resource(storage_ref, options \\ []) do
    format = Keyword.get(options, :format, :json)
    
    case AriaStorage.get_file(storage_ref) do
      {:ok, data} ->
        case format do
          :json ->
            case Jason.decode(data) do
              {:ok, json} -> {:ok, json}
              _ -> {:ok, data}
            end
          
          :binary ->
            {:ok, data}
        end
      
      {:error, reason} ->
        {:error, "Failed to retrieve resource: #{inspect(reason)}"}
    end
  end

  @doc """
  List all stored scene resources.
  
  ## Parameters
  - `options`: List options
    - `:limit`: Maximum number of resources to return
  
  ## Returns
  - `{:ok, [resources]}` - List of storage references
  - `{:error, reason}` - Error if listing fails
  """
  @spec list_scene_resources(keyword()) :: 
    {:ok, list(String.t())} | {:error, String.t()}
  def list_scene_resources(options \\ []) do
    limit = Keyword.get(options, :limit, 100)
    
    case AriaStorage.list_files(limit: limit) do
      {:ok, files} ->
        refs = Enum.map(files, fn file ->
          Map.get(file, :chunk_id) || Map.get(file, :file_ref) || Map.get(file, :id) || 
          Map.get(file, "chunk_id") || Map.get(file, "file_ref") || Map.get(file, "id")
        end)
        {:ok, refs}
      
      {:error, reason} ->
        {:error, "Failed to list resources: #{inspect(reason)}"}
    end
  end

  @doc """
  Delete a stored scene resource.
  
  ## Parameters
  - `storage_ref`: Storage reference to delete
  
  ## Returns
  - `:ok` - Resource deleted
  - `{:error, reason}` - Error if deletion fails
  """
  @spec delete_scene_resource(String.t()) :: :ok | {:error, String.t()}
  def delete_scene_resource(_storage_ref) do
    # AriaStorage doesn't have a direct delete API in the main module
    # This would need to be implemented based on the chunk store being used
    {:error, "Delete not yet implemented - requires chunk store access"}
  end

  # Private helpers

  defp create_temp_file(scene_id, data) do
    temp_dir = System.tmp_dir!()
    filename = "bpy_scene_#{scene_id}_#{System.unique_integer([:positive])}.json"
    temp_path = Path.join(temp_dir, filename)
    
    case File.write(temp_path, data) do
      :ok -> temp_path
      {:error, reason} -> {:error, "Failed to create temp file: #{reason}"}
    end
  end
end

