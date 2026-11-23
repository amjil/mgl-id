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
       |> assign(page_title: "Users")
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
    <.admin_shell active="users">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Users</h1>
        <form phx-change="search" class="mn-latin">
          <input
            class="mn-input mn-input-latin"
            type="search"
            name="q"
            value={@q}
            placeholder="Search"
          />
        </form>
        <div class="mn-stack mn-latin" style="gap: 0.75rem; margin-top: 1rem;">
          <%= for u <- @users do %>
            <a href={~p"/admin/users/#{u.id}"}>{u.username} — {u.status}</a>
          <% end %>
        </div>
      </article>
    </.admin_shell>
    """
  end
end
