# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Configure pythonx to auto-initialize with bpy in test environment
# bpy is vendored and always available via pythonx
config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "bpy-mcp"
  version = "0.1.0"
  requires-python = ">=3.10"
  dependencies = []
  """
