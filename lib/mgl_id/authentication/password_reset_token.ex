defmodule MglId.Authentication.PasswordResetToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "password_reset_tokens" do
    field :token_hash, :string
    field :expires_at, :utc_datetime_usec
    field :used_at, :utc_datetime_usec
    belongs_to :user, MglId.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:user_id, :token_hash, :expires_at, :used_at])
    |> validate_required([:user_id, :token_hash, :expires_at])
    |> unique_constraint(:token_hash)
  end
end
