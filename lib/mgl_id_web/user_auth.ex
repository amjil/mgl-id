defmodule MglIdWeb.UserAuth do
  @moduledoc """
  Session cookie helpers for browser auth.
  """

  import Plug.Conn

  alias MglIdWeb.Plugs.FetchCurrentUser

  @max_age 60 * 60 * 24 * 30

  def log_in_user(conn, token) do
    conn
    |> renew_session()
    |> put_session(:session_token, token)
    |> put_resp_cookie(FetchCurrentUser.cookie_name(), token,
      sign: false,
      max_age: @max_age,
      same_site: "Lax",
      http_only: true
    )
  end

  def log_out_user(conn) do
    conn
    |> renew_session()
    |> delete_resp_cookie(FetchCurrentUser.cookie_name())
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
