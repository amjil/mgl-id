defmodule MglIdWeb.SessionController do
  use MglIdWeb, :controller

  alias MglId.{Authentication, Sessions}
  alias MglIdWeb.UserAuth

  def create(conn, %{"username" => username, "password" => password} = _params) do
    meta = %{
      ip_address: conn.remote_ip && :inet.ntoa(conn.remote_ip) |> to_string(),
      user_agent: get_req_header(conn, "user-agent") |> List.first()
    }

    case Authentication.login(username, password, meta) do
      {:ok, _user, _session, token} ->
        return_to = get_session(conn, :user_return_to) || ~p"/account"

        conn
        |> delete_session(:user_return_to)
        |> UserAuth.log_in_user(token)
        |> put_flash(:info, "ᠠᠮᠵᠢᠯᠲᠠᠲᠠᠢ ᠨᠡᠪᠲᠡᠷᠡᠪᠡ")
        |> redirect(to: return_to)

      {:error, :account_suspended} ->
        conn
        |> put_flash(:error, "ᠪᠦᠷᠢᠳᠬᠡᠯ ᠲᠦᠷ ᠵᠣᠭᠰᠤᠭᠠᠭᠳᠠᠭᠰᠠᠨ ᠪᠠᠢᠨ᠎ᠠ")
        |> redirect(to: ~p"/login")

      {:error, :account_disabled} ->
        conn
        |> put_flash(:error, "ᠪᠦᠷᠢᠳᠬᠡᠯ ᠬᠠᠭᠠᠭᠳᠠᠭᠰᠠᠨ ᠪᠠᠢᠨ᠎ᠠ")
        |> redirect(to: ~p"/login")

      {:error, _} ->
        conn
        |> put_flash(:error, "ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ᠎ᠶᠢᠨ ᠨᠡᠷ᠎ᠡ ᠪᠤᠶᠤ ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠪᠤᠷᠤᠤ")
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    if session = conn.assigns[:current_session] do
      _ = Sessions.revoke_session(session)
    end

    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "ᠰᠢᠰᠲ᠋ᠧᠮ ᠡᠴᠡ ᠭᠠᠷᠪᠠ")
    |> redirect(to: ~p"/login")
  end
end
