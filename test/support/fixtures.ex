defmodule MglId.Fixtures do
  @moduledoc false

  alias MglId.Authentication

  def unique_username, do: "user_#{System.unique_integer([:positive])}"

  def valid_password, do: "a-long-unique-passphrase"

  def register_user(attrs \\ %{}) do
    username = Map.get(attrs, :username) || unique_username()

    params =
      %{
        "username" => username,
        "password" => Map.get(attrs, :password) || valid_password(),
        "display_name" => Map.get(attrs, :display_name) || username,
        "email" => Map.get(attrs, :email)
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    meta = Map.get(attrs, :meta, %{ip_address: "127.0.0.1"})

    Authentication.register(params, meta)
  end
end
