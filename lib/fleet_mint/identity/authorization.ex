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

      iex> authorized?(%User{role: "tenant_admin"}, ["platform_admin", "tenant_admin", "manager"])
      true

      iex> authorized?(%User{role: "cashier"}, ["platform_admin", "tenant_admin", "manager"])
      false

  """
  def authorized?(%User{role: role}, allowed_roles) when is_list(allowed_roles) do
    role in allowed_roles
  end

  @doc """
  Platform-level users (`organisation_id` is nil — Miway's own staff) are
  not tied to a single tenant and see across every organisation. Tenant
  staff are scoped to their own organisation's data only.

  ## Examples

      iex> platform_level?(%User{organisation_id: nil})
      true

      iex> platform_level?(%User{organisation_id: 7})
      false

  """
  def platform_level?(%User{organisation_id: nil}), do: true
  def platform_level?(%User{}), do: false

  @doc """
  True only for the `platform_admin` role specifically — the authority
  check for platform-only actions (onboarding a new tenant, the
  platform-wide audit log). Deliberately a role check, not
  `platform_level?/1` (organisation_id nil): the two questions —"which
  organisations' data can this user see" vs. "is this user actually
  Miway's own platform administrator" — must be checked independently,
  not inferred from each other.
  """
  def platform_admin?(%User{role: "platform_admin"}), do: true
  def platform_admin?(%User{}), do: false

  @doc """
  Returns true if `user` may access a record belonging to `organisation_id`
  — either the user is platform-level, or the record's organisation
  matches their own.

  ## Examples

      iex> can_access_organisation?(%User{organisation_id: nil}, 7)
      true

      iex> can_access_organisation?(%User{organisation_id: 7}, 7)
      true

      iex> can_access_organisation?(%User{organisation_id: 3}, 7)
      false

  """
  def can_access_organisation?(%User{} = user, organisation_id) do
    platform_level?(user) or user.organisation_id == organisation_id
  end
end
