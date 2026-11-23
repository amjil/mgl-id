defmodule MglIdWeb.Account.ApplicationsLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.AuthorizedApplications

  @impl true
  def mount(_params, _session, socket) do
    apps = AuthorizedApplications.list_for_user(socket.assigns.current_user.id)
    {:ok, assign(socket, page_title: "Applications", apps: apps)}
  end

  @impl true
  def handle_event("revoke", %{"client_id" => client_id}, socket) do
    _ = AuthorizedApplications.revoke_for_user(socket.assigns.current_user.id, client_id)
    apps = AuthorizedApplications.list_for_user(socket.assigns.current_user.id)
    {:noreply, assign(socket, apps: apps)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="applications">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Authorized applications</h1>
        <%= if @apps == [] do %>
          <p class="mn-p mn-latin">No authorized applications.</p>
        <% else %>
          <div class="mn-stack mn-latin" style="gap: 1rem;">
            <%= for app <- @apps do %>
              <div>
                <p>{(app.client && app.client.name) || app.client_id}</p>
                <p>Scopes: {Enum.join(app.scopes, ", ")}</p>
                <button phx-click="revoke" phx-value-client_id={app.client_id} class="btn btn-sm">
                  Revoke
                </button>
              </div>
            <% end %>
          </div>
        <% end %>
      </article>
    </.account_shell>
    """
  end
end
