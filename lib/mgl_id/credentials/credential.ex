defmodule MglId.Credentials.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "credentials" do
    field :type, :string, default: "password"
    field :secret_hash, :string
    field :password, :string, virtual: true
    belongs_to :user, MglId.Accounts.User

    timestamps()
  end

  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:type, :secret_hash, :user_id])
    |> validate_required([:type, :secret_hash, :user_id])
    |> unique_constraint([:user_id, :type])
  end
end
