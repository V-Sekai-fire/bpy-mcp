# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools.Introspection do
  @moduledoc """
  Introspection tools for examining bpy/bmesh and Python APIs (read-only, metadata only).
  """

  alias BpyMcp.BpyTools.Utils

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Introspects Blender bpy/bmesh structure for debugging and understanding API.
  Metadata only - no property access, no side effects.
  """
  @spec introspect_bpy(String.t(), String.t()) :: bpy_result()
  def introspect_bpy(object_path \\ "bmesh", temp_dir) do
    case Utils.ensure_pythonx() do
      :ok ->
        do_introspect_bpy(object_path, temp_dir)

      :mock ->
        {:ok, "Mock introspection of #{object_path}: API not available in mock mode"}
    end
  end

  defp do_introspect_bpy(object_path, temp_dir) do
    escaped_path = object_path |> String.replace("\\", "\\\\") |> String.replace("'", "\\'")

    code = """
import bpy
import bmesh
import inspect

try:
    # Evaluate the object path (read-only evaluation)
    obj = eval('#{escaped_path}')
    
    result_parts = []
    result_parts.append(f"=== bpy Introspection (Metadata Only): #{escaped_path} ===\\n")
    result_parts.append("[Read-Only: Only showing static API metadata, no property access]\\n")
    
    # Get type (metadata only)
    result_parts.append(f"Type: {type(obj).__name__}\\n")
    
    # Get module if available (metadata)
    if hasattr(obj, '__module__'):
        result_parts.append(f"Module: {obj.__module__}\\n")
    
    # Get docstring (metadata, read-only)
    if hasattr(obj, '__doc__') and obj.__doc__:
        doc = obj.__doc__.strip().split('\\n')[0] if obj.__doc__ else ""
        if doc:
            result_parts.append(f"Docstring: {doc}\\n")
    
    result_parts.append("\\n--- Available Attributes (Names Only) ---\\n")
    # Only list attribute names from dir(), don't access them (avoid property getters)
    attrs = [attr for attr in dir(obj) if not attr.startswith('_')]
    result_parts.append(f"Attribute names ({len(attrs)}): {', '.join(attrs[:25])}")
    if len(attrs) > 25:
        result_parts.append(f" ... and {len(attrs) - 25} more")
    result_parts.append("\\n")
    
    result_parts.append("\\n--- Methods (Metadata Only) ---\\n")
    # Get method names and signatures only, don't call them
    methods = []
    method_sigs = []
    for name, method in inspect.getmembers(obj, inspect.ismethod):
        if not name.startswith('_'):
            methods.append(name)
            try:
                sig = inspect.signature(method)
                method_sigs.append(f"  {name}{sig}")
            except:
                method_sigs.append(f"  {name}(...)")
    
    result_parts.append(f"Methods ({len(methods)}): {', '.join(methods[:15])}")
    if len(methods) > 15:
        result_parts.append(f" ... and {len(methods) - 15} more")
    result_parts.append("\\n")
    
    # Show a few method signatures as examples
    if method_sigs:
        result_parts.append("\\nExample method signatures:\\n")
        result_parts.append('\\n'.join(method_sigs[:10]))
        if len(method_sigs) > 10:
            result_parts.append(f"\\n... and {len(method_sigs) - 10} more")
        result_parts.append("\\n")
    
    result_parts.append("\\n--- Functions (Metadata Only) ---\\n")
    # Get function names and signatures only
    functions = []
    func_sigs = []
    for name, func in inspect.getmembers(obj, inspect.isfunction):
        if not name.startswith('_'):
            functions.append(name)
            try:
                sig = inspect.signature(func)
                func_sigs.append(f"  {name}{sig}")
            except:
                func_sigs.append(f"  {name}(...)")
    
    result_parts.append(f"Functions ({len(functions)}): {', '.join(functions[:15])}")
    if len(functions) > 15:
        result_parts.append(f" ... and {len(functions) - 15} more")
    result_parts.append("\\n")
    
    # Show a few function signatures as examples
    if func_sigs:
        result_parts.append("\\nExample function signatures:\\n")
        result_parts.append('\\n'.join(func_sigs[:10]))
        if len(func_sigs) > 10:
            result_parts.append(f"\\n... and {len(func_sigs) - 10} more")
        result_parts.append("\\n")
    
    # If it's a module, show what's in it (read-only)
    if inspect.ismodule(obj):
        result_parts.append("\\n--- Module Contents (Names Only) ---\\n")
        module_contents = [name for name in dir(obj) if not name.startswith('_')]
        result_parts.append(f"Contents: {', '.join(module_contents[:30])}")
        if len(module_contents) > 30:
            result_parts.append(f" ... and {len(module_contents) - 30} more")
    
    # If it's a class, show base classes (metadata)
    if inspect.isclass(obj):
        if hasattr(obj, '__bases__'):
            bases = [base.__name__ for base in obj.__bases__ if base != object]
            if bases:
                result_parts.append(f"\\nBase classes: {', '.join(bases)}\\n")
    
    result_parts.append("\\n[Note: Only metadata shown - no properties accessed, no methods called]\\n")
    result = '\\n'.join(result_parts)
    
