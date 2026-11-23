defmodule MglId.Sessions do
  @moduledoc """
  Central browser sessions. Tokens stored hashed only.
  """

  import Ecto.Query

  alias MglId.Accounts.User
  alias MglId.Crypto
  alias MglId.Repo
  alias MglId.Sessions.Session

  @default_ttl_days 30

  def create_session(%User{} = user, attrs \\ %{}) do
    token = Crypto.generate_token()
    now = DateTime.utc_now()

    attrs =
      Map.merge(
        %{
          user_id: user.id,
          session_token_hash: Crypto.hash_token(token),
          last_active_at: now,
          expires_at: DateTime.add(now, @default_ttl_days * 24 * 3600, :second)
        },
        Map.take(attrs, [:device_name, :ip_address, :user_agent])
      )

    case %Session{} |> Session.changeset(attrs) |> Repo.insert() do
      {:ok, session} -> {:ok, session, token}
      error -> error
    end
  end

  def get_user_by_session_token(token) when is_binary(token) do
    hash = Crypto.hash_token(token)
    now = DateTime.utc_now()

    query =
      from s in Session,
        join: u in assoc(s, :user),
        where: s.session_token_hash == ^hash,
        where: is_nil(s.revoked_at),
        where: s.expires_at > ^now,
        where: u.status in ^["active", "pending"],
        where: is_nil(u.deleted_at),
        preload: [user: u]

    case Repo.one(query) do
      %Session{} = session ->
        touch(session)
        {session.user, session}

      nil ->
        nil
    end
  end

  def get_user_by_session_token(_), do: nil

  def list_user_sessions(user_id) do
    now = DateTime.utc_now()

    Repo.all(
      from s in Session,
        where: s.user_id == ^user_id,
        where: is_nil(s.revoked_at),
        where: s.expires_at > ^now,
        order_by: [desc: s.last_active_at]
    )
  end

  def revoke_session(%Session{} = session) do
    session
    |> Session.changeset(%{revoked_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def revoke_session(user_id, session_id) do
    case Repo.get_by(Session, id: session_id, user_id: user_id) do
      nil -> {:error, :not_found}
      session -> revoke_session(session)
    end
  end

  def revoke_all_user_sessions(user_id, except_id \\ nil) do
    now = DateTime.utc_now()

    query =
      from s in Session,
        where: s.user_id == ^user_id,
        where: is_nil(s.revoked_at)

    query =
      if except_id do
        from s in query, where: s.id != ^except_id
      else
        query
      end

    {count, _} = Repo.update_all(query, set: [revoked_at: now])
    {:ok, count}
  end

  defp touch(%Session{} = session) do
    session
    |> Session.changeset(%{last_active_at: DateTime.utc_now()})
    |> Repo.update()
  end
end
