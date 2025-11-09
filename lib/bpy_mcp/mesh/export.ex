# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Mesh.Export do
  @moduledoc """
  Mesh export functionality using OpenMesh internal format.
  """

  alias BpyMcp.Tools.Utils

  @type result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Exports the current scene as OpenMesh format (internal data structure).
  Returns JSON representation of OpenMesh mesh data.
  """
  @spec export_openmesh(String.t()) :: result()
  def export_openmesh(temp_dir) do
    :ok = Utils.ensure_pythonx()
    export_openmesh_bpy(temp_dir)
  end

  defp export_openmesh_bpy(temp_dir) do
    try do
      code = """
      import bpy
      import openmesh as om
      import json

      # Collect all mesh objects
      mesh_data = []

      for obj in bpy.context.scene.objects:
          if obj.type == 'MESH' and obj.data:
              mesh = obj.data

              # Create OpenMesh PolyMesh to support n-gons
              om_mesh = om.PolyMesh()

              # Build vertex handle mapping
              vertex_handles = {}
              for i, vert in enumerate(mesh.vertices):
                  vh = om_mesh.add_vertex(om.Vec3d(vert.co.x, vert.co.y, vert.co.z))
                  vertex_handles[i] = vh

              # Add faces preserving original topology (n-gons, loops, etc.)
              # Work with original faces, not triangulated
              for face in mesh.polygons:
                  # Get vertex handles for this face
                  face_vertex_handles = []
                  for loop_idx in face.loop_indices:
                      vert_idx = mesh.loops[loop_idx].vertex_index
                      face_vertex_handles.append(vertex_handles[vert_idx])

                  # Add face with all vertices (preserves n-gons)
                  try:
                      om_mesh.add_face(face_vertex_handles)
                  except:
                      pass

              # Extract OpenMesh internal data structure
              # Vertices (points)
              om_vertices = []
              vertex_idx_map = {}
              for idx, vh in enumerate(om_mesh.vertices()):
                  point = om_mesh.point(vh)
                  om_vertices.append([float(point[0]), float(point[1]), float(point[2])])
                  vertex_idx_map[vh.idx()] = idx

              # Faces (as vertex indices) - preserves n-gons
              om_faces = []
              for fh in om_mesh.faces():
                  face_verts = []
                  # Iterate through vertices of face (preserves loop order)
                  for vh in om_mesh.fv(fh):
                      face_verts.append(vertex_idx_map[vh.idx()])
                  om_faces.append(face_verts)

              # Loop data (Blender's loop structure - vertex/edge/face connectivity)
              om_loops = []
              for fh in om_mesh.faces():
                  face_loops = []
                  # Get halfedges of face (represents loops)
                  for heh in om_mesh.fh(fh):
                      from_vh = om_mesh.from_vertex_handle(heh)
                      to_vh = om_mesh.to_vertex_handle(heh)
                      face_loops.append({
                          "vertex": vertex_idx_map[from_vh.idx()],
                          "next_vertex": vertex_idx_map[to_vh.idx()],
                          "halfedge": heh.idx()
                      })
                  om_loops.append(face_loops)

              # Halfedge connectivity (OpenMesh's internal structure)
              om_halfedges = []
              halfedge_idx_map = {}
              for idx, heh in enumerate(om_mesh.halfedges()):
                  from_vh = om_mesh.from_vertex_handle(heh)
                  to_vh = om_mesh.to_vertex_handle(heh)

                  halfedge_data = {
                      "from_vertex": vertex_idx_map[from_vh.idx()],
                      "to_vertex": vertex_idx_map[to_vh.idx()],
                      "is_boundary": om_mesh.is_boundary(heh)
                  }

                  # Get face if not boundary
                  if not om_mesh.is_boundary(heh):
                      fh = om_mesh.face_handle(heh)
                      # Find face index
                      face_idx = None
                      for i, f in enumerate(om_mesh.faces()):
                          if f.idx() == fh.idx():
                              face_idx = i
                              break
                      halfedge_data["face"] = face_idx
                  else:
                      halfedge_data["face"] = None

                  # Get next halfedge
                  next_heh = om_mesh.next_halfedge_handle(heh)
                  halfedge_data["next"] = next_heh.idx() if next_heh.is_valid() else None

                  # Get opposite halfedge
                  opp_heh = om_mesh.opposite_halfedge_handle(heh)
                  halfedge_data["opposite"] = opp_heh.idx() if opp_heh.is_valid() else None

                  om_halfedges.append(halfedge_data)
                  halfedge_idx_map[heh.idx()] = idx

              # Edge data
              om_edges = []
              for eh in om_mesh.edges():
                  h0 = om_mesh.halfedge_handle(eh, 0)
                  h1 = om_mesh.halfedge_handle(eh, 1)
                  om_edges.append({
                      "halfedge0": h0.idx() if h0.is_valid() else None,
                      "halfedge1": h1.idx() if h1.is_valid() else None
                  })

              mesh_info = {
                  "name": obj.name,
                  "vertices": om_vertices,
                  "faces": om_faces,
                  "loops": om_loops,
                  "halfedges": om_halfedges,
                  "edges": om_edges,
                  "vertex_count": om_mesh.n_vertices(),
                  "face_count": om_mesh.n_faces(),
                  "halfedge_count": om_mesh.n_halfedges(),
                  "edge_count": om_mesh.n_edges(),
                  "preserves_ngons": True
              }

              mesh_data.append(mesh_info)

      result = {
          "format": "openmesh_internal",
          "version": "1.0",
          "mesh_count": len(mesh_data),
          "meshes": mesh_data
      }

      json.dumps(result, indent=2)
      """

      result_json = Pythonx.eval(code, %{"working_directory" => temp_dir})
      {:ok, result_json}
    rescue
      e ->
        {:error, "Failed to export OpenMesh format: #{inspect(e)}"}
    end
  end
end
