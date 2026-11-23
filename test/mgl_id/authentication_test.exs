defmodule MglId.AuthenticationTest do
  use MglId.DataCase, async: true

  alias MglId.{Accounts, Authentication, Fixtures, Sessions}
  alias MglId.Accounts.User

  test "registers and logs in a user" do
    assert {:ok, %User{} = user} = Fixtures.register_user(%{username: "good_user_1"})
    assert user.status == "active"
    assert user.username_normalized == "good_user_1"

    assert {:ok, logged, session, token} =
             Authentication.login("good_user_1", Fixtures.valid_password(), %{
               ip_address: "127.0.0.1"
             })

    assert logged.id == user.id
    assert session.user_id == user.id
    assert {from_token, _} = Sessions.get_user_by_session_token(token)
    assert from_token.id == user.id
  end

  test "rejects reserved and duplicate usernames" do
    assert {:error, :invalid_username} = Fixtures.register_user(%{username: "admin"})
    assert {:ok, _} = Fixtures.register_user(%{username: "dup_user"})
    assert {:error, :username_already_exists} = Fixtures.register_user(%{username: "DUP_USER"})
  end

  test "rejects short passwords" do
    assert {:error, :invalid_password} =
             Fixtures.register_user(%{username: "short_pwd_user", password: "tooshort"})
  end

  test "invalid credentials do not reveal username existence" do
    assert {:ok, _} = Fixtures.register_user(%{username: "exist_user"})

    assert {:error, :invalid_credentials} =
             Authentication.login("exist_user", "wrong-password-xx", %{})

    assert {:error, :invalid_credentials} =
             Authentication.login("missing_user", "wrong-password-xx", %{})
  end

  test "suspended users cannot create sessions" do
    assert {:ok, user} = Fixtures.register_user(%{username: "sus_user"})
    {:ok, user} = Accounts.change_status(user, "suspended")

    assert {:error, :account_suspended} =
             Authentication.login("sus_user", Fixtures.valid_password(), %{})

    assert user.status == "suspended"
  end

  test "password reset revokes sessions" do
    assert {:ok, user} = Fixtures.register_user(%{username: "reset_user"})

    assert {:ok, _u, _s, token} =
             Authentication.login("reset_user", Fixtures.valid_password(), %{})

    assert {:ok, reset_token} = Authentication.create_password_reset(user)
    assert :ok = Authentication.reset_password(reset_token, "brand-new-password-99")
    assert Sessions.get_user_by_session_token(token) == nil
  end

  test "hashes passwords with argon2" do
    assert {:ok, user} = Fixtures.register_user(%{username: "hash_user"})
    cred = MglId.Credentials.get_password_credential(user.id)
    assert String.starts_with?(cred.secret_hash, "$argon2")
  end
end
