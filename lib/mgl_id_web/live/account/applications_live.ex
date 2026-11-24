defmodule MglIdWeb.Account.ApplicationsLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.AuthorizedApplications

  @impl true
  def mount(_params, _session, socket) do
    apps = AuthorizedApplications.list_for_user(socket.assigns.current_user.id)
    {:ok, assign(socket, page_title: "ᠬᠡᠷᠡᠭᠯᠡᠭᠡ", apps: apps)}
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
    <.account_shell current_user={@current_user} active="applications" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠵᠥᠪᠰᠢᠶᠡᠷᠡᠭᠰᠡᠨ ᠬᠡᠷᠡᠭᠯᠡᠭᠡ</h1>
        <%= if @apps == [] do %>
          <p class="mn-p mn-text">ᠵᠥᠪᠰᠢᠶᠡᠷᠡᠭᠰᠡᠨ ᠬᠡᠷᠡᠭᠯᠡᠭᠡ ᠦᠭᠡᠢ᠃</p>
        <% else %>
          <div class="mn-columns" style="gap: 1rem;">
            <%= for app <- @apps do %>
              <div class="mn-callout mn-stack">
                <p class="mn-p mn-upright">{(app.client && app.client.name) || app.client_id}</p>
                <p class="mn-p mn-text">
                  ᠡᠷᠬᠡ: <span class="mn-upright">{Enum.join(app.scopes, ", ")}</span>
                </p>
                <button phx-click="revoke" phx-value-client_id={app.client_id} class="mn-text btn">
                  ᠬᠦᠴᠦᠨ ᠦᠭᠡᠢ ᠪᠣᠯᠭᠠᠬᠤ
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
