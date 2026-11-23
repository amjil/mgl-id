defmodule MglId.MfaTest do
  use MglId.DataCase, async: true

  alias MglId.{Fixtures, Mfa}

  test "setup confirm and verify totp" do
    {:ok, user} = Fixtures.register_user(%{username: Fixtures.unique_username()})
    {:ok, user, secret, uri} = Mfa.begin_setup(user)
    assert uri =~ "otpauth://"

    code = NimbleTOTP.verification_code(secret)
    assert {:ok, user} = Mfa.confirm_setup(user, code)
    assert Mfa.enabled?(user)
    assert :ok = Mfa.verify(user, NimbleTOTP.verification_code(secret))
  end
end
