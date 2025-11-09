# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.MathTools do
  @moduledoc """
  Math tools exposing aria_math API functions.

  Provides access to:
  - AriaMath API primitives (Vector3, Matrix4, Quaternion, Primitives)
  """

  @doc """
  Call an aria_math API function.

  Supported modules:
  - AriaMath.API.Primitives - abs_float, clamp_float, approximately_equal, clamp, lerp_scalar, deg_to_rad, rad_to_deg, create_joint
  - AriaMath.API.Vector3 - vector3, add, subtract, scale, dot, cross, length, normalize, distance, lerp
  - AriaMath.API.Matrix4 - matrix4_identity, matrix4_translation, matrix4_scaling, matrix4_rotation, matrix4_multiply, matrix4_transform_point, matrix4_transform_direction, matrix4_inverse, matrix4_transpose, matrix4_decompose, matrix4_compose, matrix_determinant
  - AriaMath.API.Quaternion - quaternion, identity_quaternion, quaternion_from_axis_angle, quaternion_from_euler, quaternion_multiply, quaternion_normalize, quaternion_rotate, quaternion_conjugate, quaternion_slerp
  """
  @spec call_aria_math(String.t(), String.t(), list()) :: {:ok, term()} | {:error, String.t()}
  def call_aria_math(module_name, function_name, args) do
    case Code.ensure_loaded?(AriaMath) do
      true ->
        try do
          case get_aria_math_module(module_name) do
            {:error, reason} ->
              {:error, reason}

            module ->
              result = apply(module, String.to_atom(function_name), args)
              {:ok, result}
          end
        rescue
          e ->
            {:error, "Failed to call aria_math function: #{inspect(e)}"}
        end

      false ->
        {:error, "AriaMath not available"}
    end
  end

  defp get_aria_math_module("Primitives"), do: AriaMath.API.Primitives
  defp get_aria_math_module("Matrix4"), do: AriaMath.API.Matrix4
  defp get_aria_math_module("Vector3"), do: AriaMath.API.Vector3
  defp get_aria_math_module("Quaternion"), do: AriaMath.API.Quaternion
  defp get_aria_math_module(_), do: {:error, "Unknown aria_math module"}
end
