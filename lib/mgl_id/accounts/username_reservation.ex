defmodule MglId.Accounts.UsernameReservation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "username_reservations" do
    field :username_normalized, :string
    field :reason, :string
    field :expires_at, :utc_datetime_usec
    belongs_to :user, MglId.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, [:username_normalized, :reason, :user_id, :expires_at])
    |> validate_required([:username_normalized, :reason])
    |> unique_constraint(:username_normalized)
  end
end
