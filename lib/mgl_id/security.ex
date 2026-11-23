defmodule MglId.Security do
  @moduledoc """
  Rate limiting, login attempts, and security events.
  """

  import Ecto.Query

  alias MglId.Repo
  alias MglId.Security.{LoginAttempt, SecurityEvent}

  @table :mgl_id_rate_limits

  def ensure_ets! do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])

      _ ->
        @table
    end
  end

  @doc "Clear rate-limit buckets (tests)."
  def reset_rate_limits! do
    ensure_ets!()
    :ets.delete_all_objects(@table)
    :ok
  end

  @doc """
  Simple sliding-window rate limit. Returns `:ok` or `{:error, :rate_limited}`.
  """
  def check_rate_limit(bucket, limit, window_ms \\ 60_000) do
    ensure_ets!()
    now = System.system_time(:millisecond)
    key = {bucket, div(now, window_ms)}

    count =
      case :ets.update_counter(@table, key, {2, 1}, {key, 0}) do
        n when is_integer(n) -> n
      end

    if count > limit, do: {:error, :rate_limited}, else: :ok
  end

  def record_login_attempt(attrs) do
    %LoginAttempt{}
    |> LoginAttempt.changeset(attrs)
    |> Repo.insert()
  end

  def record_event(event_type, attrs \\ %{}) do
    %SecurityEvent{}
    |> SecurityEvent.changeset(
      Map.merge(attrs, %{event_type: event_type, metadata: Map.get(attrs, :metadata, %{})})
    )
    |> Repo.insert()
  end

  def recent_registration_count(ip_address, minutes \\ 60) do
    since = DateTime.add(DateTime.utc_now(), -minutes * 60, :second)

    # Approximate using audit logs for register success from same IP
    from(a in MglId.Audit.AuditLog,
      where: a.action == "auth.register.success",
      where: a.ip_address == ^ip_address,
      where: a.inserted_at > ^since
    )
    |> Repo.aggregate(:count, :id)
  end

  def recent_failed_logins(username_normalized, minutes \\ 15) do
    since = DateTime.add(DateTime.utc_now(), -minutes * 60, :second)

    from(a in LoginAttempt,
      where: a.username_normalized == ^username_normalized,
      where: a.success == false,
      where: a.inserted_at > ^since
    )
    |> Repo.aggregate(:count, :id)
  end
end
