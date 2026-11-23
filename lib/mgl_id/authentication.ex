defmodule MglId.Authentication do
  @moduledoc """
  Registration, login, password change/reset, and email verification.
  """

  import Ecto.Query

  alias MglId.{
    Accounts,
    Audit,
    Contacts,
    Credentials,
    Crypto,
    Passwords,
    Registrations,
    Repo,
    Security,
    Sessions
  }

  alias MglId.Accounts.{User, Username}
  alias MglId.Authentication.{EmailVerificationToken, PasswordResetToken}
  alias MglId.Workers.DeliverEmail

  def register(attrs, meta \\ %{}) do
    if Application.get_env(:mgl_id, :registration_enabled, true) do
      do_register(attrs, meta)
    else
      {:error, :registration_disabled}
    end
  end

  defp do_register(attrs, meta) do
    username = Map.get(attrs, "username") || Map.get(attrs, :username)
    password = Map.get(attrs, "password") || Map.get(attrs, :password)
    email = optional_email(attrs)

    with :ok <- Security.check_rate_limit({:register_ip, meta[:ip_address] || "unknown"}, 20),
         {:ok, normalized} <- Username.validate(username),
         true <- Accounts.username_available?(normalized),
         :ok <- Passwords.validate(password),
         :ok <- maybe_require_email(email),
         :ok <- maybe_check_email_taken(email) do
      risk = Registrations.evaluate_risk(%{ip_address: meta[:ip_address]})

      {status, review_status} =
        if risk.require_review do
          {"pending", "pending_review"}
        else
          {"active", "not_required"}
        end

      Repo.transaction(fn ->
        {:ok, user} =
          Accounts.create_user(%{
            username: username,
            username_normalized: normalized,
            display_name:
              Map.get(attrs, "display_name") || Map.get(attrs, :display_name) || username,
            status: status,
            review_status: review_status,
            registration_source: Map.get(meta, :source, "web"),
            locale: Map.get(attrs, "locale") || Map.get(attrs, :locale)
          })

        {:ok, _} = Credentials.create_password(user.id, password)

        if email do
          {:ok, _} = Contacts.add_email(user.id, email, verified_at: nil)
          _ = request_email_verification(user, email)
        end

        if risk.require_review do
          {:ok, _} = Registrations.create_pending_review(user.id, risk.signals)
        end

        Audit.log("auth.register.success", %{
          actor_id: user.id,
          resource_type: "user",
          resource_id: user.id,
          ip_address: meta[:ip_address],
          metadata: %{review_status: review_status, signals: risk.signals}
        })

        _ = MglId.Metrics.emit("auth.register.success", %{review_status: review_status})

        user
      end)
    else
      false -> {:error, :username_already_exists}
      {:error, :rate_limited} -> {:error, :rate_limited}
      {:error, :invalid_username} -> {:error, :invalid_username}
      {:error, :password_too_short} -> {:error, :invalid_password}
      {:error, :password_compromised} -> {:error, :invalid_password}
      {:error, :email_required} -> {:error, :email_required}
      {:error, :email_taken} -> {:error, :email_taken}
    end
  end

  def login(username, password, meta \\ %{}) do
    normalized = Username.normalize(username || "")

    with :ok <- Security.check_rate_limit({:login_ip, meta[:ip_address] || "unknown"}, 30),
         :ok <- Security.check_rate_limit({:login_user, normalized}, 10) do
      user = Accounts.get_user_by_username(username)

      cond do
        is_nil(user) ->
          _ = Argon2.no_user_verify()
          record_failed_login(normalized, meta)
          {:error, :invalid_credentials}

        user.status == "suspended" ->
          record_failed_login(normalized, meta)
          {:error, :account_suspended}

        user.status == "disabled" ->
          record_failed_login(normalized, meta)
          {:error, :account_disabled}

        user.review_status == "pending_review" and user.status == "pending" ->
          # Allow login to see status, but some flows may block — SPEC: pending can auth
          do_login(user, password, normalized, meta)

        not User.can_authenticate?(user) ->
          record_failed_login(normalized, meta)
          {:error, :invalid_credentials}

        true ->
          do_login(user, password, normalized, meta)
      end
    end
  end

  defp do_login(user, password, normalized, meta) do
    if Credentials.valid_password?(user.id, password) do
      {:ok, user} = Accounts.touch_last_login(user)

      {:ok, session, token} =
        Sessions.create_session(user, %{
          ip_address: meta[:ip_address],
          user_agent: meta[:user_agent],
          device_name: meta[:device_name]
        })

      Security.record_login_attempt(%{
        username_normalized: normalized,
        ip_address: meta[:ip_address],
        user_agent: meta[:user_agent],
        success: true
      })

      Security.record_event("auth.login.success", %{
        user_id: user.id,
        ip_address: meta[:ip_address]
      })

      Audit.log("auth.login.success", %{
        actor_id: user.id,
        resource_type: "session",
        resource_id: session.id,
        ip_address: meta[:ip_address]
      })

      _ = MglId.Metrics.emit("auth.login.success")

      {:ok, user, session, token}
    else
      record_failed_login(normalized, meta, user.id)
      _ = MglId.Metrics.emit("auth.login.failure")
      {:error, :invalid_credentials}
    end
  end

  def change_password(%User{} = user, current_password, new_password) do
    with true <- Credentials.valid_password?(user.id, current_password),
         :ok <- Passwords.validate(new_password),
         {:ok, _} <- Credentials.update_password(user.id, new_password),
         {:ok, _} <- Sessions.revoke_all_user_sessions(user.id) do
      Audit.log("auth.change_password", %{
        actor_id: user.id,
        resource_type: "user",
        resource_id: user.id
      })

      :ok
    else
      false -> {:error, :invalid_credentials}
      {:error, :password_too_short} -> {:error, :invalid_password}
      {:error, :password_compromised} -> {:error, :invalid_password}
      other -> other
    end
  end

  def forgot_password(username_or_email, meta \\ %{}) do
    # Always return :ok to avoid enumeration
    _ = Security.check_rate_limit({:forgot_ip, meta[:ip_address] || "unknown"}, 10)

    user =
      cond do
        is_binary(username_or_email) and String.contains?(username_or_email, "@") ->
          # lookup by email hash via contacts — skip enumeration; try username path only for now
          nil

        is_binary(username_or_email) ->
          Accounts.get_user_by_username(username_or_email)

        true ->
          nil
      end

    if user do
      _ = create_password_reset(user)
    end

    :ok
  end

  def reset_password(token, new_password) when is_binary(token) do
    hash = Crypto.hash_token(token)
    now = DateTime.utc_now()

    with %PasswordResetToken{} = reset <-
           Repo.one(
             from t in PasswordResetToken,
               where: t.token_hash == ^hash,
               where: is_nil(t.used_at),
               where: t.expires_at > ^now
           ),
         :ok <- Passwords.validate(new_password),
         user <- Accounts.get_user!(reset.user_id),
         {:ok, _} <- Credentials.update_password(user.id, new_password),
         {:ok, _} <-
           reset |> PasswordResetToken.changeset(%{used_at: now}) |> Repo.update(),
         {:ok, _} <- Sessions.revoke_all_user_sessions(user.id) do
      Audit.log("auth.reset_password", %{
        actor_id: user.id,
        resource_type: "user",
        resource_id: user.id
      })

      :ok
    else
      nil -> {:error, :token_expired}
      {:error, :password_too_short} -> {:error, :invalid_password}
      {:error, :password_compromised} -> {:error, :invalid_password}
      other -> other
    end
  end

  def request_email_verification(%User{} = user, email) do
    token = Crypto.generate_token()
    now = DateTime.utc_now()

    {:ok, _} =
      %EmailVerificationToken{}
      |> EmailVerificationToken.changeset(%{
        user_id: user.id,
        token_hash: Crypto.hash_token(token),
        email_hash: Crypto.hmac(email),
        expires_at: DateTime.add(now, 24 * 3600, :second)
      })
      |> Repo.insert()

    %{
      to: email,
      subject: "Verify your email — Mgl ID",
      text_body: "Your verification token: #{token}\nVisit /account/verify-email?token=#{token}"
    }
    |> DeliverEmail.new()
    |> Oban.insert()

    {:ok, token}
  end

  def verify_email(token) when is_binary(token) do
    hash = Crypto.hash_token(token)
    now = DateTime.utc_now()

    case Repo.one(
           from t in EmailVerificationToken,
             where: t.token_hash == ^hash,
             where: is_nil(t.used_at),
             where: t.expires_at > ^now
         ) do
      nil ->
        {:error, :token_expired}

      ev ->
        Repo.transaction(fn ->
          # We need the email plaintext — stored encrypted on contact with matching hash
          contact =
            Repo.one(
              from c in MglId.Contacts.VerifiedContact,
                where: c.user_id == ^ev.user_id and c.value_hash == ^ev.email_hash
            )

          if contact do
            {:ok, email} = Crypto.decrypt(contact.value_encrypted)
            {:ok, _} = Contacts.mark_verified(ev.user_id, email)
          end

          {:ok, _} =
            ev
            |> EmailVerificationToken.changeset(%{used_at: now})
            |> Repo.update()

          user = Accounts.get_user!(ev.user_id)

          if user.trust_level == "basic" do
            user
            |> Ecto.Changeset.change(%{trust_level: "verified"})
            |> Repo.update!()
          end

          :ok
        end)
    end
  end

  def create_password_reset(%User{} = user) do
    token = Crypto.generate_token()
    now = DateTime.utc_now()

    {:ok, _} =
      %PasswordResetToken{}
      |> PasswordResetToken.changeset(%{
        user_id: user.id,
        token_hash: Crypto.hash_token(token),
        expires_at: DateTime.add(now, 3600, :second)
      })
      |> Repo.insert()

    email = Contacts.get_primary_email(user.id)

    if email do
      %{
        to: email,
        subject: "Reset your password — Mgl ID",
        text_body: "Reset token: #{token}\nVisit /password/reset?token=#{token}"
      }
      |> DeliverEmail.new()
      |> Oban.insert()
    end

    {:ok, token}
  end

  defp record_failed_login(normalized, meta, user_id \\ nil) do
    Security.record_login_attempt(%{
      username_normalized: normalized,
      ip_address: meta[:ip_address],
      user_agent: meta[:user_agent],
      success: false
    })

    Security.record_event("auth.login.failure", %{
      user_id: user_id,
      ip_address: meta[:ip_address],
      metadata: %{username_normalized: normalized}
    })
  end

  defp optional_email(attrs) do
    case Map.get(attrs, "email") || Map.get(attrs, :email) do
      email when is_binary(email) and email != "" -> String.trim(email) |> String.downcase()
      _ -> nil
    end
  end

  defp maybe_require_email(nil) do
    if Application.get_env(:mgl_id, :registration_require_email, false) do
      {:error, :email_required}
    else
      :ok
    end
  end

  defp maybe_require_email(_), do: :ok

  defp maybe_check_email_taken(nil), do: :ok

  defp maybe_check_email_taken(email) do
    if Contacts.email_taken?(email), do: {:error, :email_taken}, else: :ok
  end
end
