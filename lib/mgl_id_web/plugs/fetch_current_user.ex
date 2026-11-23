defmodule MglIdWeb.Plugs.FetchCurrentUser do
  @moduledoc false
  import Plug.Conn

  alias MglId.Sessions

  @cookie "_mgl_id_session_token"

  def init(opts), do: opts

  def call(conn, _opts) do
    token = get_session(conn, :session_token) || conn.cookies[@cookie]

    case token && Sessions.get_user_by_session_token(token) do
      {user, session} ->
        conn
        |> assign(:current_user, user)
        |> assign(:current_session, session)
        |> put_session(:session_token, token)

      nil ->
        conn
        |> assign(:current_user, nil)
        |> assign(:current_session, nil)
    end
  end

  def cookie_name, do: @cookie
end
