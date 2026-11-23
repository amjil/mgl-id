defmodule MglIdWeb.OauthView do
  @moduledoc false
  use MglIdWeb, :view

  alias Boruta.Oauth.IntrospectResponse
  alias Boruta.Oauth.TokenResponse

  def render("token.json", %{response: %TokenResponse{} = response}) do
    Enum.filter(
      %{
        token_type: response.token_type,
        access_token: response.access_token,
        expires_in: response.expires_in,
        refresh_token: response.refresh_token,
        id_token: response.id_token
      },
      fn
        {_key, nil} -> false
        _ -> true
      end
    )
    |> Map.new()
  end

  def render("introspect.json", %{response: %IntrospectResponse{} = response}) do
    if response.active do
      %{
        active: true,
        client_id: response.client_id,
        username: response.username,
        scope: response.scope,
        sub: response.sub,
        iss: response.iss,
        exp: response.exp,
        iat: response.iat
      }
    else
      %{active: false}
    end
  end

  def render("error.json", %{error: error, error_description: error_description}) do
    %{error: error, error_description: error_description}
  end
end
