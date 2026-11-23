defmodule MglId.Repo.Migrations.P3AccountAdmin do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :totp_secret_encrypted, :text
      add :totp_enabled_at, :utc_datetime_usec
    end

    create table(:admin_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, size: 64, null: false
      add :permissions, {:array, :string}, null: false, default: []

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:admin_roles, [:name])

    create table(:admin_user_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :role_id, references(:admin_roles, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:admin_user_roles, [:user_id, :role_id])
    create index(:admin_user_roles, [:user_id])
  end
end