except Exception as e:
    result = f"Error introspecting '#{escaped_path}': {str(e)}\\n{type(e).__name__}"
    import traceback
    result += "\\n\\nTraceback:\\n" + traceback.format_exc()

result
"""

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode introspection result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  @doc """
  Introspects any Python object/API structure for debugging and understanding Python APIs.
  This is a general-purpose tool that doesn't require Blender/bpy to be available.

  SECURITY: This tool is read-only and uses safe attribute access methods.
  It does not execute arbitrary code or modify any state.
  """
  @spec introspect_python(String.t(), String.t() | nil, String.t()) :: bpy_result()
  def introspect_python(object_path, prep_code \\ nil, temp_dir) do
    case Utils.ensure_pythonx() do
      :ok ->
        do_introspect_python(object_path, prep_code, temp_dir)

      :mock ->
        {:ok, "Mock introspection of #{object_path}: Python API not available in mock mode"}
    end
  end

  defp do_introspect_python(object_path, _prep_code, temp_dir) do
    # Sanitize object_path - only allow alphanumeric, dots, and underscores for safe module paths
    sanitized_path = object_path |> String.replace(~r/[^a-zA-Z0-9._]/, "")

    # Remove prep_code parameter entirely for security - no arbitrary code execution
    # Only allow safe module imports via importlib

    code = """
import inspect
import importlib
import sys

# Security: Only allow safe attribute access, no eval()
def safe_get_attr(obj, attr_path):
    \"\"\"Safely navigate attribute paths like 'module.submodule.Class'\"
    parts = attr_path.split('.')
    current = obj
    for part in parts:
        if not part or not part.replace('_', '').isalnum():
            raise ValueError(f"Invalid attribute name: {part}")
        if not hasattr(current, part):
            raise AttributeError(f"'{type(current).__name__}' has no attribute '{part}'")
        current = getattr(current, part)
    return current

