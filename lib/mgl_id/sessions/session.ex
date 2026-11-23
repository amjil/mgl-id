defmodule MglId.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "sessions" do
    field :session_token_hash, :string
    field :device_name, :string
    field :ip_address, :string
    field :user_agent, :string
    field :last_active_at, :utc_datetime_usec
    field :expires_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    belongs_to :user, MglId.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [
      :user_id,
      :session_token_hash,
      :device_name,
      :ip_address,
      :user_agent,
      :last_active_at,
      :expires_at,
      :revoked_at
    ])
    |> validate_required([:user_id, :session_token_hash, :expires_at])
    |> unique_constraint(:session_token_hash)
  end

  def active?(%__MODULE__{revoked_at: nil, expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  def active?(%__MODULE__{}), do: false
end
