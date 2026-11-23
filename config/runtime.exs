import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/mgl_id start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :mgl_id, MglIdWeb.Endpoint, server: true
end

config :mgl_id, MglIdWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

# Registration / identity policy (defaults match SPEC §6.2)
config :mgl_id,
  registration_enabled: System.get_env("REGISTRATION_ENABLED", "true") in ~w(true 1),
  registration_review_mode: System.get_env("REGISTRATION_REVIEW_MODE", "conditional"),
  registration_require_email: System.get_env("REGISTRATION_REQUIRE_EMAIL", "false") in ~w(true 1),
  registration_captcha_mode: System.get_env("REGISTRATION_CAPTCHA_MODE", "conditional"),
  oidc_issuer: System.get_env("OIDC_ISSUER", "https://id.amjil.net")

# Account link redirect targets (product apps). Override in prod.
xamt_link = System.get_env("XAMT_LINK_START_URL", "http://127.0.0.1:4002/account/link")
nomio_link = System.get_env("NOMIO_LINK_START_URL", "http://127.0.0.1:4003/account/link")

config :mgl_id,
  account_link_providers: %{
    "xamt" => %{
      name: "Xamt",
      link_start_url: xamt_link,
      oauth_client_name: "Xamt"
    },
    "nomio" => %{
      name: "Nomio",
      link_start_url: nomio_link,
      oauth_client_name: "Nomio"
    }
  }

if config_env() == :dev do
  # Reload browser tabs when matching files change.
  config :mgl_id, MglIdWeb.Endpoint,
    live_reload: [
      web_console_logger: true,
      patterns: [
        # Static assets, except user uploads
        ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$"E,
        # Gettext translations
        ~r"priv/gettext/.*\.po$"E,
        # Router, Controllers, LiveViews and LiveComponents
        ~r"lib/mgl_id_web/router\.ex$"E,
        ~r"lib/mgl_id_web/(controllers|live|components)/.*\.(ex|heex)$"E
      ]
    ]
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  repo_ssl? = System.get_env("DATABASE_SSL", "true") in ~w(true 1)

  repo_opts = [
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    ssl: repo_ssl?
  ]

  repo_opts =
    if repo_ssl? do
      ssl_opts =
        cond do
          ca = System.get_env("DATABASE_CA_CERT_FILE") ->
            [verify: :verify_peer, cacertfile: ca]

          System.get_env("DATABASE_SSL_VERIFY", "true") in ~w(false 0) ->
            [verify: :verify_none]

          true ->
            [verify: :verify_peer, cacerts: :public_key.cacerts_get()]
        end

      Keyword.put(repo_opts, :ssl_opts, ssl_opts)
    else
      repo_opts
    end

  config :mgl_id, MglId.Repo, repo_opts

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "id.amjil.net"

  config :mgl_id, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  if key = System.get_env("TOKEN_ENCRYPTION_KEY") do
    config :mgl_id, :token_encryption_key, key
  end

  if key = System.get_env("CONTACT_HMAC_KEY") do
    config :mgl_id, :contact_hmac_key, key
  end

  config :mgl_id, MglIdWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # SMTP (optional). Prefer secret manager injection of credentials.
  if System.get_env("SMTP_HOST") do
    config :mgl_id, MglId.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: System.get_env("SMTP_HOST"),
      port: String.to_integer(System.get_env("SMTP_PORT", "587")),
      username: System.get_env("SMTP_USERNAME"),
      password: System.get_env("SMTP_PASSWORD"),
      tls: :always,
      auth: :always
  end
end
