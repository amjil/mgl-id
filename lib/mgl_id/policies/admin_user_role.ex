defmodule MglId.Policies.AdminUserRole do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "admin_user_roles" do
    belongs_to :user, MglId.Accounts.User
    belongs_to :role, MglId.Policies.AdminRole

    timestamps(updated_at: false)
  end

  def changeset(join, attrs) do
    join
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
    |> unique_constraint([:user_id, :role_id])
  end
end