try:
    # Parse object path safely
    path_parts = '#{sanitized_path}'.split('.')
    if not path_parts or not path_parts[0]:
        raise ValueError("Empty object path")
    
    # Import the base module safely using importlib (read-only)
    module_name = path_parts[0]
    if not module_name.replace('_', '').isalnum():
        raise ValueError(f"Invalid module name: {module_name}")
    
    try:
        base_module = importlib.import_module(module_name)
    except ImportError as e:
        result = f"Error importing module '{module_name}': {str(e)}"
        result
        import sys
        sys.exit(0)
    
    # Navigate to the target object using safe attribute access
    if len(path_parts) == 1:
        obj = base_module
    else:
        attr_path = '.'.join(path_parts[1:])
        obj = safe_get_attr(base_module, attr_path)
    
    result_parts = []
    result_parts.append(f"=== Python Introspection (Read-Only): #{sanitized_path} ===\\n")
    
    # Get type
    result_parts.append(f"Type: {type(obj).__name__}\\n")
    
    # Get base classes if it's a class
    if inspect.isclass(obj):
        bases = [base.__name__ for base in obj.__bases__ if base != object]
        if bases:
            result_parts.append(f"Base classes: {', '.join(bases)}\\n")
    
    # Get module if available
    if hasattr(obj, '__module__'):
        result_parts.append(f"Module: {obj.__module__}\\n")
    
    # Get docstring if available (read-only)
    if hasattr(obj, '__doc__') and obj.__doc__:
        doc = obj.__doc__.strip().split('\\n')[0]  # First line only
        result_parts.append(f"Docstring: {doc}\\n")
    
    result_parts.append("\\n--- Attributes (Names Only - No Access) ---\\n")
    # Only list attribute names from dir(), don't access them (avoid property getters with side effects)
    attrs = [attr for attr in dir(obj) if not attr.startswith('_')]
    
    result_parts.append(f"Attributes ({len(attrs)}): {', '.join(attrs[:30])}")
    if len(attrs) > 30:
        result_parts.append(f" ... and {len(attrs) - 30} more")
    result_parts.append("\\n")
    
    result_parts.append("\\n--- Methods (Read-Only Info) ---\\n")
    # Get instance methods (read metadata only, never call)
    methods = []
    for name, method in inspect.getmembers(obj, inspect.ismethod):
        if not name.startswith('_'):
            methods.append(name)
    
    result_parts.append(f"Methods ({len(methods)}): {', '.join(methods[:30])}")
    if len(methods) > 30:
        result_parts.append(f" ... and {len(methods) - 30} more")
    result_parts.append("\\n")
    
    result_parts.append("\\n--- Functions (Read-Only Info) ---\\n")
    # Get functions (read metadata only, never call)
    functions = []
    for name, func in inspect.getmembers(obj, inspect.isfunction):
        if not name.startswith('_'):
            functions.append(name)
    
    result_parts.append(f"Functions ({len(functions)}): {', '.join(functions[:30])}")
    if len(functions) > 30:
        result_parts.append(f" ... and {len(functions) - 30} more")
    result_parts.append("\\n")
    
    result_parts.append("\\n--- Callables (Read-Only Info) ---\\n")
    # Get callable objects (metadata only, never call)
    callables = []
    for name in dir(obj):
        if not name.startswith('_'):
            try:
                value = getattr(obj, name)
                if callable(value):
                    callables.append(name)
            except:
                pass
    
    result_parts.append(f"Callables ({len(callables)}): {', '.join(callables[:30])}")
    if len(callables) > 30:
        result_parts.append(f" ... and {len(callables) - 30} more")
    result_parts.append("\\n")
    
    # If it's a module, show what's in it (read-only)
    if inspect.ismodule(obj):
        result_parts.append("\\n--- Module Contents (Read-Only) ---\\n")
        module_contents = [name for name in dir(obj) if not name.startswith('_')]
        result_parts.append(f"Contents: {', '.join(module_contents[:40])}")
        if len(module_contents) > 40:
            result_parts.append(f" ... and {len(module_contents) - 40} more")
    
    # If it's a class, show its methods with signatures (read-only metadata)
    if inspect.isclass(obj):
        result_parts.append("\\n--- Class Methods (Read-Only Signatures) ---\\n")
        count = 0
        for name, method in inspect.getmembers(obj, inspect.isfunction):
            if not name.startswith('_') and count < 50:  # Limit to prevent excessive output
                try:
                    sig = inspect.signature(method)
                    result_parts.append(f"  {name}{sig}\\n")
                    count += 1
                except:
                    result_parts.append(f"  {name}(...)\\n")
                    count += 1
    
    # If it's callable, show its signature (read-only metadata)
    if callable(obj) and not inspect.isclass(obj) and not inspect.ismodule(obj):
        result_parts.append("\\n--- Signature (Read-Only) ---\\n")
        try:
            sig = inspect.signature(obj)
            result_parts.append(f"{obj.__name__ if hasattr(obj, '__name__') else 'callable'}{sig}\\n")
        except:
            result_parts.append("Signature not available\\n")
    
    result_parts.append("\\n[Read-Only Mode: No code execution or state modification]\\n")
    result = ''.join(result_parts)
    
except ValueError as e:
    result = f"Security Error: Invalid object path - {str(e)}"
except Exception as e:
    result = f"Error introspecting '#{sanitized_path}': {str(e)}\\n{type(e).__name__}"

result
"""

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode introspection result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end
end

