defmodule MglIdWeb.UserAuth do
  @moduledoc """
  Session cookie helpers for browser auth.
  """

  import Plug.Conn

  alias MglIdWeb.Plugs.FetchCurrentUser

  @max_age 60 * 60 * 24 * 30
  @secure_cookies Application.compile_env(:mgl_id, :secure_cookies, false)

  def log_in_user(conn, token) do
    conn
    |> renew_session()
    |> put_session(:session_token, token)
    |> put_resp_cookie(FetchCurrentUser.cookie_name(), token,
      sign: false,
      max_age: @max_age,
      same_site: "Lax",
      http_only: true,
      secure: @secure_cookies
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
