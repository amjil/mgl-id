defmodule MglId.Security.LoginAttempt do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "login_attempts" do
    field :username_normalized, :string
    field :ip_address, :string
    field :success, :boolean, default: false
    field :user_agent, :string

    timestamps(updated_at: false)
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [:username_normalized, :ip_address, :success, :user_agent])
    |> validate_required([:success])
  end
end
