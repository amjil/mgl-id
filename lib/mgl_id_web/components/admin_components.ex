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
        <.link
          class={"mn-rail-link mn-text #{if @active == "home", do: "font-bold"}"}
          navigate={~p"/admin"}
        >
          ᠬᠢᠨᠠᠯᠲᠠ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "users", do: "font-bold"}"}
          navigate={~p"/admin/users"}
        >
          ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "registrations", do: "font-bold"}"}
          navigate={~p"/admin/registrations"}
        >
          ᠰᠢᠯᠭᠠᠯᠲᠠ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "clients", do: "font-bold"}"}
          navigate={~p"/admin/clients"}
        >
          ᠬᠡᠷᠡᠭᠯᠡᠭᠡ
        </.link>
        <.link
          class={"mn-rail-link mn-text #{if @active == "migration", do: "font-bold"}"}
          navigate={~p"/admin/migration"}
        >
          ᠰᠢᠯᠵᠢᠭᠦᠯᠭᠡ
        </.link>
        <a class="mn-rail-link mn-text" href={~p"/account"}>ᠪᠦᠷᠲᠦᠭᠡᠯ</a>
      </:rail>
      {render_slot(@inner_block)}
    </.mn_shell>
    """
  end
end
