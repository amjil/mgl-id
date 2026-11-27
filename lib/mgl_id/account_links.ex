defmodule MglId.AccountLinks do
  @moduledoc """
  Link-mode product account association (Xamt, Nomio, …).

  Ownership must be proven by the product backend before a link is written.
  Never auto-merge by username or email.
  """

  import Ecto.Query

  alias Boruta.Ecto.Admin
  alias MglId.AccountLinks.{AccountLink, Initiation}
  alias MglId.{Audit, Clients, Credentials, Crypto, Repo}
  alias MglId.Accounts.User

  @initiation_ttl_seconds 600
  @known_providers ~w(xamt nomio)

  def known_providers, do: @known_providers

  def providers_config do
    Application.get_env(:mgl_id, :account_link_providers, default_providers())
  end

  def provider_config(provider) when is_binary(provider) do
    Map.get(providers_config(), provider)
  end

  def list_for_user(user_id) do
    Repo.all(
      from l in AccountLink,
        where: l.user_id == ^user_id and is_nil(l.unlinked_at),
        order_by: [asc: l.provider]
    )
  end

  def get_active_link(user_id, provider) do
    Repo.one(
      from l in AccountLink,
        where: l.user_id == ^user_id and l.provider == ^provider and is_nil(l.unlinked_at)
    )
  end

  def get_by_external(provider, external_user_id) do
    Repo.one(
      from l in AccountLink,
        where:
          l.provider == ^provider and l.external_user_id == ^external_user_id and
            is_nil(l.unlinked_at)
    )
  end

  @doc """
  Start a one-time linking flow for the signed-in Amjil ID user.
  Returns plaintext `token` once for redirect to the product.
  """
  def initiate(%User{} = user, provider, meta \\ %{}) when is_binary(provider) do
    with :ok <- validate_provider(provider),
         :ok <- ensure_not_already_linked(user.id, provider),
         cfg when is_map(cfg) <- provider_config(provider) do
      token = Crypto.generate_token()
      nonce = Crypto.generate_token(16)
      now = DateTime.utc_now()
      expires_at = DateTime.add(now, @initiation_ttl_seconds, :second)
      redirect_url = build_redirect_url(cfg, token, provider)

      attrs = %{
        user_id: user.id,
        provider: provider,
        token_hash: Crypto.hash_token(token),
        nonce: nonce,
        expires_at: expires_at,
        oauth_client_id: resolve_oauth_client_id(cfg),
        redirect_url: redirect_url,
        metadata: %{
          "ip_address" => Map.get(meta, :ip_address) || Map.get(meta, "ip_address")
        }
      }

      case %Initiation{} |> Initiation.changeset(attrs) |> Repo.insert() do
        {:ok, initiation} ->
          _ =
            Audit.log("account.link.initiate", %{
              actor_id: user.id,
              resource_type: "account_link_initiation",
              resource_id: initiation.id,
              ip_address: Map.get(meta, :ip_address),
              metadata: %{provider: provider}
            })

          {:ok,
           %{
             initiation: initiation,
             token: token,
             nonce: nonce,
             provider: provider,
             redirect_url: redirect_url,
             expires_at: expires_at
           }}

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      nil -> {:error, :invalid_provider}
      {:error, _} = err -> err
    end
  end

  @doc """
  Product backend confirms ownership. Requires OAuth client credentials.
  Body: initiation_token, external_user_id, optional nonce, optional status.
  """
  def confirm(client_id, client_secret, params) when is_map(params) do
    token = params["initiation_token"] || params[:initiation_token]
    external_user_id = params["external_user_id"] || params[:external_user_id]
    nonce = params["nonce"] || params[:nonce]
    status = params["external_account_status"] || params[:external_account_status] || "active"

    with :ok <- require_binaries(token, external_user_id),
         {:ok, client} <- authenticate_client(client_id, client_secret),
         {:ok, provider} <- provider_for_client(client),
         {:ok, initiation} <- fetch_usable_initiation(token),
         :ok <- match_provider(initiation, provider),
         :ok <- match_nonce(initiation, nonce),
         :ok <- match_client(initiation, client),
         :ok <- external_account_allowed(status),
         {:ok, link} <- create_link_in_transaction(initiation, external_user_id, client) do
      _ =
        Audit.log("account.link.success", %{
          actor_id: initiation.user_id,
          resource_type: "account_link",
          resource_id: link.id,
          metadata: %{
            provider: provider,
            oauth_client_id: client.id
          }
        })

      _ = MglId.Metrics.emit("account.link.success", %{provider: provider})

      {:ok, link}
    else
      {:error, reason} = err ->
        _ =
          Audit.log("account.link.failure", %{
            metadata: %{
              reason: inspect(reason),
              client_id: client_id
            }
          })

        _ = MglId.Metrics.emit("account.link.failure")

        err
    end
  end

  def unlink(%User{} = user, link_id, password) when is_binary(password) do
    with {:auth, true} <- {:auth, Credentials.valid_password?(user.id, password)},
         %AccountLink{} = link <- Repo.get_by(AccountLink, id: link_id, user_id: user.id),
         {:active, true} <- {:active, AccountLink.active?(link)} do
      now = DateTime.utc_now()

      case link |> AccountLink.changeset(%{unlinked_at: now}) |> Repo.update() do
        {:ok, link} ->
          _ =
            Audit.log("account.link.unlink", %{
              actor_id: user.id,
              resource_type: "account_link",
              resource_id: link.id,
              metadata: %{provider: link.provider}
            })

          {:ok, link}

        other ->
          other
      end
    else
      {:auth, false} -> {:error, :invalid_credentials}
      nil -> {:error, :not_found}
      {:active, false} -> {:error, :not_found}
    end
  end

  def migration_stats do
    active =
      from(l in AccountLink, where: is_nil(l.unlinked_at))
      |> group_by_provider()

    unlinked =
      from(l in AccountLink, where: not is_nil(l.unlinked_at))
      |> group_by_provider()

    pending_initiations =
      Repo.one(
        from i in Initiation,
          where: is_nil(i.consumed_at) and i.expires_at > ^DateTime.utc_now(),
          select: count(i.id)
      )

    %{
      providers: @known_providers,
      linked_by_provider: active,
      unlinked_by_provider: unlinked,
      pending_initiations: pending_initiations || 0,
      linked_total: Map.values(active) |> Enum.sum()
    }
  end

  defp group_by_provider(query) do
    Repo.all(from l in query, group_by: l.provider, select: {l.provider, count(l.id)})
    |> Map.new()
  end

  defp default_providers do
    %{
      "xamt" => %{
        name: "Xamt",
        link_start_url: "http://100.64.0.8:4002/account/link",
        oauth_client_name: "Xamt"
      },
      "nomio" => %{
        name: "Nomio",
        link_start_url: "http://100.64.0.6:4000/account/link",
        oauth_client_name: "Nomio"
      }
    }
  end

  defp validate_provider(provider) do
    if provider in @known_providers and is_map(provider_config(provider)) do
      :ok
    else
      {:error, :invalid_provider}
    end
  end

  defp ensure_not_already_linked(user_id, provider) do
    case get_active_link(user_id, provider) do
      nil -> :ok
      %AccountLink{} = link -> {:error, {:account_link_exists, %{link_id: link.id}}}
    end
  end

  defp resolve_oauth_client_id(cfg) do
    cond do
      is_binary(Map.get(cfg, :oauth_client_id)) ->
        Map.get(cfg, :oauth_client_id)

      is_binary(Map.get(cfg, :oauth_client_name)) ->
        name = Map.get(cfg, :oauth_client_name)

        Clients.list_clients()
        |> Enum.find(&(&1.name == name))
        |> case do
          nil -> nil
          client -> client.id
        end

      true ->
        nil
    end
  end

  defp build_redirect_url(cfg, token, provider) do
    base = Map.fetch!(cfg, :link_start_url)
    uri = URI.parse(base)

    query =
      (uri.query || "")
      |> URI.decode_query()
      |> Map.merge(%{"token" => token, "provider" => provider})
      |> URI.encode_query()

    URI.to_string(%{uri | query: query})
  end

  defp require_binaries(token, external_user_id) do
    if is_binary(token) and token != "" and is_binary(external_user_id) and
         external_user_id != "" do
      :ok
    else
      {:error, :invalid_params}
    end
  end

  defp authenticate_client(client_id, client_secret)
       when is_binary(client_id) and is_binary(client_secret) do
    try do
      client = Admin.get_client!(client_id)

      if secure_secret_match?(client.secret, client_secret) do
        {:ok, client}
      else
        {:error, :invalid_client}
      end
    rescue
      Ecto.NoResultsError -> {:error, :invalid_client}
    end
  end

  defp authenticate_client(_, _), do: {:error, :invalid_client}

  defp secure_secret_match?(stored, provided)
       when is_binary(stored) and is_binary(provided) do
    Plug.Crypto.secure_compare(stored, provided)
  end

  defp secure_secret_match?(_, _), do: false

  defp provider_for_client(client) do
    meta = client.metadata || %{}

    provider =
      Map.get(meta, "provider") || Map.get(meta, :provider) ||
        provider_from_name(client.name)

    if provider in @known_providers do
      {:ok, provider}
    else
      {:error, :invalid_client}
    end
  end

  defp provider_from_name(name) when is_binary(name) do
    Enum.find(@known_providers, fn p ->
      String.downcase(name) == p or String.downcase(name) == String.capitalize(p)
    end)
  end

  defp provider_from_name(_), do: nil

  defp fetch_usable_initiation(token) do
    hash = Crypto.hash_token(token)

    case Repo.get_by(Initiation, token_hash: hash) do
      %Initiation{} = initiation ->
        if Initiation.usable?(initiation) do
          {:ok, initiation}
        else
          if initiation.consumed_at do
            {:error, :account_link_expired}
          else
            {:error, :account_link_expired}
          end
        end

      nil ->
        {:error, :account_link_expired}
    end
  end

  defp match_provider(%Initiation{provider: provider}, provider), do: :ok
  defp match_provider(_, _), do: {:error, :account_link_conflict}

  defp match_nonce(_initiation, nil), do: :ok
  defp match_nonce(_initiation, ""), do: :ok

  defp match_nonce(%Initiation{nonce: nonce}, nonce), do: :ok
  defp match_nonce(_, _), do: {:error, :account_link_expired}

  defp match_client(%Initiation{oauth_client_id: nil}, _client), do: :ok
  defp match_client(%Initiation{oauth_client_id: id}, %{id: id}), do: :ok
  defp match_client(_, _), do: {:error, :invalid_client}

  defp external_account_allowed(status) when status in ["active", :active, nil], do: :ok
  defp external_account_allowed("disabled"), do: {:error, :account_disabled}
  defp external_account_allowed(:disabled), do: {:error, :account_disabled}
  defp external_account_allowed("suspended"), do: {:error, :account_suspended}
  defp external_account_allowed(:suspended), do: {:error, :account_suspended}
  defp external_account_allowed(_), do: {:error, :account_disabled}

  defp create_link_in_transaction(initiation, external_user_id, client) do
    Repo.transaction(fn ->
      initiation =
        initiation
        |> Initiation.changeset(%{consumed_at: DateTime.utc_now()})
        |> Repo.update!()

      case get_by_external(initiation.provider, external_user_id) do
        %AccountLink{user_id: uid} = existing when uid == initiation.user_id ->
          existing

        %AccountLink{} ->
          Repo.rollback(:account_link_conflict)

        nil ->
          case get_active_link(initiation.user_id, initiation.provider) do
            %AccountLink{} ->
              Repo.rollback(:account_link_conflict)

            nil ->
              %AccountLink{}
              |> AccountLink.changeset(%{
                user_id: initiation.user_id,
                provider: initiation.provider,
                external_user_id: external_user_id,
                linked_at: DateTime.utc_now(),
                oauth_client_id: client.id,
                metadata: %{"initiation_id" => initiation.id}
              })
              |> Repo.insert()
              |> case do
                {:ok, link} -> link
                {:error, changeset} -> Repo.rollback(changeset_to_reason(changeset))
              end
          end
      end
    end)
    |> case do
      {:ok, link} -> {:ok, link}
      {:error, reason} -> {:error, reason}
    end
  end

  defp changeset_to_reason(%Ecto.Changeset{} = changeset) do
    if Keyword.has_key?(changeset.errors, :provider) or
         Keyword.has_key?(changeset.errors, :external_user_id) or
         Keyword.has_key?(changeset.errors, :user_id) do
      :account_link_conflict
    else
      :account_link_conflict
    end
  end

  defp changeset_to_reason(other), do: other
end
