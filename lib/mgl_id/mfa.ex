defmodule MglId.Mfa do
  @moduledoc """
  TOTP MFA for administrators.
  """

  alias MglId.Accounts.User
  alias MglId.Crypto
  alias MglId.Repo

  def enabled?(%User{totp_enabled_at: %DateTime{}}), do: true
  def enabled?(_), do: false

  def required_for?(%User{} = user) do
    user.is_admin or MglId.Policies.user_permissions(user) != []
  end

  def begin_setup(%User{} = user) do
    secret = NimbleTOTP.secret()
    encrypted = Crypto.encrypt(Base.encode64(secret))

    {:ok, user} =
      user
      |> Ecto.Changeset.change(%{totp_secret_encrypted: encrypted, totp_enabled_at: nil})
      |> Repo.update()

    uri = NimbleTOTP.otpauth_uri("Mgl ID:#{user.username}", secret, issuer: "Mgl ID")
    {:ok, user, secret, uri}
  end

  def confirm_setup(%User{} = user, code) when is_binary(code) do
    with {:ok, secret} <- decrypt_secret(user),
         true <- NimbleTOTP.valid?(secret, code) do
      user
      |> Ecto.Changeset.change(%{totp_enabled_at: DateTime.utc_now()})
      |> Repo.update()
    else
      false -> {:error, :invalid_code}
      other -> other
    end
  end

  def verify(%User{} = user, code) when is_binary(code) do
    with true <- enabled?(user),
         {:ok, secret} <- decrypt_secret(user),
         true <- NimbleTOTP.valid?(secret, code) do
      :ok
    else
      false -> {:error, :invalid_code}
      other -> other
    end
  end

  def disable(%User{} = user) do
    user
    |> Ecto.Changeset.change(%{totp_secret_encrypted: nil, totp_enabled_at: nil})
    |> Repo.update()
  end

  defp decrypt_secret(%User{totp_secret_encrypted: nil}), do: {:error, :not_configured}

  defp decrypt_secret(%User{totp_secret_encrypted: ciphertext}) do
    case Crypto.decrypt(ciphertext) do
      {:ok, b64} -> {:ok, Base.decode64!(b64)}
      error -> error
    end
  end
end
