defmodule MglIdWeb.Api.V1.AuthorizedApplicationController do
  use MglIdWeb, :controller

  alias MglId.AuthorizedApplications

  def index(conn, _params) do
    apps =
      conn.assigns.current_user.id
      |> AuthorizedApplications.list_for_user()
      |> Enum.map(fn app ->
        %{
          client_id: app.client_id,
          name: app.client && app.client.name,
          scopes: app.scopes,
          granted_at: app.granted_at
        }
      end)

    json(conn, %{data: apps, meta: %{}})
  end

  def delete(conn, %{"client_id" => client_id}) do
    {:ok, _} = AuthorizedApplications.revoke_for_user(conn.assigns.current_user.id, client_id)
    json(conn, %{data: %{}, meta: %{}})
  end
end
