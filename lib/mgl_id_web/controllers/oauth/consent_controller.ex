defmodule MglIdWeb.Oauth.ConsentController do
  use MglIdWeb, :controller

  alias Boruta.Ecto.Admin
  alias MglIdWeb.Oauth.AuthorizeController

  plug MglIdWeb.Plugs.RequireAuthenticated

  def new(conn, params) do
    client_id = params["client_id"]
    scope = params["scope"] || ""
    client = safe_get_client(client_id)

    render(conn, :new,
      client: client,
      client_id: client_id,
      scope: scope,
      scopes: String.split(scope, " ", trim: true)
    )
  end

  def create(conn, %{"decision" => "allow"} = params) do
    client_id = params["client_id"]
    scope = params["scope"] || ""
    key = AuthorizeController.consent_key(client_id, scope)
    return_to = get_session(conn, :oauth_consent_return_to) || ~p"/account"

    conn
    |> put_session(key, true)
    |> delete_session(:oauth_consent_return_to)
    |> redirect(to: return_to)
  end

  def create(conn, _params) do
    conn
    |> delete_session(:oauth_consent_return_to)
    |> put_flash(:error, "ᠵᠥᠪᠰᠢᠶᠡᠷᠡᠯ ᠲᠠᠲᠠᠭᠠᠯᠵᠠᠭᠳᠠᠪᠠ")
    |> redirect(to: ~p"/account")
  end

  defp safe_get_client(nil), do: nil

  defp safe_get_client(id) do
    Admin.get_client!(id)
  rescue
    Ecto.NoResultsError -> nil
  end
end

defmodule MglIdWeb.Oauth.ConsentHTML do
  use MglIdWeb, :html

  import MglIdWeb.MnComponents

  embed_templates "consent_html/*"

  def scope_label("openid"), do: "ᠨᠡᠪᠲᠡᠷᠡᠯᠲᠡ ᠪᠠᠲᠤᠮᠵᠢ"
  def scope_label("profile"), do: "ᠨᠡᠢᠲᠡ ᠮᠡᠳᠡᠭᠡᠯᠡᠯ ᠢ ᠦᠵᠡᠬᠦ"
  def scope_label("email"), do: "ᠢᠮᠡᠯ ᠬᠠᠶᠢᠭ ᠢ ᠦᠵᠡᠬᠦ"
  def scope_label("offline_access"), do: "ᠳᠠᠬᠢᠨ ᠨᠡᠪᠲᠡᠷᠡᠬᠦ ᠡᠷᠬᠡ"
  def scope_label(scope) when is_binary(scope), do: scope
  def scope_label(_), do: ""
end
