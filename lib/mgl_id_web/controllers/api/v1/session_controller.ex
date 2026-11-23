defmodule MglIdWeb.Api.V1.SessionController do
  use MglIdWeb, :controller

  alias MglId.Errors
  alias MglId.Sessions

  def index(conn, _params) do
    sessions =
      conn.assigns.current_user.id
      |> Sessions.list_user_sessions()
      |> Enum.map(&session_json/1)

    json(conn, %{data: sessions, meta: %{}})
  end

  def delete(conn, %{"id" => id}) do
    case Sessions.revoke_session(conn.assigns.current_user.id, id) do
      {:ok, _} ->
        json(conn, %{data: %{}, meta: %{}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: Errors.to_error(:not_found)})
    end
  end

  defp session_json(session) do
    %{
      id: session.id,
      device_name: session.device_name,
      ip_address: session.ip_address,
      last_active_at: session.last_active_at,
      expires_at: session.expires_at,
      inserted_at: session.inserted_at
    }
  end
end
