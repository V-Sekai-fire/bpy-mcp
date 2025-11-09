# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Mesh.Import do
  @moduledoc """
  Mesh import functionality using OpenMesh internal format.
  """

  alias BpyMcp.Tools.Utils

  @type result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Imports mesh data from OpenMesh format (internal data structure).
  Takes JSON representation of OpenMesh mesh data and creates Blender mesh objects.
  """
  @spec import_openmesh(String.t(), String.t()) :: result()
  def import_openmesh(openmesh_json, temp_dir) do
    :ok = Utils.ensure_pythonx()
    import_openmesh_bpy(openmesh_json, temp_dir)
  end

  defp import_openmesh_bpy(openmesh_json, temp_dir) do
    try do
      code = """
      import bpy
      import openmesh as om
      import json

      # Parse OpenMesh JSON data
      try:
          data = json.loads('''#{openmesh_json}''')
      except json.JSONDecodeError as e:
          result = f"Failed to parse JSON: {str(e)}"
          print(result)
          result

      if data.get("format") != "openmesh_internal":
          result = "Invalid format: expected 'openmesh_internal', got '{}'".format(data.get("format", "unknown"))
          print(result)
          result
      else:
          imported_count = 0
          results = []

          for mesh_data in data.get("meshes", []):
              mesh_name = mesh_data.get("name", "ImportedMesh")

              # Clear existing mesh if it exists
              if mesh_name in bpy.data.objects:
                  bpy.data.objects.remove(bpy.data.objects[mesh_name], do_unlink=True)
              if mesh_name in bpy.data.meshes:
                  bpy.data.meshes.remove(bpy.data.meshes[mesh_name])

              # Create OpenMesh PolyMesh from data
              om_mesh = om.PolyMesh()

              # Add vertices
              vertex_handles = []
              for vert_coords in mesh_data.get("vertices", []):
                  vh = om_mesh.add_vertex(om.Vec3d(vert_coords[0], vert_coords[1], vert_coords[2]))
                  vertex_handles.append(vh)

              # Add faces (preserves n-gons)
              for face_verts in mesh_data.get("faces", []):
                  face_vhs = [vertex_handles[idx] for idx in face_verts if idx < len(vertex_handles)]
                  if len(face_vhs) >= 3:  # Need at least 3 vertices for a face
                      try:
                          om_mesh.add_face(face_vhs)
                      except:
                          pass

              # Create Blender mesh from OpenMesh
              # Create new mesh
              bmesh = bpy.data.meshes.new(name=mesh_name)

              # Add vertices to Blender mesh (use original vertex order from data)
              bmesh_vertices = []
              for vert_coords in mesh_data.get("vertices", []):
                  bmesh_vertices.append((vert_coords[0], vert_coords[1], vert_coords[2]))

              # Use faces directly from OpenMesh data (preserves n-gons and loop order)
              bmesh_faces = []
              for face_verts in mesh_data.get("faces", []):
                  # Filter valid vertex indices
                  valid_face = [idx for idx in face_verts if 0 <= idx < len(bmesh_vertices)]
                  if len(valid_face) >= 3:  # Need at least 3 vertices for a face
                      bmesh_faces.append(valid_face)

              # Create mesh with vertices and faces
              bmesh.from_pydata(bmesh_vertices, [], bmesh_faces)

              # Update mesh
              bmesh.update()

              # Create object and link to scene
              obj = bpy.data.objects.new(mesh_name, bmesh)
              bpy.context.collection.objects.link(obj)

              # Make active
              bpy.context.view_layer.objects.active = obj
              obj.select_set(True)

              imported_count += 1
              results.append(f"Imported mesh '{mesh_name}' with {len(bmesh_vertices)} vertices and {len(bmesh_faces)} faces")

          result = f"Successfully imported {imported_count} mesh(es).\\n" + "\\n".join(results)
          print(result)
          result
      """

      result = Pythonx.eval(code, %{"working_directory" => temp_dir})
      {:ok, result}
    rescue
      e ->
        {:error, "Failed to import OpenMesh format: #{inspect(e)}"}
    end
  end
end
