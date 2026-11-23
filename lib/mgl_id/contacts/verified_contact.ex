defmodule MglId.Contacts.VerifiedContact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "verified_contacts" do
    field :type, :string
    field :value_encrypted, :string
    field :value_hash, :string
    field :verified_at, :utc_datetime_usec
    field :is_primary, :boolean, default: false
    belongs_to :user, MglId.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:type, :value_encrypted, :value_hash, :verified_at, :is_primary, :user_id])
    |> validate_required([:type, :value_encrypted, :value_hash, :user_id])
    |> validate_inclusion(:type, ~w(email phone))
    |> unique_constraint([:type, :value_hash])
  end
end
