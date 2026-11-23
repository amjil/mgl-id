defmodule MglId.Crypto do
  @moduledoc """
  Token hashing and contact encryption helpers.
  Never log plaintext secrets or tokens.
  """

  @doc "Generate a high-entropy URL-safe token."
  def generate_token(bytes \\ 32) do
    :crypto.strong_rand_bytes(bytes) |> Base.url_encode64(padding: false)
  end

  def hash_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
  end

  def encrypt(plaintext) when is_binary(plaintext) do
    Plug.Crypto.MessageEncryptor.encrypt(plaintext, encryption_key(), signing_salt())
  end

  def decrypt(ciphertext) when is_binary(ciphertext) do
    case Plug.Crypto.MessageEncryptor.decrypt(ciphertext, encryption_key(), signing_salt()) do
      {:ok, plaintext} -> {:ok, plaintext}
      :error -> {:error, :invalid}
    end
  end

  def hmac(value) when is_binary(value) do
    :crypto.mac(:hmac, :sha256, hmac_key(), String.downcase(String.trim(value)))
    |> Base.encode16(case: :lower)
  end

  defp encryption_key do
    key =
      Application.get_env(:mgl_id, :token_encryption_key) ||
        Application.get_env(:mgl_id, MglIdWeb.Endpoint)[:secret_key_base]

    key |> binary_part_key(32)
  end

  defp signing_salt do
    (Application.get_env(:mgl_id, :token_signing_salt) || "mgl-id-contact-v1")
    |> binary_part_key(32)
  end

  defp hmac_key do
    key =
      Application.get_env(:mgl_id, :contact_hmac_key) ||
        Application.get_env(:mgl_id, MglIdWeb.Endpoint)[:secret_key_base]

    ("hmac:" <> to_string(key)) |> binary_part_key(32)
  end

  defp binary_part_key(source, size) when is_binary(source) do
    hash = :crypto.hash(:sha256, source)

    if byte_size(hash) >= size do
      binary_part(hash, 0, size)
    else
      hash
    end
  end
end
