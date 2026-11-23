defmodule MglIdWeb.Oauth.AuthorizeController do
  @behaviour Boruta.Oauth.AuthorizeApplication

  use MglIdWeb, :controller

  alias Boruta.Oauth.AuthorizeResponse
  alias Boruta.Oauth.Error
  alias Boruta.Oauth.ResourceOwner
  alias MglId.Oauth.ResourceOwners
  alias MglIdWeb.UserAuth

  def oauth_module, do: Application.get_env(:mgl_id, :oauth_module, Boruta.Oauth)

  def authorize(%Plug.Conn{} = conn, _params) do
    conn = store_user_return_to(conn)
    resource_owner = get_resource_owner(conn)

    with {:unchanged, conn} <- prompt_redirection(conn),
         {:unchanged, conn} <- max_age_redirection(conn, resource_owner),
         {:unchanged, conn} <- login_redirection(conn),
         {:unchanged, conn} <- consent_redirection(conn) do
      oauth_module().authorize(conn, resource_owner, __MODULE__)
    end
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def authorize_success(conn, %AuthorizeResponse{} = response) do
    redirect(conn, external: AuthorizeResponse.redirect_to_url(response))
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def authorize_error(
        %Plug.Conn{} = conn,
        %Error{status: :unauthorized, error: :login_required} = error
      ) do
    redirect(conn, external: Error.redirect_to_url(error))
  end

  def authorize_error(%Plug.Conn{} = conn, %Error{
        status: :unauthorized,
        error: :invalid_resource_owner
      }) do
    redirect_to_login(conn)
  end

  def authorize_error(conn, %Error{format: format} = error) when not is_nil(format) do
    redirect(conn, external: Error.redirect_to_url(error))
  end

  def authorize_error(conn, %Error{
        status: status,
        error: error,
        error_description: error_description
      }) do
    esc = fn v ->
      v |> to_string() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    end

    body = """
    <!DOCTYPE html>
    <html><body class="mn-latin">
    <h1>#{esc.(error)}</h1>
    <p>#{esc.(error_description)}</p>
    </body></html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(status, body)
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def preauthorize_success(_conn, _response), do: :ok

  @impl Boruta.Oauth.AuthorizeApplication
  def preauthorize_error(_conn, _response), do: :ok

  defp store_user_return_to(conn) do
    path =
      current_path(conn)
      |> String.replace(~r/prompt=(login|none)/, "")
      |> String.replace(~r/max_age=(\d+)/, "")

    put_session(conn, :user_return_to, path)
  end

  defp prompt_redirection(%Plug.Conn{query_params: %{"prompt" => "login"}} = conn) do
    log_out_user(conn)
  end

  defp prompt_redirection(%Plug.Conn{} = conn), do: {:unchanged, conn}

  defp max_age_redirection(
         %Plug.Conn{query_params: %{"max_age" => max_age}} = conn,
         %ResourceOwner{} = resource_owner
       ) do
    if login_expired?(resource_owner, max_age), do: log_out_user(conn), else: {:unchanged, conn}
  end

  defp max_age_redirection(%Plug.Conn{} = conn, _resource_owner), do: {:unchanged, conn}

  defp login_expired?(%ResourceOwner{last_login_at: nil}, _max_age), do: true

  defp login_expired?(%ResourceOwner{last_login_at: last_login_at}, max_age) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    with "" <> max_age <- max_age,
         {max_age, _} <- Integer.parse(max_age),
         true <- now - DateTime.to_unix(last_login_at) >= max_age do
      true
    else
      _ -> false
    end
  end

  defp login_redirection(%Plug.Conn{assigns: %{current_user: %_{}}} = conn) do
    {:unchanged, conn}
  end

  defp login_redirection(%Plug.Conn{query_params: %{"prompt" => "none"}} = conn) do
    {:unchanged, conn}
  end

  defp login_redirection(%Plug.Conn{} = conn), do: redirect_to_login(conn)

  defp consent_redirection(%Plug.Conn{assigns: %{current_user: nil}} = conn),
    do: {:unchanged, conn}

  defp consent_redirection(%Plug.Conn{query_params: params} = conn) do
    client_id = params["client_id"]
    scope = params["scope"] || ""
    key = consent_key(client_id, scope)

    if get_session(conn, key) do
      {:unchanged, conn}
    else
      conn
      |> put_session(:oauth_consent_return_to, current_path(conn))
      |> redirect(to: ~p"/oauth/consent?#{%{client_id: client_id, scope: scope}}")
    end
  end

  def consent_key(client_id, scope), do: "oauth_consent:#{client_id}:#{scope}"

  defp get_resource_owner(conn) do
    case conn.assigns[:current_user] do
      nil -> %ResourceOwner{sub: nil}
      user -> ResourceOwners.to_resource_owner(user)
    end
  end

  defp redirect_to_login(conn) do
    redirect(conn, to: ~p"/login")
  end

  defp log_out_user(conn) do
    if session = conn.assigns[:current_session] do
      _ = MglId.Sessions.revoke_session(session)
    end

    conn
    |> UserAuth.log_out_user()
    |> redirect(to: ~p"/login")
  end
end
