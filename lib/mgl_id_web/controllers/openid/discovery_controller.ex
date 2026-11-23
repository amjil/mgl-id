defmodule MglIdWeb.Openid.DiscoveryController do
  use MglIdWeb, :controller

  @doc """
  OpenID Connect Discovery document. Only declares capabilities we support.
  """
  def configuration(conn, _params) do
    issuer = Application.get_env(:boruta, Boruta.Oauth)[:issuer] || "https://id.amjil.net"

    json(conn, %{
      issuer: issuer,
      authorization_endpoint: url(~p"/oauth/authorize"),
      token_endpoint: url(~p"/oauth/token"),
      userinfo_endpoint: url(~p"/oauth/userinfo"),
      revocation_endpoint: url(~p"/oauth/revoke"),
      introspection_endpoint: url(~p"/oauth/introspect"),
      jwks_uri: url(~p"/.well-known/jwks.json"),
      response_types_supported: ["code"],
      grant_types_supported: ["authorization_code", "refresh_token"],
      subject_types_supported: ["public"],
      id_token_signing_alg_values_supported: ["RS256"],
      scopes_supported: ["openid", "profile", "email", "offline_access"],
      token_endpoint_auth_methods_supported: [
        "client_secret_basic",
        "client_secret_post",
        "none"
      ],
      code_challenge_methods_supported: ["S256"],
      claims_supported: [
        "sub",
        "iss",
        "aud",
        "exp",
        "iat",
        "nonce",
        "preferred_username",
        "name",
        "locale",
        "email",
        "email_verified"
      ]
    })
  end
end
