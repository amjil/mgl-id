defmodule MglIdWeb.Api.V1.AccountLinkControllerTest do
  use MglIdWeb.ConnCase, async: false

  alias MglId.{AccountLinks, Clients, Fixtures, Sessions}
  alias MglIdWeb.UserAuth

  setup %{conn: conn} do
    [xamt, _nomio] = Clients.seed_product_clients!()
    password = Fixtures.valid_password()
    {:ok, user} = Fixtures.register_user(%{password: password})
    {:ok, _session, token} = Sessions.create_session(user, %{})

    conn =
      conn
      |> init_test_session(%{})
      |> UserAuth.log_in_user(token)

    {:ok, conn: conn, user: user, password: password, xamt: xamt}
  end

  test "initiate and list links", %{conn: conn, xamt: xamt} do
    conn = post(conn, ~p"/api/v1/account-links/initiations", %{provider: "xamt"})
    body = json_response(conn, 201)
    assert body["data"]["token"]
    assert body["data"]["redirect_url"]

    token = body["data"]["token"]

    confirm_conn =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/v1/account-links/confirm", %{
        client_id: xamt.id,
        client_secret: xamt.secret,
        initiation_token: token,
        external_user_id: "api-ext-1"
      })

    confirm_body = json_response(confirm_conn, 200)
    assert confirm_body["data"]["user_id"]
    assert confirm_body["data"]["amjil_user_id"]

    conn = get(conn, ~p"/api/v1/account-links")
    list = json_response(conn, 200)
    assert length(list["data"]) == 1
    assert hd(list["data"])["provider"] == "xamt"
  end

  test "confirm with basic auth", %{conn: conn, xamt: xamt} do
    conn = post(conn, ~p"/api/v1/account-links/initiations", %{provider: "xamt"})
    token = json_response(conn, 201)["data"]["token"]

    basic = Base.encode64("#{xamt.id}:#{xamt.secret}")

    confirm_conn =
      build_conn()
      |> put_req_header("authorization", "Basic #{basic}")
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/v1/account-links/confirm", %{
        initiation_token: token,
        external_user_id: "basic-ext"
      })

    assert json_response(confirm_conn, 200)["data"]["link"]["external_user_id"] == "basic-ext"
  end

  test "unlink with password", %{conn: conn, user: user, password: password, xamt: xamt} do
    {:ok, init} = AccountLinks.initiate(user, "xamt")

    {:ok, link} =
      AccountLinks.confirm(xamt.id, xamt.secret, %{
        "initiation_token" => init.token,
        "external_user_id" => "del-me"
      })

    conn = delete(conn, ~p"/api/v1/account-links/#{link.id}", %{password: password})
    assert json_response(conn, 200)["data"] == %{}
    assert AccountLinks.list_for_user(user.id) == []
  end
end
