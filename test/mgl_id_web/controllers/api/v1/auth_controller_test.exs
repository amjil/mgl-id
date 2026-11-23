defmodule MglIdWeb.Api.V1.AuthControllerTest do
  use MglIdWeb.ConnCase, async: true

  alias MglId.Fixtures

  test "POST /api/v1/auth/register creates a user", %{conn: conn} do
    username = Fixtures.unique_username()

    conn =
      post(conn, ~p"/api/v1/auth/register", %{
        username: username,
        password: Fixtures.valid_password(),
        display_name: "Test"
      })

    assert %{"data" => %{"username" => ^username, "status" => "active"}} =
             json_response(conn, 201)
  end

  test "POST /api/v1/auth/login returns session and me works", %{conn: conn} do
    username = Fixtures.unique_username()
    assert {:ok, _} = Fixtures.register_user(%{username: username})

    conn =
      post(conn, ~p"/api/v1/auth/login", %{
        username: username,
        password: Fixtures.valid_password()
      })

    assert %{"data" => %{"user" => %{"username" => ^username}, "session" => %{}}} =
             json_response(conn, 200)

    conn = get(conn, ~p"/api/v1/me")
    assert %{"data" => %{"username" => ^username}} = json_response(conn, 200)
  end

  test "login failure uses unified error envelope", %{conn: conn} do
    conn =
      post(conn, ~p"/api/v1/auth/login", %{
        username: "nobody",
        password: "wrong-password-xx"
      })

    assert %{
             "error" => %{
               "code" => "INVALID_CREDENTIALS",
               "message" => _
             }
           } = json_response(conn, 422)
  end
end
