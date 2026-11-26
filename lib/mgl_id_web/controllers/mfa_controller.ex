defmodule MglIdWeb.MfaController do
  use MglIdWeb, :controller

  alias MglId.Mfa

  plug MglIdWeb.Plugs.RequireAuthenticated

  def new(conn, _params) do
    user = conn.assigns.current_user

    cond do
      not Mfa.required_for?(user) ->
        redirect(conn, to: ~p"/account")

      not Mfa.enabled?(user) ->
        conn
        |> put_flash(:error, "ᠤᠳᠢᠷᠳᠤᠯᠭ᠎ᠠ ᠬᠡᠷᠡᠭᠯᠡᠬᠦ ᠡᠴᠡ ᠡᠮᠦᠨ᠎ᠡ ᠬᠣᠶᠠᠷ ᠠᠯᠬᠤᠮᠲᠤ ᠪᠠᠲᠤᠮᠵᠢ ᠲᠣᠬᠢᠷᠠᠭᠤᠯᠤᠭᠠᠷᠠᠢ")
        |> redirect(to: ~p"/account/security")

      true ->
        render(conn, :new, page_title: "ᠬᠣᠶᠠᠷ ᠠᠯᠬᠤᠮᠲᠤ ᠪᠠᠲᠤᠮᠵᠢ")
    end
  end

  def create(conn, %{"code" => code}) do
    user = conn.assigns.current_user

    case Mfa.verify(user, code) do
      :ok ->
        return_to = get_session(conn, :mfa_return_to) || ~p"/admin"

        conn
        |> put_session(:mfa_ok, true)
        |> delete_session(:mfa_return_to)
        |> redirect(to: return_to)

      {:error, _} ->
        conn
        |> put_flash(:error, "ᠪᠠᠲᠤᠮᠵᠢ ᠶᠢᠨ ᠺᠣᠳ ᠪᠤᠷᠤᠤ")
        |> redirect(to: ~p"/mfa")
    end
  end
end

defmodule MglIdWeb.MfaHTML do
  use MglIdWeb, :html
  import MglIdWeb.MnComponents

  embed_templates "mfa_html/*"
end
