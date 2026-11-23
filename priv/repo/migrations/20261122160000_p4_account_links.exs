defmodule MglId.Repo.Migrations.P4AccountLinks do
  use Ecto.Migration

  def change do
    create table(:account_link_initiations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :provider, :string, size: 64, null: false
      add :token_hash, :string, null: false
      add :nonce, :string, size: 64, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :consumed_at, :utc_datetime_usec
      add :oauth_client_id, :string, size: 64
      add :redirect_url, :text
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:account_link_initiations, [:token_hash])
    create index(:account_link_initiations, [:user_id, :provider])
    create index(:account_link_initiations, [:expires_at])

    create table(:account_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :restrict), null: false
      add :provider, :string, size: 64, null: false
      add :external_user_id, :string, size: 255, null: false
      add :linked_at, :utc_datetime_usec, null: false
      add :unlinked_at, :utc_datetime_usec
      add :oauth_client_id, :string, size: 64
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:account_links, [:user_id])
    create index(:account_links, [:provider])

    # One active external identity ↔ one Amjil ID per provider
    create unique_index(:account_links, [:provider, :external_user_id],
             name: :account_links_provider_external_active_index,
             where: "unlinked_at IS NULL"
           )

    create unique_index(:account_links, [:user_id, :provider],
             name: :account_links_user_provider_active_index,
             where: "unlinked_at IS NULL"
           )
  end
end
