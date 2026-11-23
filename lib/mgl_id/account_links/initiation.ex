defmodule MglId.AccountLinks.Initiation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "account_link_initiations" do
    field :provider, :string
    field :token_hash, :string
    field :nonce, :string
    field :expires_at, :utc_datetime_usec
    field :consumed_at, :utc_datetime_usec
    field :oauth_client_id, :string
    field :redirect_url, :string
    field :metadata, :map, default: %{}

    belongs_to :user, MglId.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(initiation, attrs) do
    initiation
    |> cast(attrs, [
      :user_id,
      :provider,
      :token_hash,
      :nonce,
      :expires_at,
      :consumed_at,
      :oauth_client_id,
      :redirect_url,
      :metadata
    ])
    |> validate_required([:user_id, :provider, :token_hash, :nonce, :expires_at])
    |> unique_constraint(:token_hash)
  end

  def usable?(%__MODULE__{consumed_at: nil, expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  def usable?(%__MODULE__{}), do: false
end
