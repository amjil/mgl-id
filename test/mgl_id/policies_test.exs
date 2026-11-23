defmodule MglId.PoliciesTest do
  use MglId.DataCase, async: true

  alias MglId.{Fixtures, Policies}

  test "is_admin bypasses permission checks" do
    {:ok, user} = Fixtures.register_user(%{username: Fixtures.unique_username()})

    {:ok, user} =
      user
      |> Ecto.Changeset.change(%{is_admin: true})
      |> MglId.Repo.update()

    assert Policies.allow?(user, "users.manage")
  end

  test "ensure_default_roles assigns admin role to is_admin users" do
    {:ok, user} = Fixtures.register_user(%{username: Fixtures.unique_username()})

    {:ok, user} =
      user
      |> Ecto.Changeset.change(%{is_admin: true})
      |> MglId.Repo.update()

    role = Policies.ensure_default_roles!()
    assert role.name == "admin"
    assert "users.read" in Policies.user_permissions(user)
  end
end
