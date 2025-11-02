# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyMesh do
  @moduledoc """
  Blender BMesh export functionality for EXT_mesh_bmesh format.
  """

  require Logger

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Exports the current Blender scene as BMesh data in EXT_mesh_bmesh format.

  ## Returns
    - `{:ok, map()}` - BMesh scene data
    - `{:error, String.t()}` - Error message
  """
  @spec export_bmesh_scene(String.t()) :: bpy_result()
  def export_bmesh_scene(temp_dir) do
    case ensure_pythonx() do
      :ok ->
        do_export_bmesh_scene(temp_dir)

      :mock ->
        mock_export_bmesh_scene()
    end
  end

  @doc false
  def test_mock_export_bmesh_scene(), do: mock_export_bmesh_scene()

  defp mock_export_bmesh_scene do
    {:ok,
     %{
       "meshes" => [
         %{
           "name" => "MockCube",
           "primitives" => [
             %{
               "extensions" => %{
                 "EXT_mesh_bmesh" => %{
                   "vertices" => %{
                     "count" => 8,
                     "positions" => [
                       [-1, -1, -1],
                       [1, -1, -1],
                       [1, 1, -1],
                       [-1, 1, -1],
                       [-1, -1, 1],
                       [1, -1, 1],
                       [1, 1, 1],
                       [-1, 1, 1]
                     ]
                   },
                   "edges" => %{
                     "count" => 12,
                     "vertices" => [0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7]
                   },
                   "loops" => %{
                     "count" => 24,
                     "topology_vertex" => [0, 1, 2, 3, 4, 7, 6, 5, 0, 3, 7, 4, 1, 5, 6, 2, 0, 4, 5, 1, 3, 2, 6, 7],
                     "topology_edge" => [
                       0, 1, 2, 3, 8, 11, 10, 9, 4, 7, 6, 5, 12, 15, 14, 13, 16, 17, 18, 19, 20, 21, 22, 23
                     ],
                     "topology_face" => [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5],
                     "topology_next" => [1, 2, 3, 0, 5, 6, 7, 4, 9, 10, 11, 8, 13, 14, 15, 12, 17, 18, 19, 16, 21, 22, 23, 20],
                     "topology_prev" => [3, 0, 1, 2, 7, 4, 5, 6, 11, 8, 9, 10, 15, 12, 13, 14, 19, 16, 17, 18, 23, 20, 21, 22],
                     "topology_radial_next" => [4, 8, 12, 16, 0, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92],
                     "topology_radial_prev" => [16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 0, 4, 8, 12, 64, 68, 72, 76, 80, 84, 88, 92]
                   },
                   "faces" => %{
                     "count" => 6,
                     "vertices" => [0, 1, 2, 3, 4, 7, 6, 5, 0, 3, 7, 4, 1, 5, 6, 2, 0, 4, 5, 1, 3, 2, 6, 7],
                     "offsets" => [0, 4, 8, 12, 16, 20, 24]
                   }
                 }
               }
             }
           ]
         }
       ],
       "nodes" => [
         %{
           "name" => "MockCube",
           "mesh" => 0,
           "translation" => [0, 0, 0],
           "rotation" => [0, 0, 0, 1],
           "scale" => [1, 1, 1]
         }
       ]
     }}
  end

  defp do_export_bmesh_scene(temp_dir) do
    code = """
import bpy
import bmesh

# Get all mesh objects in the scene
mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']

meshes = []
nodes = []

