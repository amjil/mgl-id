defmodule MglId.AuthorizedApplications do
  @moduledoc """
  Apps the user has authorized via OIDC (Boruta tokens).
  """

  import Ecto.Query

  alias Boruta.Ecto.Admin
  alias Boruta.Ecto.Client
  alias Boruta.Ecto.Token
  alias MglId.Repo

  def list_for_user(user_id) do
    sub = to_string(user_id)
    now = System.system_time(:second)

    tokens =
      Repo.all(
        from t in Token,
          where: t.sub == ^sub,
          where: is_nil(t.revoked_at),
          where: t.expires_at >= ^now or not is_nil(t.refresh_token),
          where: is_nil(t.refresh_token_revoked_at) or is_nil(t.refresh_token),
          preload: [:client],
          order_by: [desc: t.inserted_at]
      )

    tokens
    |> Enum.group_by(& &1.client_id)
    |> Enum.map(fn {_client_id, [token | _] = group} ->
      scopes =
        group
        |> Enum.flat_map(&String.split(&1.scope || "", " ", trim: true))
        |> Enum.uniq()

      %{
        client_id: token.client_id,
        client: token.client,
        scopes: scopes,
        granted_at: token.inserted_at,
        token_ids: Enum.map(group, & &1.id)
      }
    end)
  end

  def revoke_for_user(user_id, client_id) do
    sub = to_string(user_id)
    now = DateTime.utc_now()

    {count, _} =
      Repo.update_all(
        from(t in Token,
          where: t.sub == ^sub,
          where: t.client_id == ^client_id,
          where: is_nil(t.revoked_at)
        ),
        set: [revoked_at: now, refresh_token_revoked_at: now]
      )

    # Bust Boruta caches if present
    _ = Admin.list_clients()

    {:ok, count}
  end

  def get_client(client_id), do: Repo.get(Client, client_id)
end
