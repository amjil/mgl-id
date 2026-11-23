defmodule MglIdWeb.Api.V1.AccountLinkController do
  use MglIdWeb, :controller

  alias MglId.{AccountLinks, Errors}

  def index(conn, _params) do
    links =
      conn.assigns.current_user.id
      |> AccountLinks.list_for_user()
      |> Enum.map(&public_link/1)

    json(conn, %{data: links, meta: %{}})
  end

  def create_initiation(conn, params) do
    provider = params["provider"]
    meta = request_meta(conn)

    case AccountLinks.initiate(conn.assigns.current_user, provider, meta) do
      {:ok, result} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            provider: result.provider,
            token: result.token,
            nonce: result.nonce,
            redirect_url: result.redirect_url,
            expires_at: result.expires_at,
            initiation_id: result.initiation.id
          },
          meta: %{}
        })

      {:error, {:account_link_exists, details}} ->
        error_response(conn, :account_link_exists, details)

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def confirm(conn, params) do
    {client_id, client_secret} = client_credentials(conn, params)

    case AccountLinks.confirm(client_id, client_secret, params) do
      {:ok, link} ->
        json(conn, %{
          data: %{
            link: public_link(link),
            user_id: link.user_id,
            amjil_user_id: link.user_id
          },
          meta: %{}
        })

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def delete(conn, %{"id" => id} = params) do
    password = params["password"] || ""

    case AccountLinks.unlink(conn.assigns.current_user, id, password) do
      {:ok, _} -> json(conn, %{data: %{}, meta: %{}})
      {:error, reason} -> error_response(conn, reason)
    end
  end

  defp public_link(link) do
    %{
      id: link.id,
      provider: link.provider,
      external_user_id: link.external_user_id,
      linked_at: link.linked_at
    }
  end

  defp client_credentials(conn, params) do
    case get_req_header(conn, "authorization") do
      ["Basic " <> encoded] ->
        case Base.decode64(encoded) do
          {:ok, decoded} ->
            case String.split(decoded, ":", parts: 2) do
              [id, secret] -> {id, secret}
              _ -> {params["client_id"], params["client_secret"]}
            end

          :error ->
            {params["client_id"], params["client_secret"]}
        end

      _ ->
        {params["client_id"], params["client_secret"]}
    end
  end

  defp request_meta(conn) do
    %{
      ip_address: conn.remote_ip && :inet.ntoa(conn.remote_ip) |> to_string(),
      user_agent: get_req_header(conn, "user-agent") |> List.first()
    }
  end

  defp error_response(conn, reason, details \\ %{}) do
    status =
      case reason do
        :invalid_client -> :unauthorized
        :unauthorized -> :unauthorized
        :forbidden -> :forbidden
        :not_found -> :not_found
        :invalid_credentials -> :unauthorized
        :account_link_conflict -> :conflict
        :account_link_exists -> :conflict
        :account_link_expired -> :gone
        :account_disabled -> :forbidden
        :account_suspended -> :forbidden
        :rate_limited -> :too_many_requests
        _ -> :unprocessable_entity
      end

    error =
      case reason do
        {:account_link_exists, extra} -> Errors.to_error({:account_link_exists, extra})
        _ when details != %{} -> Errors.to_error({reason, details})
        _ -> Errors.to_error(reason)
      end

    conn
    |> put_status(status)
    |> json(%{error: error})
  end
end
