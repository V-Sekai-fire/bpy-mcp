# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Tools.Introspection do
  @moduledoc """
  Introspection tools for examining APIs (read-only, metadata only).
  """

  alias BpyMcp.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Introspects structure for debugging and understanding API.
  Metadata only - no property access, no side effects.
  """
  @spec introspect_blender(String.t(), String.t()) :: result()
  def introspect_blender(object_path \\ "bpy", temp_dir) do
    :ok = Utils.ensure_pythonx()
    introspect_blender_bpy(object_path, temp_dir)
  end

  defp introspect_blender_bpy(object_path, _temp_dir) do
    try do
      # Escape the object path for safety
      safe_path = String.replace(object_path, ~r/[^a-zA-Z0-9._]/, "")

      code = """
      import bpy
      import inspect
      import json

      # Safely evaluate the object path
      try:
          obj = eval("#{safe_path}")

          # Get type information
          obj_type = type(obj).__name__
          obj_module = type(obj).__module__ if hasattr(type(obj), '__module__') else None

          # Get attributes (methods and properties)
          attrs = []
          for attr_name in dir(obj):
              if not attr_name.startswith('_'):
                  try:
                      attr = getattr(obj, attr_name)
                      attr_type = type(attr).__name__
                      is_callable = callable(attr)

                      # Get docstring if available
                      doc = None
                      if hasattr(attr, '__doc__') and attr.__doc__:
                          doc = attr.__doc__.strip()[:200]  # Limit length

                      attrs.append({
                          "name": attr_name,
                          "type": attr_type,
                          "callable": is_callable,
                          "doc": doc
                      })
                  except:
                      pass

          # Get docstring of the object itself
          obj_doc = None
          if hasattr(obj, '__doc__') and obj.__doc__:
              obj_doc = obj.__doc__.strip()[:500]  # Limit length

          result = {
              "object_path": "#{object_path}",
              "type": obj_type,
              "module": obj_module,
              "doc": obj_doc,
              "attributes": attrs[:50]  # Limit to 50 attributes
          }
      except Exception as e:
          result = {
              "object_path": "#{object_path}",
              "error": str(e)
          }

      json.dumps(result)
      """

      result_json = Pythonx.eval(code, %{})
      {:ok, Jason.decode!(result_json)}
    rescue
      e ->
        {:error, "Failed to introspect: #{inspect(e)}"}
    end
  end

  @doc """
  Introspects any Python object/API structure for debugging and understanding Python APIs.
  """
  @spec introspect_python(String.t(), String.t() | nil, String.t()) :: result()
  def introspect_python(object_path, prep_code \\ nil, temp_dir) do
    :ok = Utils.ensure_pythonx()
    introspect_python_bpy(object_path, prep_code, temp_dir)
  end

  defp introspect_python_bpy(object_path, prep_code, _temp_dir) do
    try do
      # Escape the object path for safety - only allow alphanumeric, dots, and underscores
      safe_path = String.replace(object_path, ~r/[^a-zA-Z0-9._]/, "")

      prep_code_safe = if prep_code, do: String.replace(prep_code, ~r/[^\x20-\x7E\n]/, ""), else: ""

      code = """
      import inspect
      import json
      #{prep_code_safe}

      # Safely evaluate the object path
      try:
          obj = eval("#{safe_path}")

          # Get type information
          obj_type = type(obj).__name__
          obj_module = type(obj).__module__ if hasattr(type(obj), '__module__') else None

          # Get attributes (methods and properties)
          attrs = []
          for attr_name in dir(obj):
              if not attr_name.startswith('_'):
                  try:
                      attr = getattr(obj, attr_name)
                      attr_type = type(attr).__name__
                      is_callable = callable(attr)

                      # Get docstring if available
                      doc = None
                      if hasattr(attr, '__doc__') and attr.__doc__:
                          doc = attr.__doc__.strip()[:200]  # Limit length

                      attrs.append({
                          "name": attr_name,
                          "type": attr_type,
                          "callable": is_callable,
                          "doc": doc
                      })
                  except:
                      pass

          # Get docstring of the object itself
          obj_doc = None
          if hasattr(obj, '__doc__') and obj.__doc__:
              obj_doc = obj.__doc__.strip()[:500]  # Limit length

          result = {
              "object_path": "#{object_path}",
              "type": obj_type,
              "module": obj_module,
              "doc": obj_doc,
              "attributes": attrs[:50]  # Limit to 50 attributes
          }
      except Exception as e:
          result = {
              "object_path": "#{object_path}",
              "error": str(e)
          }

      json.dumps(result)
      """

      result_json = Pythonx.eval(code, %{})
      {:ok, Jason.decode!(result_json)}
    rescue
      e ->
        {:error, "Failed to introspect: #{inspect(e)}"}
    end
  end
end
