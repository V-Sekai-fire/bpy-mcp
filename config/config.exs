# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

config :waffle,
  storage: Waffle.Storage.Local,
  storage_dir_prefix: Path.join(System.user_home!(), ".bpy_mcp/storage")
