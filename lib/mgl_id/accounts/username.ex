defmodule MglId.Accounts.Username do
  @moduledoc """
  Username format, normalization, and reserved-name checks.
  """

  @reserved MapSet.new(~w(
    admin support system amjil mgl root null undefined api www mail
    help security account accounts login register logout oauth openid
    id identity auth authentication
  ))

  @format ~r/\A[a-zA-Z0-9_]{3,32}\z/

  def normalize(username) when is_binary(username) do
    username |> String.trim() |> String.downcase()
  end

  def normalize(_), do: ""

  def valid_format?(username) when is_binary(username), do: Regex.match?(@format, username)
  def valid_format?(_), do: false

  def reserved?(username) when is_binary(username) do
    MapSet.member?(@reserved, normalize(username))
  end

  def reserved?(_), do: true

  def validate(username) when is_binary(username) do
    cond do
      not valid_format?(username) ->
        {:error, :invalid_username}

      reserved?(username) ->
        {:error, :invalid_username}

      true ->
        {:ok, normalize(username)}
    end
  end

  def validate(_), do: {:error, :invalid_username}
end
