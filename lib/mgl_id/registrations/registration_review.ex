defmodule MglId.Registrations.RegistrationReview do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "registration_reviews" do
    field :status, :string, default: "pending_review"
    field :risk_signals, :map, default: %{}
    field :reason, :string
    field :reviewed_at, :utc_datetime_usec
    belongs_to :user, MglId.Accounts.User
    belongs_to :reviewed_by, MglId.Accounts.User

    timestamps()
  end

  def changeset(review, attrs) do
    review
    |> cast(attrs, [:user_id, :status, :risk_signals, :reason, :reviewed_by_id, :reviewed_at])
    |> validate_required([:user_id, :status])
    |> validate_inclusion(:status, ~w(pending_review approved rejected))
  end
end
