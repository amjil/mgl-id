defmodule MglId.Repo do
  use Ecto.Repo,
    otp_app: :mgl_id,
    adapter: Ecto.Adapters.Postgres
end
