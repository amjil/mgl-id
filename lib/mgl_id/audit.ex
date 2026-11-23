defmodule MglId.Audit do
  @moduledoc """
  Audit log writers. Must never record passwords, plaintext tokens, or secrets.
  """

  alias MglId.Audit.AuditLog
  alias MglId.Repo

  def log(action, attrs \\ %{}) when is_binary(action) do
    metadata = Map.get(attrs, :metadata, %{}) |> scrub()

    %AuditLog{}
    |> AuditLog.changeset(%{
      action: action,
      actor_id: Map.get(attrs, :actor_id),
      resource_type: Map.get(attrs, :resource_type),
      resource_id: Map.get(attrs, :resource_id),
      ip_address: Map.get(attrs, :ip_address),
      metadata: metadata
    })
    |> Repo.insert()
  end

  defp scrub(metadata) when is_map(metadata) do
    metadata
    |> Map.drop([
      :password,
      :password_confirmation,
      :token,
      :secret,
      :client_secret,
      "password",
      "token",
      "secret"
    ])
  end

  defp scrub(_), do: %{}
end
