defmodule MglId.Credentials do
  @moduledoc """
  Password credential storage (Argon2id).
  """

  import Ecto.Query

  alias MglId.Credentials.Credential
  alias MglId.Passwords
  alias MglId.Repo

  def get_password_credential(user_id) do
    Repo.one(
      from c in Credential,
        where: c.user_id == ^user_id and c.type == "password"
    )
  end

  def create_password(user_id, password) do
    with :ok <- Passwords.validate(password) do
      %Credential{}
      |> Credential.changeset(%{
        user_id: user_id,
        type: "password",
        secret_hash: Passwords.hash(password)
      })
      |> Repo.insert()
    end
  end

  def update_password(user_id, password) do
    with :ok <- Passwords.validate(password),
         %Credential{} = cred <- get_password_credential(user_id) do
      cred
      |> Credential.changeset(%{secret_hash: Passwords.hash(password)})
      |> Repo.update()
    else
      nil -> {:error, :not_found}
      other -> other
    end
  end

  def valid_password?(user_id, password) when is_binary(password) do
    case get_password_credential(user_id) do
      %Credential{secret_hash: hash} -> Passwords.verify(password, hash)
      nil -> Passwords.verify(password, Argon2.hash_pwd_salt("invalid"))
    end
  end
end
