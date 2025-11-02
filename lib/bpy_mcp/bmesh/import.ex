# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BMesh.Import do
  @moduledoc """
  BMesh import functionality for glTF with EXT_mesh_bmesh extension.
  """

  require Logger

  @type import_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Imports BMesh data from glTF JSON with EXT_mesh_bmesh extension.
  """
  @spec import_gltf_scene(String.t()) :: BpyMcp.BpyMesh.bpy_result()
  def import_gltf_scene(gltf_json) do
    case BpyMcp.BMesh.ensure_pythonx() do
      :ok ->
        do_import_gltf_scene(gltf_json)

      :mock ->
        BpyMcp.BMesh.Mock.import_gltf_scene(gltf_json)
    end
  end

  # Real Blender import implementation
  defp do_import_gltf_scene(gltf_json) do
    code = """
import bpy
import bmesh
import base64
import json
import struct

# Parse glTF JSON
gltf_data = json.loads(gltf_json)
meshes = gltf_data.get('meshes', [])
imported_count = 0

for mesh_data in meshes:
    name = mesh_data.get('name', 'ImportedMesh')
    primitives = mesh_data.get('primitives', [])

    for primitive in primitives:
        ext_bmesh = primitive.get('extensions', {}).get('EXT_mesh_bmesh')
        if not ext_bmesh:
            continue

        # Create new mesh and object
        mesh = bpy.data.meshes.new(name)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)

        # Get BMesh topology data
        vertices_data = ext_bmesh['vertices']
        edges_data = ext_bmesh['edges']
        faces_data = ext_bmesh['faces']
        loops_data = ext_bmesh['loops']

        # Extract vertex positions
        vertex_positions = vertices_data['positions']

        # Create BMesh
        bm = bmesh.new()

        # Add vertices
        for pos in vertex_positions:
            bm.verts.new(pos)
        bm.verts.ensure_lookup_table()

        # Add edges
        edge_vertices = edges_data['vertices']
        for i in range(0, len(edge_vertices), 2):
            v1_idx = edge_vertices[i]
            v2_idx = edge_vertices[i + 1]
            v1 = bm.verts[v1_idx]
            v2 = bm.verts[v2_idx]
            bm.edges.new([v1, v2])
        bm.edges.ensure_lookup_table()

        # Add faces
        face_vertices = faces_data['vertices']
        face_offsets = faces_data.get('offsets', [0])

        face_start = 0
        for face_end in face_offsets[1:]:
            face_vert_indices = face_vertices[face_start:face_end]
            face_verts = [bm.verts[i] for i in face_vert_indices]
            bm.faces.new(face_verts)
            face_start = face_end
        bm.faces.ensure_lookup_table()

        # Load BMesh into mesh
        bm.to_mesh(mesh)
        bm.free()

        imported_count += 1

result = f"Imported {imported_count} meshes with BMesh topology"
result
"""

    case Pythonx.eval(code, %{"gltf_json" => gltf_json}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode import result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end
end
