defmodule MglId.Audit.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :binary_id
    field :ip_address, :string
    field :metadata, :map, default: %{}
    belongs_to :actor, MglId.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:actor_id, :action, :resource_type, :resource_id, :ip_address, :metadata])
    |> validate_required([:action])
  end
end
