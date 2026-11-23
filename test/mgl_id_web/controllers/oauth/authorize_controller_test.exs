defmodule MglIdWeb.Oauth.AuthorizeControllerTest do
  use MglIdWeb.ConnCase, async: false

  alias MglId.{Clients, Fixtures}
  alias MglIdWeb.UserAuth

  setup do
    client = Clients.seed_dev_client!()
    {:ok, user} = Fixtures.register_user(%{username: Fixtures.unique_username()})

    {:ok, client: client, user: user}
  end

  test "authorize redirects anonymous users to login", %{conn: conn, client: client} do
    conn =
      get(conn, ~p"/oauth/authorize", %{
        "response_type" => "code",
        "client_id" => client.id,
        "redirect_uri" => hd(client.redirect_uris),
        "scope" => "openid profile",
        "state" => "xyz",
        "code_challenge" =>
          :crypto.hash(:sha256, "verifier-1234567890") |> Base.url_encode64(padding: false),
        "code_challenge_method" => "S256"
      })

    assert redirected_to(conn) == "/login"
  end

  test "authorize redirects logged-in users to consent", %{conn: conn, client: client, user: user} do
    {:ok, _session, token} =
      MglId.Sessions.create_session(user, %{ip_address: "127.0.0.1"})

    conn =
      conn
      |> init_test_session(%{})
      |> UserAuth.log_in_user(token)
      |> get(~p"/oauth/authorize", %{
        "response_type" => "code",
        "client_id" => client.id,
        "redirect_uri" => hd(client.redirect_uris),
        "scope" => "openid",
        "state" => "xyz",
        "code_challenge" =>
          :crypto.hash(:sha256, "verifier-1234567890") |> Base.url_encode64(padding: false),
        "code_challenge_method" => "S256"
      })

    assert redirected_to(conn) =~ "/oauth/consent"
  end
end
