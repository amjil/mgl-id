defmodule MglId.Oauth.ResourceOwners do
  @moduledoc """
  Bridge Boruta resource owners to MglId users.
  """
  @behaviour Boruta.Oauth.ResourceOwners

  import Ecto.Query

  alias Boruta.Oauth.ResourceOwner
  alias MglId.Accounts
  alias MglId.Accounts.User
  alias MglId.Contacts
  alias MglId.Contacts.VerifiedContact
  alias MglId.Credentials
  alias MglId.Repo

  @impl true
  def get_by(username: username) do
    case Accounts.get_user_by_username(username) do
      %User{} = user -> {:ok, to_resource_owner(user)}
      nil -> {:error, "User not found."}
    end
  end

  def get_by(sub: sub) do
    case Accounts.get_user(sub) do
      %User{} = user -> {:ok, to_resource_owner(user)}
      nil -> {:error, "User not found."}
    end
  end

  @impl true
  def check_password(%ResourceOwner{sub: sub}, password) do
    if Credentials.valid_password?(sub, password) do
      :ok
    else
      {:error, "Invalid username or password."}
    end
  end

  @impl true
  def authorized_scopes(%ResourceOwner{}), do: []

  @impl true
  def claims(%ResourceOwner{sub: sub}, scope) do
    user = Accounts.get_user(sub)
    scopes = String.split(scope || "", " ", trim: true)

    base = %{"sub" => sub}

    base =
      if "profile" in scopes and user do
        Map.merge(base, %{
          "preferred_username" => user.username,
          "name" => user.display_name || user.username,
          "locale" => user.locale
        })
      else
        base
      end

    if "email" in scopes and user do
      case Contacts.get_primary_email(user.id) do
        email when is_binary(email) ->
          contact =
            Repo.one(
              from c in VerifiedContact,
                where: c.user_id == ^user.id and c.type == "email" and c.is_primary == true
            )

          Map.merge(base, %{
            "email" => email,
            "email_verified" => not is_nil(contact && contact.verified_at)
          })

        _ ->
          base
      end
    else
      base
    end
  end

  def to_resource_owner(%User{} = user) do
    %ResourceOwner{
      sub: to_string(user.id),
      username: user.username,
      last_login_at: Map.get(user, :last_login_at) || user.updated_at
    }
  end
end
