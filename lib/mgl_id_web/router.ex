defmodule MglIdWeb.Router do
  use MglIdWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MglIdWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MglIdWeb.Plugs.SecurityHeaders
    plug MglIdWeb.Plugs.FetchCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug MglIdWeb.Plugs.SecurityHeaders
    plug MglIdWeb.Plugs.FetchCurrentUser
  end

  pipeline :api_authenticated do
    plug MglIdWeb.Plugs.RequireAuthenticated
  end

  scope "/", MglIdWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :public, on_mount: [{MglIdWeb.Live.Hooks.RequireAuthenticated, :maybe}] do
      live "/login", Auth.LoginLive, :new
      live "/register", Auth.RegisterLive, :new
      live "/password/forgot", Auth.ForgotPasswordLive, :new
      live "/password/reset", Auth.ResetPasswordLive, :edit
    end

    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
    post "/register", RegistrationController, :create

    get "/mfa", MfaController, :new
    post "/mfa", MfaController, :create

    live_session :authenticated,
      on_mount: [{MglIdWeb.Live.Hooks.RequireAuthenticated, :default}] do
      live "/account", Account.HomeLive, :index
      live "/account/profile", Account.ProfileLive, :edit
      live "/account/security", Account.SecurityLive, :edit
      live "/account/sessions", Account.SessionsLive, :index
      live "/account/applications", Account.ApplicationsLive, :index
      live "/account/links", Account.LinksLive, :index
      live "/account/privacy", Account.PrivacyLive, :edit
    end

    live_session :admin, on_mount: [{MglIdWeb.Live.Hooks.RequireAuthenticated, :admin}] do
      live "/admin", Admin.HomeLive, :index
      live "/admin/users", Admin.UsersLive, :index
      live "/admin/users/:id", Admin.UserShowLive, :show
      live "/admin/registrations", Admin.RegistrationsLive, :index
      live "/admin/clients", Admin.ClientsLive, :index
      live "/admin/migration", Admin.MigrationLive, :index
    end

    get "/oauth/authorize", Oauth.AuthorizeController, :authorize
    get "/openid/authorize", Openid.AuthorizeController, :authorize
    get "/oauth/consent", Oauth.ConsentController, :new
    post "/oauth/consent", Oauth.ConsentController, :create
  end

  scope "/", MglIdWeb do
    pipe_through :api

    get "/health", HealthController, :show
    get "/health/live", HealthController, :live
    get "/health/ready", HealthController, :ready

    get "/.well-known/openid-configuration", Openid.DiscoveryController, :configuration
    get "/.well-known/jwks.json", Openid.JwksController, :jwks_index
  end

  scope "/oauth", MglIdWeb.Oauth do
    pipe_through :api

    post "/token", TokenController, :token
    post "/revoke", RevokeController, :revoke
    post "/introspect", IntrospectController, :introspect
  end

  scope "/oauth", MglIdWeb.Openid do
    pipe_through :api

    get "/userinfo", UserinfoController, :userinfo
    post "/userinfo", UserinfoController, :userinfo
  end

  scope "/openid", MglIdWeb.Openid do
    pipe_through :api

    get "/userinfo", UserinfoController, :userinfo
    post "/userinfo", UserinfoController, :userinfo
    get "/jwks", JwksController, :jwks_index
  end

  scope "/api/v1", MglIdWeb.Api.V1 do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/forgot-password", AuthController, :forgot_password
    post "/auth/reset-password", AuthController, :reset_password
  end

  scope "/api/v1", MglIdWeb.Api.V1 do
    pipe_through [:api, :api_authenticated]

    get "/me", MeController, :show
    patch "/me", MeController, :update
    delete "/me", MeController, :delete

    post "/auth/logout", AuthController, :logout
    post "/auth/logout-all", AuthController, :logout_all
    post "/auth/change-password", AuthController, :change_password

    get "/sessions", SessionController, :index
    delete "/sessions/:id", SessionController, :delete

    get "/authorized-applications", AuthorizedApplicationController, :index
    delete "/authorized-applications/:client_id", AuthorizedApplicationController, :delete

    get "/account-links", AccountLinkController, :index
    post "/account-links/initiations", AccountLinkController, :create_initiation
    delete "/account-links/:id", AccountLinkController, :delete
  end

  scope "/api/v1", MglIdWeb.Api.V1 do
    pipe_through :api

    # Product backends confirm with OAuth client credentials (not user session)
    post "/account-links/confirm", AccountLinkController, :confirm
  end

  if Application.compile_env(:mgl_id, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MglIdWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
