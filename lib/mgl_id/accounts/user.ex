defmodule MglId.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  @statuses ~w(pending active suspended disabled deletion_pending deleted)
  @trust_levels ~w(basic verified trusted)
  @review_statuses ~w(not_required pending_review approved rejected)

  schema "users" do
    field :username, :string
    field :username_normalized, :string
    field :display_name, :string
    field :avatar_url, :string
    field :bio, :string
    field :locale, :string
    field :timezone, :string
    field :status, :string, default: "active"
    field :trust_level, :string, default: "basic"
    field :review_status, :string, default: "not_required"
    field :registration_source, :string
    field :is_admin, :boolean, default: false
    field :deleted_at, :utc_datetime_usec
    field :last_login_at, :utc_datetime_usec
    field :totp_secret_encrypted, :string
    field :totp_enabled_at, :utc_datetime_usec

    has_one :credential, MglId.Credentials.Credential
    has_many :contacts, MglId.Contacts.VerifiedContact
    has_many :sessions, MglId.Sessions.Session

    timestamps()
  end

  def statuses, do: @statuses
  def trust_levels, do: @trust_levels
  def review_statuses, do: @review_statuses

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :username,
      :username_normalized,
      :display_name,
      :locale,
      :timezone,
      :status,
      :trust_level,
      :review_status,
      :registration_source,
      :is_admin
    ])
    |> validate_required([:username, :username_normalized, :status, :trust_level, :review_status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:trust_level, @trust_levels)
    |> validate_inclusion(:review_status, @review_statuses)
    |> validate_length(:display_name, max: 100)
    |> unique_constraint(:username_normalized)
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name, :avatar_url, :bio, :locale, :timezone])
    |> validate_length(:display_name, max: 100)
    |> validate_length(:bio, max: 2000)
  end

  def status_changeset(user, status) when status in @statuses do
    change(user, status: status)
  end

  def review_status_changeset(user, status) when status in @review_statuses do
    change(user, review_status: status)
  end

  def can_authenticate?(%__MODULE__{status: status}) when status in ~w(active pending), do: true
  def can_authenticate?(%__MODULE__{}), do: false

  def admin?(%__MODULE__{is_admin: true}), do: true
  def admin?(%__MODULE__{}), do: false

  def public_attrs(%__MODULE__{} = user) do
    %{
      id: user.id,
      username: user.username,
      display_name: user.display_name,
      avatar_url: user.avatar_url,
      bio: user.bio,
      locale: user.locale,
      timezone: user.timezone,
      status: user.status,
      trust_level: user.trust_level,
      review_status: user.review_status,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
