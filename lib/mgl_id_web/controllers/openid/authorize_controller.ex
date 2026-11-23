defmodule MglIdWeb.Openid.AuthorizeController do
  @moduledoc false
  # OpenID authorize aliases to the OAuth authorize entry (SPEC /oauth/authorize).
  use MglIdWeb, :controller

  def authorize(conn, params) do
    MglIdWeb.Oauth.AuthorizeController.authorize(conn, params)
  end
end
