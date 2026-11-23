defmodule MglId.AuthorizedApplicationsTest do
  use MglId.DataCase, async: false

  alias Boruta.Ecto.Token
  alias MglId.{AuthorizedApplications, Clients, Fixtures, Repo}

  test "lists and revokes apps for a user" do
    client = Clients.seed_dev_client!()
    {:ok, user} = Fixtures.register_user(%{username: Fixtures.unique_username()})

    {:ok, _} =
      %Token{}
      |> Ecto.Changeset.change(%{
        type: "access_token",
        value: "test-token-#{System.unique_integer()}",
        client_id: client.id,
        sub: to_string(user.id),
        scope: "openid profile",
        expires_at: System.system_time(:second) + 600
      })
      |> Repo.insert()

    apps = AuthorizedApplications.list_for_user(user.id)
    assert Enum.any?(apps, &(&1.client_id == client.id))

    assert {:ok, _} = AuthorizedApplications.revoke_for_user(user.id, client.id)
    assert AuthorizedApplications.list_for_user(user.id) == []
  end
end
