defmodule MglId.Policies do
  @moduledoc """
  Access-control policies for account and admin RBAC.
  """

  import Ecto.Query

  alias MglId.Accounts.User
  alias MglId.Policies.{AdminRole, AdminUserRole}
  alias MglId.Repo

  @permissions ~w(
    users.read
    users.manage
    registrations.review
    applications.read
    applications.manage
    security.audit
    system.settings
  )

  def permissions, do: @permissions

  def allow?(%User{is_admin: true}, _permission), do: true

  def allow?(%User{} = user, permission) when is_binary(permission) do
    permission in user_permissions(user)
  end

  def allow?(_, _), do: false

  def user_permissions(%User{} = user) do
    Repo.all(
      from ur in AdminUserRole,
        join: r in AdminRole,
        on: r.id == ur.role_id,
        where: ur.user_id == ^user.id,
        select: r.permissions
    )
    |> List.flatten()
    |> Enum.uniq()
  end

  def assign_role(%User{} = user, %AdminRole{} = role) do
    %AdminUserRole{}
    |> AdminUserRole.changeset(%{user_id: user.id, role_id: role.id})
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :role_id])
  end

  def ensure_default_roles! do
    role =
      case Repo.get_by(AdminRole, name: "admin") do
        nil ->
          {:ok, role} =
            %AdminRole{}
            |> AdminRole.changeset(%{name: "admin", permissions: @permissions})
            |> Repo.insert()

          role

        role ->
          role
      end

    # Attach legacy is_admin users
    for user <- Repo.all(from u in User, where: u.is_admin == true) do
      assign_role(user, role)
    end

    role
  end
end
