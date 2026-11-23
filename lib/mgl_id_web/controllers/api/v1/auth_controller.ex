defmodule MglIdWeb.Api.V1.AuthController do
  use MglIdWeb, :controller

  alias MglId.{Authentication, Errors, Sessions}
  alias MglId.Accounts.User
  alias MglIdWeb.UserAuth

  def register(conn, params) do
    meta = request_meta(conn)

    case Authentication.register(params, meta) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{data: User.public_attrs(user), meta: %{}})

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def login(conn, params) do
    username = params["username"]
    password = params["password"]
    meta = request_meta(conn)

    case Authentication.login(username, password, meta) do
      {:ok, user, session, token} ->
        conn
        |> UserAuth.log_in_user(token)
        |> json(%{
          data: %{
            user: User.public_attrs(user),
            session: %{id: session.id, expires_at: session.expires_at}
          },
          meta: %{}
        })

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def logout(conn, _params) do
    if session = conn.assigns[:current_session] do
      _ = Sessions.revoke_session(session)
    end

    conn
    |> UserAuth.log_out_user()
    |> json(%{data: %{}, meta: %{}})
  end

  def logout_all(conn, _params) do
    user = conn.assigns.current_user
    {:ok, _} = Sessions.revoke_all_user_sessions(user.id)

    conn
    |> UserAuth.log_out_user()
    |> json(%{data: %{}, meta: %{}})
  end

  def change_password(conn, params) do
    user = conn.assigns.current_user

    case Authentication.change_password(
           user,
           params["current_password"],
           params["new_password"]
         ) do
      :ok ->
        conn
        |> UserAuth.log_out_user()
        |> json(%{data: %{}, meta: %{message: "Password changed; please log in again"}})

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def forgot_password(conn, params) do
    _ = Authentication.forgot_password(params["username"], request_meta(conn))
    json(conn, %{data: %{}, meta: %{message: "If the account exists, a reset email was sent"}})
  end

  def reset_password(conn, params) do
    case Authentication.reset_password(params["token"], params["password"]) do
      :ok -> json(conn, %{data: %{}, meta: %{}})
      {:error, reason} -> error_response(conn, reason)
    end
  end

  defp request_meta(conn) do
    %{
      ip_address: conn.remote_ip && :inet.ntoa(conn.remote_ip) |> to_string(),
      user_agent: get_req_header(conn, "user-agent") |> List.first()
    }
  end

  defp error_response(conn, reason) do
    status =
      case reason do
        :rate_limited -> :too_many_requests
        :unauthorized -> :unauthorized
        :forbidden -> :forbidden
        :username_already_exists -> :conflict
        :email_taken -> :conflict
        :registration_disabled -> :forbidden
        :account_suspended -> :forbidden
        :account_disabled -> :forbidden
        _ -> :unprocessable_entity
      end

    conn
    |> put_status(status)
    |> json(%{error: Errors.to_error(reason)})
  end
end
