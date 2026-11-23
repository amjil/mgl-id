defmodule MglId.AccountLinks.AccountLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "account_links" do
    field :provider, :string
    field :external_user_id, :string
    field :linked_at, :utc_datetime_usec
    field :unlinked_at, :utc_datetime_usec
    field :oauth_client_id, :string
    field :metadata, :map, default: %{}

    belongs_to :user, MglId.Accounts.User

    timestamps()
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [
      :user_id,
      :provider,
      :external_user_id,
      :linked_at,
      :unlinked_at,
      :oauth_client_id,
      :metadata
    ])
    |> validate_required([:user_id, :provider, :external_user_id, :linked_at])
    |> validate_length(:provider, max: 64)
    |> validate_length(:external_user_id, max: 255)
    |> unique_constraint([:provider, :external_user_id],
      name: :account_links_provider_external_active_index
    )
    |> unique_constraint([:user_id, :provider], name: :account_links_user_provider_active_index)
  end

  def active?(%__MODULE__{unlinked_at: nil}), do: true
  def active?(%__MODULE__{}), do: false
end
