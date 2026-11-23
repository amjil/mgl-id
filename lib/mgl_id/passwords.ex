defmodule MglId.Passwords do
  @moduledoc """
  Password policy and Argon2id hashing.
  """

  @min_length 12
  @denylist MapSet.new(~w(
    password password123 password1234 123456789012 qwertyuiopas
    letmeinletmein changeme1234 adminadmin12 welcome12345
  ))

  def validate(password) when is_binary(password) do
    cond do
      String.length(password) < @min_length ->
        {:error, :password_too_short}

      MapSet.member?(@denylist, String.downcase(password)) ->
        {:error, :password_compromised}

      true ->
        :ok
    end
  end

  def validate(_), do: {:error, :password_too_short}

  def hash(password) when is_binary(password) do
    Argon2.hash_pwd_salt(password)
  end

  def verify(password, hash) when is_binary(password) and is_binary(hash) do
    Argon2.verify_pass(password, hash)
  end

  def verify(_, _), do: Argon2.no_user_verify()
end
