defmodule MglId.Accounts do
  @moduledoc """
  Users: create, profile updates, and account status transitions.
  """

  import Ecto.Query

  alias MglId.Accounts.{User, Username, UsernameReservation}
  alias MglId.Repo

  def get_user(id), do: Repo.get(User, id)

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_username(username) when is_binary(username) do
    normalized = Username.normalize(username)

    Repo.one(
      from u in User,
        where: u.username_normalized == ^normalized and is_nil(u.deleted_at)
    )
  end

  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def change_status(%User{} = user, status) do
    user
    |> User.status_changeset(status)
    |> Repo.update()
  end

  def set_review_status(%User{} = user, status) do
    user
    |> User.review_status_changeset(status)
    |> Repo.update()
  end

  def request_deletion(%User{} = user) do
    change_status(user, "deletion_pending")
  end

  def touch_last_login(%User{} = user) do
    user
    |> Ecto.Changeset.change(%{last_login_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def reserve_username(normalized, reason, user_id \\ nil) do
    %UsernameReservation{}
    |> UsernameReservation.changeset(%{
      username_normalized: normalized,
      reason: reason,
      user_id: user_id
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:username_normalized])
  end

  def list_users(opts \\ []) do
    q = Keyword.get(opts, :q, "") |> to_string() |> String.trim()
    status = Keyword.get(opts, :status)

    query =
      from u in User, where: is_nil(u.deleted_at), order_by: [desc: u.inserted_at], limit: 100

    query =
      if q != "" do
        like = "%#{String.downcase(q)}%"

        from u in query,
          where:
            like(u.username_normalized, ^like) or
              like(fragment("lower(?)", u.display_name), ^like)
      else
        query
      end

    query =
      if status in User.statuses() do
        from u in query, where: u.status == ^status
      else
        query
      end

    Repo.all(query)
  end

  def list_login_attempts(user_id, limit \\ 20) do
    user = get_user!(user_id)
    normalized = user.username_normalized

    Repo.all(
      from a in MglId.Security.LoginAttempt,
        where: a.username_normalized == ^normalized,
        order_by: [desc: a.inserted_at],
        limit: ^limit
    )
  end

  def username_available?(normalized) when is_binary(normalized) do
    user_taken? =
      Repo.exists?(
        from u in User,
          where: u.username_normalized == ^normalized and is_nil(u.deleted_at)
      )

    reserved? =
      Repo.exists?(
        from r in UsernameReservation,
          where: r.username_normalized == ^normalized,
          where: is_nil(r.expires_at) or r.expires_at > ^DateTime.utc_now()
      )

    not user_taken? and not reserved?
  end
end
