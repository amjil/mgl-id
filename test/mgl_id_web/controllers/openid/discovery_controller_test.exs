defmodule MglIdWeb.Openid.DiscoveryControllerTest do
  use MglIdWeb.ConnCase, async: true

  test "GET /.well-known/openid-configuration", %{conn: conn} do
    conn = get(conn, ~p"/.well-known/openid-configuration")
    body = json_response(conn, 200)

    assert body["issuer"] == "https://id.amjil.net"
    assert body["authorization_endpoint"] =~ "/oauth/authorize"
    assert body["token_endpoint"] =~ "/oauth/token"
    assert body["jwks_uri"] =~ "/.well-known/jwks.json"
    assert "code" in body["response_types_supported"]
    assert "S256" in body["code_challenge_methods_supported"]
    assert "RS256" in body["id_token_signing_alg_values_supported"]
  end

  test "GET /.well-known/jwks.json", %{conn: conn} do
    conn = get(conn, ~p"/.well-known/jwks.json")
    assert %{"keys" => keys} = json_response(conn, 200)
    assert is_list(keys)
  end
end
