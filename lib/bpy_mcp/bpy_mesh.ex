# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyMesh do
  @moduledoc """
  Blender BMesh export/import functionality for EXT_mesh_bmesh format.

  This module provides high-level functions for BMesh operations, delegating
  to specialized submodules for specific functionality.
  """

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Exports BMesh data as JSON using a simple DSL.

  ## Examples

      # Export everything as JSON
      BpyMcp.BpyMesh.export_json(temp_dir)

      # Export with options
      BpyMcp.BpyMesh.export_json(temp_dir, %{include_normals: true})

  ## Returns
    - `{:ok, String.t()}` - JSON string of BMesh data
    - `{:error, String.t()}` - Error message
  """
  @spec export_json(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def export_json(temp_dir, opts \\ %{}) do
    BpyMcp.BMesh.Export.export_json(temp_dir, opts)
  end

  @doc """
  Exports the current Blender scene as complete glTF 2.0 JSON with EXT_mesh_bmesh extension.

  ## Returns
    - `{:ok, map()}` - Complete glTF 2.0 JSON data
    - `{:error, String.t()}` - Error message
  """
  @spec export_bmesh_scene(String.t()) :: bpy_result()
  def export_bmesh_scene(temp_dir) do
    BpyMcp.BMesh.Export.export_gltf_scene(temp_dir)
  end

  @doc """
  Imports BMesh data from glTF JSON with EXT_mesh_bmesh extension.

  ## Parameters
    - gltf_json: String containing glTF JSON data with EXT_mesh_bmesh extension
    - temp_dir: Temporary directory for context

  ## Returns
    - `{:ok, String.t()}` - Success message with import details
    - `{:error, String.t()}` - Error message
  """
  @spec import_bmesh_scene(String.t(), String.t()) :: bpy_result()
  def import_bmesh_scene(gltf_json, temp_dir) do
    BpyMcp.BMesh.Import.import_gltf_scene(gltf_json, temp_dir)
  end

  @doc false
  def test_mock_export_bmesh_scene(), do: BpyMcp.BMesh.Mock.export_gltf_scene()

  @doc false
  def test_reconstruct_vertices_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    BpyMcp.BMesh.Binary.reconstruct_vertices_from_accessors(ext_bmesh, accessors, bufferViews, buffers)
  end

  @doc false
  def test_reconstruct_edges_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    BpyMcp.BMesh.Binary.reconstruct_edges_from_accessors(ext_bmesh, accessors, bufferViews, buffers)
  end

  @doc false
  def test_reconstruct_faces_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    BpyMcp.BMesh.Binary.reconstruct_faces_from_accessors(ext_bmesh, accessors, bufferViews, buffers)
  end

  @doc false
  def ensure_pythonx do
    BpyMcp.BMesh.ensure_pythonx()
  end
end
