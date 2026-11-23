defmodule MglId.ClientsTest do
  use MglId.DataCase, async: false

  alias MglId.Clients

  test "seed_dev_client creates scopes and a confidential client" do
    client = Clients.seed_dev_client!()
    assert client.name == "Mgl ID Dev Client"
    assert client.pkce == true
    assert client.confidential == true
    assert "authorization_code" in client.supported_grant_types

    # idempotent
    again = Clients.seed_dev_client!()
    assert again.id == client.id
  end

  test "seed_product_clients creates Xamt and Nomio" do
    [xamt, nomio] = Clients.seed_product_clients!()
    assert xamt.name == "Xamt"
    assert nomio.name == "Nomio"
    assert xamt.metadata["provider"] == "xamt"
    assert nomio.metadata["provider"] == "nomio"
    assert xamt.pkce == true

    again = Clients.seed_product_clients!()
    assert Enum.map(again, & &1.id) == [xamt.id, nomio.id]
  end
end
