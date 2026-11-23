defmodule MglId.Accounts.UsernameTest do
  use ExUnit.Case, async: true

  alias MglId.Accounts.Username

  test "normalizes to lowercase" do
    assert Username.normalize("AbC_12") == "abc_12"
  end

  test "validates format" do
    assert {:ok, "abc"} = Username.validate("abc")
    assert {:error, :invalid_username} = Username.validate("ab")
    assert {:error, :invalid_username} = Username.validate("has space")
    assert {:error, :invalid_username} = Username.validate("admin")
  end
end
