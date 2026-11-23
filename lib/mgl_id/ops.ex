defmodule MglId.Ops do
  @moduledoc """
  Production readiness helpers: config checks, key rotation drills, health detail.
  """

  alias Boruta.Ecto.Admin
  alias MglId.Repo

  @required_prod_env ~w(
    DATABASE_URL
    SECRET_KEY_BASE
    PHX_HOST
    OIDC_ISSUER
  )

  @recommended_prod_env ~w(
    TOKEN_ENCRYPTION_KEY
    CONTACT_HMAC_KEY
    SMTP_HOST
    SMTP_USERNAME
    SMTP_PASSWORD
    POOL_SIZE
  )

  def required_env_vars, do: @required_prod_env
  def recommended_env_vars, do: @recommended_prod_env

  @doc """
  Return go-live checklist status for current process environment.
  """
  def go_live_checklist(env \\ System.get_env()) do
    required =
      Enum.map(@required_prod_env, fn key ->
        %{key: key, present: present?(env, key), severity: :required}
      end)

    recommended =
      Enum.map(@recommended_prod_env, fn key ->
        %{key: key, present: present?(env, key), severity: :recommended}
      end)

    issuer = Map.get(env, "OIDC_ISSUER") || Application.get_env(:mgl_id, :oidc_issuer)
    host = Map.get(env, "PHX_HOST")

    checks = [
      %{
        id: "issuer_https",
        ok: is_binary(issuer) and String.starts_with?(issuer, "https://"),
        detail: "OIDC issuer uses https",
        blocking: true
      },
      %{
        id: "host_set",
        ok: is_binary(host) and host not in ["", "example.com", "localhost"],
        detail: "PHX_HOST is a real production hostname",
        blocking: true
      },
      %{
        id: "force_ssl",
        ok: force_ssl_configured?(),
        detail: "Endpoint force_ssl enabled (compile-time prod)",
        blocking: false
      },
      %{
        id: "database",
        ok: match?(:ok, db_ping()),
        detail: "Database reachable",
        blocking: true
      }
    ]

    missing_required = Enum.reject(required, & &1.present)
    blocking_failed = Enum.reject(checks, &(&1.ok or not &1.blocking))

    %{
      ready?: missing_required == [] and blocking_failed == [],
      required: required,
      recommended: recommended,
      checks: checks,
      missing_required: Enum.map(missing_required, & &1.key)
    }
  end

  @doc "Rotate RSA key pairs for all Boruta clients (JWKS kid rotation drill)."
  def rotate_all_client_signing_keys! do
    clients = Admin.list_clients()

    results =
      Enum.map(clients, fn client ->
        case Admin.regenerate_client_key_pair(client) do
          {:ok, updated} -> {:ok, updated.id}
          {:error, reason} -> {:error, client.id, reason}
        end
      end)

    %{rotated: Enum.count(results, &match?({:ok, _}, &1)), results: results}
  end

  def health_detail do
    db = db_ping()
    oban = oban_ok?()

    %{
      status: if(db == :ok and oban, do: "ok", else: "degraded"),
      service: "mgl-id",
      checks: %{
        database: db == :ok,
        oban: oban
      },
      time: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc "Periodic telemetry for DB pool saturation (called by Telemetry poller)."
  def emit_pool_telemetry do
    case Repo.config() |> Keyword.get(:pool_size) do
      size when is_integer(size) ->
        :telemetry.execute([:mgl_id, :repo, :pool], %{size: size}, %{})

      _ ->
        :ok
    end

    :ok
  end

  defp present?(env, key) do
    case Map.get(env, key) do
      nil -> false
      "" -> false
      _ -> true
    end
  end

  defp force_ssl_configured? do
    case Application.get_env(:mgl_id, MglIdWeb.Endpoint)[:force_ssl] do
      nil -> false
      false -> false
      _ -> true
    end
  end

  defp db_ping do
    case Ecto.Adapters.SQL.query(Repo, "SELECT 1", []) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  rescue
    e -> {:error, e}
  end

  defp oban_ok? do
    case Application.get_env(:mgl_id, Oban) do
      opts when is_list(opts) ->
        if opts[:testing] in [:manual, :inline] do
          true
        else
          case Process.whereis(Oban) do
            pid when is_pid(pid) -> Process.alive?(pid)
            _ -> false
          end
        end

      _ ->
        false
    end
  end
end
