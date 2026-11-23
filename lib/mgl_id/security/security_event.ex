defmodule MglId.Security.SecurityEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "security_events" do
    field :event_type, :string
    field :ip_address, :string
    field :metadata, :map, default: %{}
    belongs_to :user, MglId.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:user_id, :event_type, :ip_address, :metadata])
    |> validate_required([:event_type])
  end
end
