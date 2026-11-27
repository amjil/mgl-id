defmodule MglId.Clients do
  @moduledoc """
  OAuth/OIDC client administration (Boruta-backed).
  """

  alias Boruta.Ecto.Admin

  def list_clients, do: Admin.list_clients()

  def get_client!(id), do: Admin.get_client!(id)

  def create_client(attrs) when is_map(attrs) do
    Admin.create_client(attrs)
  end

  def ensure_default_scopes! do
    for {name, public?} <- [
          {"openid", true},
          {"profile", true},
          {"email", true},
          {"offline_access", false}
        ] do
      case Admin.list_scopes() |> Enum.find(&(&1.name == name)) do
        nil ->
          {:ok, _} = Admin.create_scope(%{name: name, public: public?})

        _ ->
          :ok
      end
    end

    :ok
  end

  @doc """
  Create a confidential web client for local/dev integration testing.
  """
  def seed_dev_client! do
    ensure_default_scopes!()

    existing =
      list_clients()
      |> Enum.find(&(&1.name == "Mgl ID Dev Client"))

    if existing do
      existing
    else
      scopes = Admin.get_scopes_by_names(["openid", "profile", "email", "offline_access"])

      {:ok, client} =
        create_client(%{
          name: "Mgl ID Dev Client",
          redirect_uris: ["http://127.0.0.1:4001/callback", "http://localhost:4001/callback"],
          supported_grant_types: ["authorization_code", "refresh_token"],
          access_token_ttl: 600,
          authorization_code_ttl: 60,
          refresh_token_ttl: 60 * 60 * 24 * 30,
          id_token_ttl: 600,
          id_token_signature_alg: "RS256",
          pkce: true,
          confidential: true,
          authorize_scope: true,
          authorized_scopes: Enum.map(scopes, &%{id: &1.id}),
          token_endpoint_auth_methods: ["client_secret_basic", "client_secret_post"]
        })

      client
    end
  end

  @doc """
  Seed confidential OIDC clients for Xamt and Nomio (idempotent by name).
  """
  def seed_product_clients! do
    ensure_default_scopes!()

    for {name, provider, redirect_uris} <- product_client_defs() do
      seed_named_client!(name, provider, redirect_uris)
    end
  end

  def seed_named_client!(name, provider, redirect_uris)
      when is_binary(name) and is_binary(provider) and is_list(redirect_uris) do
    ensure_default_scopes!()

    existing = list_clients() |> Enum.find(&(&1.name == name))

    if existing do
      existing
      |> maybe_set_provider_metadata!(provider)
      |> maybe_sync_redirect_uris!(redirect_uris)
      |> maybe_sync_authorized_scopes!()
    else
      scopes = Admin.get_scopes_by_names(["openid", "profile", "email", "offline_access"])

      {:ok, client} =
        create_client(%{
          name: name,
          redirect_uris: redirect_uris,
          supported_grant_types: ["authorization_code", "refresh_token"],
          access_token_ttl: 600,
          authorization_code_ttl: 60,
          refresh_token_ttl: 60 * 60 * 24 * 30,
          id_token_ttl: 600,
          id_token_signature_alg: "RS256",
          pkce: true,
          confidential: true,
          authorize_scope: true,
          authorized_scopes: Enum.map(scopes, &%{id: &1.id}),
          token_endpoint_auth_methods: ["client_secret_basic", "client_secret_post"],
          metadata: %{"provider" => provider}
        })

      client
    end
  end

  defp product_client_defs do
    # Must match Xamt.MglId redirect_uri / link_redirect_uri defaults:
    # /auth/mgl/callback and /settings/account/identities/mgl/callback
    xamt_uris =
      System.get_env(
        "XAMT_REDIRECT_URIS",
        Enum.join(
          [
            "http://100.64.0.8:4002/auth/mgl/callback",
            "http://100.64.0.8:4002/settings/account/identities/mgl/callback",
            "http://localhost:4002/auth/mgl/callback",
            "http://localhost:4002/settings/account/identities/mgl/callback",
            "http://127.0.0.1:4002/auth/mgl/callback",
            "http://127.0.0.1:4002/settings/account/identities/mgl/callback"
          ],
          ","
        )
      )
      |> String.split(",", trim: true)

    # Must match Nomio.MglId redirect_uri / PUBLIC_BASE_URL (see nomio start-mgl.sh):
    # http://100.64.0.6:4000/oauth/callback
    nomio_uris =
      System.get_env(
        "NOMIO_REDIRECT_URIS",
        Enum.join(
          [
            "http://100.64.0.6:4000/oauth/callback",
            "http://localhost:4000/oauth/callback",
            "http://127.0.0.1:4000/oauth/callback"
          ],
          ","
        )
      )
      |> String.split(",", trim: true)

    [
      {"Xamt", "xamt", xamt_uris},
      {"Nomio", "nomio", nomio_uris}
    ]
  end

  defp maybe_set_provider_metadata!(client, provider) do
    meta = client.metadata || %{}

    if Map.get(meta, "provider") == provider do
      client
    else
      case Admin.update_client(client, %{metadata: Map.put(meta, "provider", provider)}) do
        {:ok, updated} -> updated
        {:error, _} -> client
      end
    end
  end

  defp maybe_sync_redirect_uris!(client, redirect_uris) do
    current = Enum.sort(client.redirect_uris || [])
    desired = Enum.sort(redirect_uris)

    if current == desired do
      client
    else
      case Admin.update_client(client, %{redirect_uris: redirect_uris}) do
        {:ok, updated} -> updated
        {:error, _} -> client
      end
    end
  end

  defp maybe_sync_authorized_scopes!(client) do
    scopes = Admin.get_scopes_by_names(["openid", "profile", "email", "offline_access"])
    current_ids = client.authorized_scopes |> Enum.map(& &1.id) |> Enum.sort()
    desired_ids = scopes |> Enum.map(& &1.id) |> Enum.sort()

    if current_ids == desired_ids do
      client
    else
      case Admin.update_client(client, %{authorized_scopes: Enum.map(scopes, &%{id: &1.id})}) do
        {:ok, updated} -> updated
        {:error, _} -> client
      end
    end
  end
end
