defmodule MglId.Metrics do
  @moduledoc """
  Telemetry helpers for security/ops events. Never attach secrets as tags.
  """

  @known %{
    "auth.login.success" => :auth_login_success,
    "auth.login.failure" => :auth_login_failure,
    "auth.register.success" => :auth_register_success,
    "auth.register.rejected" => :auth_register_rejected,
    "oauth.authorize.success" => :oauth_authorize_success,
    "oauth.token.exchange.failure" => :oauth_token_exchange_failure,
    "oauth.refresh.replay" => :oauth_refresh_replay,
    "account.link.success" => :account_link_success,
    "account.link.failure" => :account_link_failure,
    "security.account.suspended" => :security_account_suspended
  }

  @doc "Emit a counted security/ops event."
  def emit(event, meta \\ %{})

  def emit(event, meta) when is_atom(event) do
    :telemetry.execute([:mgl_id, :security, event], %{count: 1}, scrub(meta))
    :ok
  end

  def emit(event, meta) when is_binary(event) do
    case Map.fetch(@known, event) do
      {:ok, atom} -> emit(atom, meta)
      :error -> emit(:unknown_event, Map.put(scrub(meta), :event_name, event))
    end
  end

  defp scrub(meta) when is_map(meta) do
    Map.drop(meta, [
      :password,
      :token,
      :secret,
      :client_secret,
      :authorization,
      "password",
      "token",
      "secret",
      "client_secret"
    ])
  end

  defp scrub(_), do: %{}
end
