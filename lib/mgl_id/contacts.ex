defmodule MglId.Contacts do
  @moduledoc """
  Verifiable contacts. Values encrypted at rest; lookup via HMAC.
  """

  import Ecto.Query

  alias MglId.Contacts.VerifiedContact
  alias MglId.Crypto
  alias MglId.Repo

  def add_email(user_id, email, opts \\ []) do
    email = email |> String.trim() |> String.downcase()
    primary? = Keyword.get(opts, :primary, true)
    verified_at = Keyword.get(opts, :verified_at)

    %VerifiedContact{}
    |> VerifiedContact.changeset(%{
      user_id: user_id,
      type: "email",
      value_encrypted: Crypto.encrypt(email),
      value_hash: Crypto.hmac(email),
      is_primary: primary?,
      verified_at: verified_at
    })
    |> Repo.insert()
  end

  def get_primary_email(user_id) do
    case Repo.one(
           from c in VerifiedContact,
             where: c.user_id == ^user_id and c.type == "email" and c.is_primary == true
         ) do
      nil ->
        nil

      contact ->
        case Crypto.decrypt(contact.value_encrypted) do
          {:ok, email} -> email
          _ -> nil
        end
    end
  end

  def mark_verified(user_id, email) do
    hash = Crypto.hmac(email)

    case Repo.one(
           from c in VerifiedContact,
             where: c.user_id == ^user_id and c.type == "email" and c.value_hash == ^hash
         ) do
      nil ->
        {:error, :not_found}

      contact ->
        contact
        |> VerifiedContact.changeset(%{verified_at: DateTime.utc_now()})
        |> Repo.update()
    end
  end

  def email_taken?(email) when is_binary(email) do
    hash = Crypto.hmac(email)

    Repo.exists?(
      from c in VerifiedContact,
        where: c.type == "email" and c.value_hash == ^hash
    )
  end
end
