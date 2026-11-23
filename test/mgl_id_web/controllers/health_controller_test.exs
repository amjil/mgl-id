defmodule MglIdWeb.HealthControllerTest do
  use MglIdWeb.ConnCase

  test "GET /health returns ok when database is up", %{conn: conn} do
    conn = get(conn, ~p"/health")

    assert %{"status" => "ok", "service" => "mgl-id", "checks" => checks} =
             json_response(conn, 200)

    assert checks["database"] == true
  end

  test "GET /health/live is liveness only", %{conn: conn} do
    conn = get(conn, ~p"/health/live")
    body = json_response(conn, 200)
    assert body["status"] == "ok"
    refute Map.has_key?(body, "checks")
  end

  test "GET /health/ready includes dependency checks", %{conn: conn} do
    conn = get(conn, ~p"/health/ready")

    assert %{"status" => "ok", "checks" => %{"database" => true, "oban" => true}} =
             json_response(conn, 200)
  end

  test "security headers are present", %{conn: conn} do
    conn = get(conn, ~p"/health/live")
    assert get_resp_header(conn, "x-frame-options") == ["DENY"]
    assert get_resp_header(conn, "x-content-type-options") == ["nosniff"]
    assert get_resp_header(conn, "content-security-policy") != []
  end
end
