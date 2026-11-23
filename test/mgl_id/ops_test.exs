defmodule MglId.OpsTest do
  use MglId.DataCase, async: false

  alias MglId.{Clients, Ops}

  test "go_live_checklist reports missing required env" do
    report =
      Ops.go_live_checklist(%{
        "OIDC_ISSUER" => "https://id.amjil.net",
        "PHX_HOST" => "id.amjil.net"
      })

    assert "DATABASE_URL" in report.missing_required
    assert "SECRET_KEY_BASE" in report.missing_required
    refute report.ready?
  end

  test "go_live_checklist ready when required env present and db up" do
    report =
      Ops.go_live_checklist(%{
        "DATABASE_URL" => "ecto://local/db",
        "SECRET_KEY_BASE" => String.duplicate("x", 64),
        "PHX_HOST" => "id.amjil.net",
        "OIDC_ISSUER" => "https://id.amjil.net"
      })

    assert report.missing_required == []
    assert report.ready?
  end

  test "health_detail includes database and oban" do
    detail = Ops.health_detail()
    assert detail.status == "ok"
    assert detail.checks.database
    assert detail.checks.oban
  end

  test "rotate_all_client_signing_keys regenerates pairs" do
    client = Clients.seed_dev_client!()
    before_kid = client.id

    %{rotated: n} = Ops.rotate_all_client_signing_keys!()
    assert n >= 1

    updated = Clients.get_client!(before_kid)
    assert updated.public_key
    # key material should change after rotation
    assert updated.public_key != client.public_key or updated.private_key != client.private_key
  end
end
