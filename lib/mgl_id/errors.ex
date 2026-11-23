defmodule MglId.Errors do
  @moduledoc """
  Unified API error codes and messages.
  """

  @messages %{
    username_already_exists: {"USERNAME_ALREADY_EXISTS", "Username is already taken"},
    invalid_username: {"INVALID_USERNAME", "Invalid username"},
    invalid_credentials: {"INVALID_CREDENTIALS", "Invalid username or password"},
    invalid_password: {"INVALID_PASSWORD", "Password does not meet requirements"},
    account_suspended: {"ACCOUNT_SUSPENDED", "Account is suspended"},
    account_disabled: {"ACCOUNT_DISABLED", "Account is disabled"},
    registration_disabled: {"REGISTRATION_DISABLED", "Registration is currently disabled"},
    verification_required: {"VERIFICATION_REQUIRED", "Verification required"},
    rate_limited: {"RATE_LIMITED", "Too many requests"},
    token_expired: {"TOKEN_EXPIRED", "Token expired or invalid"},
    token_revoked: {"TOKEN_REVOKED", "Token revoked"},
    email_required: {"EMAIL_REQUIRED", "Email is required"},
    email_taken: {"EMAIL_TAKEN", "Email is already in use"},
    unauthorized: {"UNAUTHORIZED", "Authentication required"},
    forbidden: {"FORBIDDEN", "Forbidden"},
    not_found: {"NOT_FOUND", "Not found"},
    invalid_client: {"INVALID_CLIENT", "Invalid client credentials"},
    invalid_params: {"INVALID_PARAMS", "Invalid parameters"},
    invalid_provider: {"INVALID_PROVIDER", "Unknown product provider"},
    account_link_conflict: {"ACCOUNT_LINK_CONFLICT", "Account link conflict"},
    account_link_exists: {"ACCOUNT_LINK_EXISTS", "Account already linked for this provider"},
    account_link_expired: {"ACCOUNT_LINK_EXPIRED", "Account link initiation expired or invalid"}
  }

  def to_error(reason) when is_atom(reason) do
    {code, message} = Map.get(@messages, reason, {"UNKNOWN", "An error occurred"})
    %{code: code, message: message, details: %{}}
  end

  def to_error({reason, details}) when is_atom(reason) and is_map(details) do
    error = to_error(reason)
    %{error | details: details}
  end
end
