defmodule MglIdWeb.Admin.UsersLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents

  alias MglId.Accounts
  alias MglId.Policies

  @impl true
  def mount(_params, _session, socket) do
    unless Policies.allow?(socket.assigns.current_user, "users.read") or
             socket.assigns.current_user.is_admin do
      {:ok, push_navigate(socket, to: ~p"/account")}
    else
      {:ok,
       socket
       |> assign(page_title: "ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ")
       |> assign(q: "")
       |> assign(users: Accounts.list_users())}
    end
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, assign(socket, q: q, users: Accounts.list_users(q: q))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="users" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ</h1>
        <form phx-change="search" class="mn-form">
          <label class="mn-field">
            <span class="mn-text">ᠬᠠᠢᠬᠤ</span>
            <input
              class="mn-input mn-input-latin"
              type="search"
              name="q"
              value={@q}
              placeholder="username"
            />
          </label>
        </form>
        <div class="mn-columns" style="gap: 0.75rem;">
          <%= for u <- @users do %>
            <a href={~p"/admin/users/#{u.id}"} class="mn-callout mn-text">
              <span class="mn-sideways">{u.username}</span> — <span class="mn-sideways">{u.status}</span>
            </a>
          <% end %>
        </div>
      </article>
    </.admin_shell>
    """
  end
end
