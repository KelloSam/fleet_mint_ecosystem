defmodule FleetMint.Identity.Authorization do
  @moduledoc """
  Role-based authorization checks.

  Thin today, on purpose: a user's role is a single string column (see
  `FleetMint.Identity.User`'s `@valid_roles`), not a normalized
  roles/permissions model. This module exists so that boundary is named
  and callers (`RequireRolePlug`, per-controller `require_admin`/
  `require_manager` plugs) go through one place rather than each inlining
  `user.role in [...]`. If per-role granular permissions become a real
  need, this is where that model would grow from.
  """

  alias FleetMint.Identity.User

  @doc """
  Returns true if `user`'s role is included in `allowed_roles`.

  ## Examples

      iex> authorized?(%User{role: "admin"}, ["admin", "manager"])
      true

      iex> authorized?(%User{role: "cashier"}, ["admin", "manager"])
      false

  """
  def authorized?(%User{role: role}, allowed_roles) when is_list(allowed_roles) do
    role in allowed_roles
  end
end
