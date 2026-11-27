# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mgl_id,
  ecto_repos: [MglId.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  # Sibling checkout for `mix mgl_id.vendor` (override with MGL_COMMON_UI_PATH).
  # From config/ → ../../.. = projects/, then js/mgl-common-ui.js
  mgl_common_ui_path: Path.expand("../../../js/mgl-common-ui.js", __DIR__),
  account_link_providers: %{
    "xamt" => %{
      name: "Xamt",
      link_start_url: "http://100.64.0.8:4002/account/link",
      oauth_client_name: "Xamt"
    },
    "nomio" => %{
      name: "Nomio",
      link_start_url: "http://100.64.0.6:4000/account/link",
      oauth_client_name: "Nomio"
    }
  }

# Oban background jobs (mail, cleanup). Queues expand in later phases.
config :mgl_id, Oban,
  repo: MglId.Repo,
  queues: [default: 10, mailers: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7}
  ]

# Boruta OAuth / OpenID Connect provider
config :boruta, Boruta.Oauth,
  repo: MglId.Repo,
  issuer: "https://id.amjil.net",
  contexts: [
    resource_owners: MglId.Oauth.ResourceOwners
  ],
  max_ttl: [
    authorization_code: 60,
    access_token: 60 * 10,
    id_token: 60 * 10,
    refresh_token: 60 * 60 * 24 * 30
  ]

# Configure the endpoint
config :mgl_id, MglIdWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MglIdWeb.ErrorHTML, json: MglIdWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MglId.PubSub,
  live_view: [signing_salt: "DbdMdJEF"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :mgl_id, MglId.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  mgl_id: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=. --alias:mgl-common-ui=./vendor/mgl-common-ui/index.js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.3",
  mgl_id: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
