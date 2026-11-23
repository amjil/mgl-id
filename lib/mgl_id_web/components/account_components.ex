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
  slot :inner_block, required: true

  def account_shell(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID">
      <:rail>
        <a
          class={"mn-rail-link mn-latin #{if @active == "home", do: "font-bold"}"}
          href={~p"/account"}
        >
          Home
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "profile", do: "font-bold"}"}
          href={~p"/account/profile"}
        >
          Profile
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "security", do: "font-bold"}"}
          href={~p"/account/security"}
        >
          Security
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "sessions", do: "font-bold"}"}
          href={~p"/account/sessions"}
        >
          Sessions
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "applications", do: "font-bold"}"}
          href={~p"/account/applications"}
        >
          Apps
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "links", do: "font-bold"}"}
          href={~p"/account/links"}
        >
          Links
        </a>
        <a
          class={"mn-rail-link mn-latin #{if @active == "privacy", do: "font-bold"}"}
          href={~p"/account/privacy"}
        >
          Privacy
        </a>

        <%= if @current_user.is_admin do %>
          <a class="mn-rail-link mn-latin" href={~p"/admin"}>Admin</a>
        <% end %>
        <form action={~p"/logout"} method="post" class="inline">
          <input type="hidden" name="_method" value="delete" />
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <button type="submit" class="mn-rail-link mn-latin">Logout</button>
        </form>
      </:rail>
      {render_slot(@inner_block)}
    </.mn_shell>
    """
  end
end
