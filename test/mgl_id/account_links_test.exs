defmodule MglId.AccountLinksTest do
  use MglId.DataCase, async: false

  alias MglId.{AccountLinks, Clients, Fixtures}

  setup do
    [xamt, nomio] = Clients.seed_product_clients!()
    password = Fixtures.valid_password()
    {:ok, user} = Fixtures.register_user(%{password: password})

    {:ok, user: user, password: password, xamt: xamt, nomio: nomio}
  end

  test "initiate + confirm creates a unique link", %{user: user, xamt: xamt} do
    {:ok, init} = AccountLinks.initiate(user, "xamt")
    assert init.token
    assert init.redirect_url =~ "token="
    assert init.redirect_url =~ "provider=xamt"

    {:ok, link} =
      AccountLinks.confirm(xamt.id, xamt.secret, %{
        "initiation_token" => init.token,
        "external_user_id" => "xamt-user-1",
        "nonce" => init.nonce
      })

    assert link.provider == "xamt"
    assert link.external_user_id == "xamt-user-1"
    assert link.user_id == user.id
    assert AccountLinks.get_by_external("xamt", "xamt-user-1").id == link.id
  end

  test "rejects linking external id already owned by another user", %{
    user: user,
    xamt: xamt,
    password: password
  } do
    {:ok, other} = Fixtures.register_user(%{password: password})
    {:ok, init1} = AccountLinks.initiate(user, "xamt")

    {:ok, _} =
      AccountLinks.confirm(xamt.id, xamt.secret, %{
        "initiation_token" => init1.token,
        "external_user_id" => "shared-ext"
      })

    {:ok, init2} = AccountLinks.initiate(other, "xamt")

    assert {:error, :account_link_conflict} =
             AccountLinks.confirm(xamt.id, xamt.secret, %{
               "initiation_token" => init2.token,
               "external_user_id" => "shared-ext"
             })
  end

  test "rejects second active link for same user+provider", %{
    user: user,
    xamt: xamt
  } do
    {:ok, init1} = AccountLinks.initiate(user, "xamt")

    {:ok, _} =
      AccountLinks.confirm(xamt.id, xamt.secret, %{
        "initiation_token" => init1.token,
        "external_user_id" => "a"
      })

    assert {:error, {:account_link_exists, _}} = AccountLinks.initiate(user, "xamt")
  end

  test "rejects reused initiation token", %{user: user, xamt: xamt} do
    {:ok, init} = AccountLinks.initiate(user, "xamt")

    {:ok, _} =
      AccountLinks.confirm(xamt.id, xamt.secret, %{
        "initiation_token" => init.token,
        "external_user_id" => "once"
      })

    assert {:error, :account_link_expired} =
             AccountLinks.confirm(xamt.id, xamt.secret, %{
               "initiation_token" => init.token,
               "external_user_id" => "once"
             })
  end

  test "rejects wrong client for provider", %{user: user, nomio: nomio} do
    {:ok, init} = AccountLinks.initiate(user, "xamt")

    assert {:error, _} =
             AccountLinks.confirm(nomio.id, nomio.secret, %{
               "initiation_token" => init.token,
               "external_user_id" => "x"
             })
  end

  test "rejects disabled external account", %{user: user, xamt: xamt} do
    {:ok, init} = AccountLinks.initiate(user, "xamt")

    assert {:error, :account_disabled} =
             AccountLinks.confirm(xamt.id, xamt.secret, %{
               "initiation_token" => init.token,
               "external_user_id" => "disabled-user",
               "external_account_status" => "disabled"
             })
  end

  test "unlink requires password and soft-deletes", %{
    user: user,
    password: password,
    xamt: xamt
  } do
    {:ok, init} = AccountLinks.initiate(user, "xamt")

    {:ok, link} =
      AccountLinks.confirm(xamt.id, xamt.secret, %{
        "initiation_token" => init.token,
        "external_user_id" => "to-unlink"
      })

    assert {:error, :invalid_credentials} = AccountLinks.unlink(user, link.id, "wrong")
    assert {:ok, unlinked} = AccountLinks.unlink(user, link.id, password)
    assert unlinked.unlinked_at
    assert AccountLinks.list_for_user(user.id) == []
  end

  test "migration_stats counts links", %{user: user, xamt: xamt} do
    {:ok, init} = AccountLinks.initiate(user, "xamt")

    {:ok, _} =
      AccountLinks.confirm(xamt.id, xamt.secret, %{
        "initiation_token" => init.token,
        "external_user_id" => "stats-1"
      })

    stats = AccountLinks.migration_stats()
    assert stats.linked_by_provider["xamt"] == 1
    assert stats.linked_total >= 1
  end
end
