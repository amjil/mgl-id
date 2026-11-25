defmodule MglIdWeb.AdminComponents do
  @moduledoc false
  use Phoenix.Component

  import MglIdWeb.MnComponents

  use Phoenix.VerifiedRoutes,
    endpoint: MglIdWeb.Endpoint,
    router: MglIdWeb.Router,
    statics: MglIdWeb.static_paths()

  attr :active, :string, default: "home"
  attr :flash, :map, default: %{}
  slot :inner_block, required: true

  def admin_shell(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID" subtitle="ᠤᠳᠢᠷᠳᠤᠯᠭ᠎ᠠ" flash={@flash}>
      <:rail>
        <a class={"mn-rail-link mn-text #{if @active == "home", do: "font-bold"}"} href={~p"/admin"}>
          ᠬᠢᠨᠠᠯᠲᠠ
        </a>
        <a
          class={"mn-rail-link mn-text #{if @active == "users", do: "font-bold"}"}
          href={~p"/admin/users"}
        >
          ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ
        </a>
        <a
          class={"mn-rail-link mn-text #{if @active == "registrations", do: "font-bold"}"}
          href={~p"/admin/registrations"}
        >
          ᠰᠢᠯᠭᠠᠯᠲᠠ
        </a>
        <a
          class={"mn-rail-link mn-text #{if @active == "clients", do: "font-bold"}"}
          href={~p"/admin/clients"}
        >
          ᠬᠡᠷᠡᠭᠯᠡᠭᠡ
        </a>
        <a
          class={"mn-rail-link mn-text #{if @active == "migration", do: "font-bold"}"}
          href={~p"/admin/migration"}
        >
          ᠰᠢᠯᠵᠢᠭᠦᠯᠭᠡ
        </a>
        <a class="mn-rail-link mn-text" href={~p"/account"}>ᠪᠦᠷᠲᠦᠭᠡᠯ</a>
      </:rail>
      {render_slot(@inner_block)}
    </.mn_shell>
    """
  end
end