for i, obj in enumerate(mesh_objects):
    # Create BMesh from object
    bm = bmesh.new()
    bm.from_mesh(obj.data)

    # Ensure BMesh is in consistent state
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.verts.ensure_lookup_table()
    bm.edges.ensure_lookup_table()
    bm.faces.ensure_lookup_table()

    # Extract vertices
    vertices = []
    for vert in bm.verts:
        # Convert to object space (local coordinates)
        vertices.append([vert.co.x, vert.co.y, vert.co.z])

    # Extract edges - vertex pairs
    edge_vertices = []
    for edge in bm.edges:
        edge_vertices.extend([edge.verts[0].index, edge.verts[1].index])

    # Build edge adjacency data (which faces use each edge)
    edge_faces = []
    edge_faces_offsets = [0]
    for edge in bm.edges:
        # Find all faces that use this edge
        connected_faces = []
        for face in edge.link_faces:
            connected_faces.append(face.index)
        edge_faces.extend(connected_faces)
        edge_faces_offsets.append(len(edge_faces))

    # Extract complete loop topology
    loop_vertex_indices = []
    loop_edge_indices = []
    loop_face_indices = []
    loop_next_indices = []
    loop_prev_indices = []
    loop_radial_next_indices = []
    loop_radial_prev_indices = []

    # Build radial navigation map for edges
    edge_loop_map = {}
    for edge in bm.edges:
        edge_loop_map[edge.index] = []
        for loop in edge.link_loops:
            edge_loop_map[edge.index].append(loop.index)

    loop_index = 0
    for face in bm.faces:
        face_loop_start = loop_index
        face_loop_count = len(face.loops)

        for j, loop in enumerate(face.loops):
            loop_vertex_indices.append(loop.vert.index)
            loop_edge_indices.append(loop.edge.index)
            loop_face_indices.append(face.index)

            # Next/prev within face
            next_idx = face_loop_start + (j + 1) % face_loop_count
            prev_idx = face_loop_start + (j - 1) % face_loop_count
            loop_next_indices.append(next_idx)
            loop_prev_indices.append(prev_idx)

            # Radial navigation around edge
            edge_loops = edge_loop_map[loop.edge.index]
            current_pos = edge_loops.index(loop.index)

            # Find next loop around this edge
            radial_next_pos = (current_pos + 1) % len(edge_loops)
            radial_prev_pos = (current_pos - 1) % len(edge_loops)

            loop_radial_next_indices.append(edge_loops[radial_next_pos])
            loop_radial_prev_indices.append(edge_loops[radial_prev_pos])

            loop_index += 1

    # Extract face data
    face_vertices = []
    face_edges = []
    face_loops = []
    face_offsets = [0]
    face_normals = []

    for face in bm.faces:
        # Face vertices
        face_vertices.extend([vert.index for vert in face.verts])

        # Face edges
        face_edges.extend([edge.index for edge in face.edges])

        # Face loops
        face_loops.extend([loop.index for loop in face.loops])

        face_offsets.append(len(face_vertices))

        # Face normal
        face_normals.extend([face.normal.x, face.normal.y, face.normal.z])

    # Create mesh data in EXT_mesh_bmesh format
    mesh_data = {
        "name": obj.name,
        "primitives": [{
            "extensions": {
                "EXT_mesh_bmesh": {
                    "vertices": {
                        "count": len(vertices),
                        "positions": vertices
                    },
                    "edges": {
                        "count": len(bm.edges),
                        "vertices": edge_vertices,
                        "faces": edge_faces,
                        "offsets": edge_faces_offsets
                    },
                    "loops": {
                        "count": len(loop_vertex_indices),
                        "topology_vertex": loop_vertex_indices,
                        "topology_edge": loop_edge_indices,
                        "topology_face": loop_face_indices,
                        "topology_next": loop_next_indices,
                        "topology_prev": loop_prev_indices,
                        "topology_radial_next": loop_radial_next_indices,
                        "topology_radial_prev": loop_radial_prev_indices
                    },
                    "faces": {
                        "count": len(bm.faces),
                        "vertices": face_vertices,
                        "edges": face_edges,
                        "loops": face_loops,
                        "offsets": face_offsets,
                        "normals": face_normals
                    }
                }
            }
        }]
    }

    meshes.append(mesh_data)

    # Extract transform
    translation = [obj.location.x, obj.location.y, obj.location.z]
    rotation = [obj.rotation_quaternion.x, obj.rotation_quaternion.y, obj.rotation_quaternion.z, obj.rotation_quaternion.w]
    scale = [obj.scale.x, obj.scale.y, obj.scale.z]

    node_data = {
        "name": obj.name,
        "mesh": i,
        "translation": translation,
        "rotation": rotation,
        "scale": scale
    }

    nodes.append(node_data)

    # Clean up
    bm.free()

result = {
    "meshes": meshes,
    "nodes": nodes
}
result
"""

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_map(result) -> {:ok, result}
          _ -> {:error, "Failed to decode BMesh export result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  # Import helper functions from BpyTools
  defp ensure_pythonx do
    # Force mock mode during testing to avoid Blender initialization
    if Application.get_env(:bpy_mcp, :force_mock, false) or System.get_env("MIX_ENV") == "test" do
      :mock
    else
      case Application.ensure_all_started(:pythonx) do
        {:error, _reason} ->
          :mock

        {:ok, _} ->
          check_pythonx_availability()
      end
    end
  rescue
    _ -> :mock
  end

  defp check_pythonx_availability do
    # In test mode, never try to execute Python code
    if Mix.env() == :test do
      :mock
    else
      # Test if both Pythonx works and bpy is available
      # Redirect stderr to prevent EGL errors from corrupting stdio
      try do
        code = """
        import bpy
        result = bpy.context.scene is not None
        result
        """

        # Use /dev/null to suppress Blender's output from corrupting stdio
        null_device = File.open!("/dev/null", [:write])
        case Pythonx.eval(code, %{}, stdout_device: null_device, stderr_device: null_device) do
          {result, _globals} ->
            case Pythonx.decode(result) do
              true -> :ok
              _ -> :mock
            end

          _ ->
            :mock
        end
      rescue
        _ -> :mock
      end
    end
  end
end
