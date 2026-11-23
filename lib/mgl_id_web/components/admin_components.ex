defmodule MglIdWeb.AdminComponents do
  @moduledoc false
  use Phoenix.Component

  import MglIdWeb.MnComponents

  use Phoenix.VerifiedRoutes,
    endpoint: MglIdWeb.Endpoint,
    router: MglIdWeb.Router,
    statics: MglIdWeb.static_paths()

  attr :active, :string, default: "home"
  slot :inner_block, required: true

  def admin_shell(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID Admin">
      <:rail>
        <a class={"mn-rail-link mn-latin #{if @active == "home", do: "font-bold"}"} href={~p"/admin"}>
          Dashboard
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "users", do: "font-bold"}"}
          href={~p"/admin/users"}
        >
          Users
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "registrations", do: "font-bold"}"}
          href={~p"/admin/registrations"}
        >
          Reviews
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "clients", do: "font-bold"}"}
          href={~p"/admin/clients"}
        >
          Clients
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "migration", do: "font-bold"}"}
          href={~p"/admin/migration"}
        >
          Migration
        </a>
        <a class="mn-rail-link mn-latin" href={~p"/account"}>Account</a>
      </:rail>
      {render_slot(@inner_block)}
    </.mn_shell>
    """
  end
end
