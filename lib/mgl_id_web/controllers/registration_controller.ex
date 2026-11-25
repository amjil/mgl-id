defmodule MglIdWeb.RegistrationController do
  use MglIdWeb, :controller

  alias MglId.Authentication
  alias MglIdWeb.UserAuth

  def create(conn, params) do
    meta = %{
      ip_address: conn.remote_ip && :inet.ntoa(conn.remote_ip) |> to_string(),
      user_agent: get_req_header(conn, "user-agent") |> List.first(),
      source: "web"
    }

    case Authentication.register(params, meta) do
      {:ok, user} ->
        # Auto-login when account is immediately usable
        case Authentication.login(user.username, params["password"], meta) do
          {:ok, _user, _session, token} ->
            conn
            |> UserAuth.log_in_user(token)
            |> put_flash(:info, "ᠪᠦᠷᠲᠦᠭᠡᠯ ᠡᠭᠦᠰᠭᠡᠭᠳᠡᠪᠡ")
            |> redirect(to: ~p"/account")

          {:error, _} ->
            conn
            |> put_flash(:info, "ᠪᠦᠷᠲᠦᠭᠡᠯ ᠡᠭᠦᠰᠭᠡᠭᠳᠡᠪᠡ᠂ ᠰᠢᠯᠭᠠᠯᠲᠠ ᠬᠦᠯᠢᠶᠡᠵᠦ ᠪᠠᠢᠨ᠎ᠠ")
            |> redirect(to: ~p"/login")
        end

      {:error, :username_already_exists} ->
        conn
        |> put_flash(:error, "ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ ᠶᠢᠨ ᠨᠡᠷ᠎ᠡ ᠪᠦᠷᠢᠳᠬᠡᠭᠳᠡᠭᠰᠡᠨ ᠪᠠᠢᠨ᠎ᠠ")
        |> redirect(to: ~p"/register")

      {:error, :invalid_username} ->
        conn
        |> put_flash(:error, "ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ ᠶᠢᠨ ᠨᠡᠷ᠎ᠡ ᠪᠤᠷᠤᠤ")
        |> redirect(to: ~p"/register")

      {:error, :invalid_password} ->
        conn
        |> put_flash(:error, "ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ 12 ᠡᠴᠡ ᠳᠣᠭᠣᠰᠢ ᠦᠭᠡᠢ ᠲᠡᠮᠳᠡᠭᠲᠦ ᠪᠠᠢᠬᠤ ᠶᠣᠰᠤᠲᠠᠢ")
        |> redirect(to: ~p"/register")

      {:error, :registration_disabled} ->
        conn
        |> put_flash(:error, "ᠪᠦᠷᠢᠳᠬᠡᠯ ᠲᠦᠷ ᠬᠠᠭᠠᠭᠳᠠᠭᠰᠠᠨ ᠪᠠᠢᠨ᠎ᠠ")
        |> redirect(to: ~p"/register")

      {:error, :rate_limited} ->
        conn
        |> put_flash(:error, "ᠬᠦᠰᠡᠯᠲᠡ ᠬᠡᠲᠦᠷᠡᠭᠰᠡᠨ ᠪᠠᠢᠨ᠎ᠠ")
        |> redirect(to: ~p"/register")

      {:error, _} ->
        conn
        |> put_flash(:error, "ᠪᠦᠷᠢᠳᠬᠡᠵᠦ ᠴᠢᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ")
        |> redirect(to: ~p"/register")
    end
  end
end
