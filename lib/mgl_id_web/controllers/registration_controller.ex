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
            |> put_flash(:info, "Account created")
            |> redirect(to: ~p"/account")

          {:error, _} ->
            conn
            |> put_flash(:info, "Account created; pending review")
            |> redirect(to: ~p"/login")
        end

      {:error, :username_already_exists} ->
        conn
        |> put_flash(:error, "Username already taken")
        |> redirect(to: ~p"/register")

      {:error, :invalid_username} ->
        conn
        |> put_flash(:error, "Invalid username")
        |> redirect(to: ~p"/register")

      {:error, :invalid_password} ->
        conn
        |> put_flash(:error, "Password must be at least 12 characters")
        |> redirect(to: ~p"/register")

      {:error, :registration_disabled} ->
        conn
        |> put_flash(:error, "Registration disabled")
        |> redirect(to: ~p"/register")

      {:error, :rate_limited} ->
        conn
        |> put_flash(:error, "Too many requests")
        |> redirect(to: ~p"/register")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not register")
        |> redirect(to: ~p"/register")
    end
  end
end
