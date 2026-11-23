defmodule Mix.Tasks.MglId.RotateSigningKeys do
  @shortdoc "Rotate Boruta client RSA key pairs (JWKS drill)"
  @moduledoc """
  Regenerates ID-token signing key pairs for every OAuth client and
  publishes new keys via JWKS. Keep old tokens verifiable until they expire
  by overlapping TTL windows (short access/id tokens).

      mix mgl_id.rotate_signing_keys
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.config")
    {:ok, _} = Application.ensure_all_started(:mgl_id)

    %{rotated: count, results: results} = MglId.Ops.rotate_all_client_signing_keys!()

    Mix.shell().info("Rotated signing keys for #{count} client(s)")

    for result <- results do
      case result do
        {:ok, id} -> Mix.shell().info("  ok  #{id}")
        {:error, id, reason} -> Mix.shell().error("  fail #{id}: #{inspect(reason)}")
      end
    end

    Mix.shell().info("Verify: GET /.well-known/jwks.json shows new kid values")
  end
end
