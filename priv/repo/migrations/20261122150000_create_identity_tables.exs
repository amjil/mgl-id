defmodule MglId.Repo.Migrations.CreateIdentityTables do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, size: 32, null: false
      add :username_normalized, :string, size: 32, null: false
      add :display_name, :string, size: 100
      add :avatar_url, :text
      add :bio, :text
      add :locale, :string, size: 20
      add :timezone, :string, size: 64
      add :status, :string, size: 24, null: false, default: "active"
      add :trust_level, :string, size: 20, null: false, default: "basic"
      add :review_status, :string, size: 24, null: false, default: "not_required"
      add :registration_source, :string, size: 30
      add :is_admin, :boolean, null: false, default: false
      add :deleted_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, [:username_normalized])
    create index(:users, [:status])
    create index(:users, [:review_status])

    create constraint(:users, :users_status_check,
             check:
               "status IN ('pending','active','suspended','disabled','deletion_pending','deleted')"
           )

    create constraint(:users, :users_trust_level_check,
             check: "trust_level IN ('basic','verified','trusted')"
           )

    create constraint(:users, :users_review_status_check,
             check: "review_status IN ('not_required','pending_review','approved','rejected')"
           )

    create table(:credentials, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :type, :string, size: 30, null: false, default: "password"
      add :secret_hash, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:credentials, [:user_id, :type])

    create table(:verified_contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :type, :string, size: 20, null: false
      add :value_encrypted, :text, null: false
      add :value_hash, :text, null: false
      add :verified_at, :utc_datetime_usec
      add :is_primary, :boolean, null: false, default: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:verified_contacts, [:user_id])
    create unique_index(:verified_contacts, [:type, :value_hash])

    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :session_token_hash, :text, null: false
      add :device_name, :string
      add :ip_address, :string
      add :user_agent, :text
      add :last_active_at, :utc_datetime_usec
      add :expires_at, :utc_datetime_usec, null: false
      add :revoked_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:sessions, [:session_token_hash])
    create index(:sessions, [:user_id])

    create table(:email_verification_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token_hash, :text, null: false
      add :email_hash, :text, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :used_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:email_verification_tokens, [:token_hash])
    create index(:email_verification_tokens, [:user_id])

    create table(:password_reset_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token_hash, :text, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :used_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:password_reset_tokens, [:token_hash])
    create index(:password_reset_tokens, [:user_id])

    create table(:registration_reviews, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, size: 24, null: false, default: "pending_review"
      add :risk_signals, :map, null: false, default: %{}
      add :reason, :text
      add :reviewed_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :reviewed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:registration_reviews, [:status])
    create index(:registration_reviews, [:user_id])

    create constraint(:registration_reviews, :registration_reviews_status_check,
             check: "status IN ('pending_review','approved','rejected')"
           )

    create table(:login_attempts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username_normalized, :string, size: 32
      add :ip_address, :string
      add :success, :boolean, null: false, default: false
      add :user_agent, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:login_attempts, [:username_normalized, :inserted_at])
    create index(:login_attempts, [:ip_address, :inserted_at])

    create table(:security_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :event_type, :string, size: 64, null: false
      add :ip_address, :string
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:security_events, [:user_id])
    create index(:security_events, [:event_type, :inserted_at])

    create table(:audit_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :action, :string, size: 64, null: false
      add :resource_type, :string, size: 64
      add :resource_id, :binary_id
      add :ip_address, :string
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:audit_logs, [:actor_id])
    create index(:audit_logs, [:action, :inserted_at])

    create table(:username_reservations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username_normalized, :string, size: 32, null: false
      add :reason, :string, size: 64, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :expires_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:username_reservations, [:username_normalized])
  end
end
