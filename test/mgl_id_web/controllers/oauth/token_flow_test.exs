defmodule MglIdWeb.Oauth.TokenFlowTest do
  use MglIdWeb.ConnCase, async: false

  alias MglId.{Clients, Fixtures}
  alias MglIdWeb.Oauth.AuthorizeController
  alias MglIdWeb.UserAuth

  setup do
    client = Clients.seed_dev_client!()
    username = Fixtures.unique_username()
    password = Fixtures.valid_password()
    {:ok, user} = Fixtures.register_user(%{username: username, password: password})
    {:ok, _session, token} = MglId.Sessions.create_session(user, %{})

    verifier = "test-code-verifier-0123456789abcdef"
    challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

    {:ok,
     client: client,
     user: user,
     session_token: token,
     verifier: verifier,
     challenge: challenge,
     redirect_uri: hd(client.redirect_uris)}
  end

  test "authorization code + PKCE token exchange", %{
    conn: conn,
    client: client,
    session_token: session_token,
    verifier: verifier,
    challenge: challenge,
    redirect_uri: redirect_uri
  } do
    scope = "openid profile"
    consent_key = AuthorizeController.consent_key(client.id, scope)

    conn =
      conn
      |> init_test_session(%{})
      |> UserAuth.log_in_user(session_token)
      |> put_session(consent_key, true)
      |> get(~p"/oauth/authorize", %{
        "response_type" => "code",
        "client_id" => client.id,
        "redirect_uri" => redirect_uri,
        "scope" => scope,
        "state" => "st",
        "nonce" => "n1",
        "code_challenge" => challenge,
        "code_challenge_method" => "S256"
      })

    location = redirected_to(conn, 302)
    assert location =~ redirect_uri
    %URI{query: query} = URI.parse(location)
    params = URI.decode_query(query)
    assert params["state"] == "st"
    assert code = params["code"]

    conn =
      build_conn()
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> post(~p"/oauth/token", %{
        "grant_type" => "authorization_code",
        "code" => code,
        "redirect_uri" => redirect_uri,
        "client_id" => client.id,
        "client_secret" => client.secret,
        "code_verifier" => verifier
      })

    body = json_response(conn, 200)
    assert body["access_token"]
    assert body["id_token"]
    assert body["token_type"]
    assert body["expires_in"]

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{body["access_token"]}")
      |> get(~p"/oauth/userinfo")

    userinfo = json_response(conn, 200)
    assert userinfo["sub"]
    assert userinfo["preferred_username"]
  end
end
