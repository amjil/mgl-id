defmodule MglIdWeb.AccountComponents do
  @moduledoc false
  use Phoenix.Component

  import MglIdWeb.MnComponents

  use Phoenix.VerifiedRoutes,
    endpoint: MglIdWeb.Endpoint,
    router: MglIdWeb.Router,
    statics: MglIdWeb.static_paths()

  attr :current_user, :map, required: true
  attr :active, :string, default: "home"
  attr :flash, :map, default: %{}
  slot :inner_block, required: true

  def account_shell(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID" flash={@flash}>
      <:rail>
        <.link
          class={"mn-rail-link mn-text #{if @active == "home", do: "font-bold"}"}
          navigate={~p"/account"}
        >
          ᠭᠡᠷ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "profile", do: "font-bold"}"}
          navigate={~p"/account/profile"}
        >
          ᠮᠡᠳᠡᠭᠡᠯᠡᠯ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "security", do: "font-bold"}"}
          navigate={~p"/account/security"}
        >
          ᠠᠮᠤᠷ ᠲᠠᠤᠯᠠᠢ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "sessions", do: "font-bold"}"}
          navigate={~p"/account/sessions"}
        >
          ᠨᠡᠪᠲᠡᠷᠡᠯᠲᠡ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "applications", do: "font-bold"}"}
          navigate={~p"/account/applications"}
        >
          ᠬᠡᠷᠡᠭᠯᠡᠭᠡ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "links", do: "font-bold"}"}
          navigate={~p"/account/links"}
        >
          ᠬᠣᠯᠪᠤᠭ᠎ᠠ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "privacy", do: "font-bold"}"}
          navigate={~p"/account/privacy"}
        >
          ᠨᠢᠭᠤᠴᠠᠯᠠᠯ
        </.link>

        <%= if @current_user.is_admin do %>
          <a class="mn-rail-link mn-text" href={~p"/admin"}>ᠤᠳᠢᠷᠳᠤᠯᠭ᠎ᠠ</a>
        <% end %>
        <form action={~p"/logout"} method="post" class="mn-rail-logout">
          <input type="hidden" name="_method" value="delete" />
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <button type="submit" class="mn-rail-link mn-text">ᠭᠠᠷᠬᠤ</button>
        </form>
      </:rail>
      {render_slot(@inner_block)}
    </.mn_shell>
    """
  end
end
