defmodule MglIdWeb.Admin.UserShowLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents

  alias MglId.{Accounts, Audit, Policies}
  alias MglId.AuthorizedApplications

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    unless Policies.allow?(socket.assigns.current_user, "users.read") or
             socket.assigns.current_user.is_admin do
      {:ok, push_navigate(socket, to: ~p"/account")}
    else
      user = Accounts.get_user!(id)

      {:ok,
       socket
       |> assign(page_title: user.username)
       |> assign(user: user)
       |> assign(attempts: Accounts.list_login_attempts(user.id))
       |> assign(apps: AuthorizedApplications.list_for_user(user.id))}
    end
  end

  @impl true
  def handle_event("status", %{"status" => status}, socket) do
    unless Policies.allow?(socket.assigns.current_user, "users.manage") or
             socket.assigns.current_user.is_admin do
      {:noreply, socket}
    else
      {:ok, user} = Accounts.change_status(socket.assigns.user, status)

      Audit.log("admin.user.status", %{
        actor_id: socket.assigns.current_user.id,
        resource_type: "user",
        resource_id: user.id,
        metadata: %{status: status}
      })

      {:noreply, assign(socket, user: user)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="users" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">{@user.username}</h1>
        <p class="mn-p mn-latin">ID: {@user.id}</p>
        <p class="mn-p mn-latin">Status: {@user.status}</p>
        <p class="mn-p mn-latin">Review: {@user.review_status}</p>
        <p class="mn-p mn-latin">Trust: {@user.trust_level}</p>

        <div class="mn-stack mn-latin" style="gap: 0.5rem;">
          <button phx-click="status" phx-value-status="active" class="btn btn-sm">Activate</button>
          <button phx-click="status" phx-value-status="suspended" class="btn btn-sm">Suspend</button>
          <button phx-click="status" phx-value-status="disabled" class="btn btn-sm">Disable</button>
        </div>

        <h2 class="mn-latin">Login attempts</h2>
        <%= for a <- @attempts do %>
          <p class="mn-p mn-latin">
            {a.inserted_at} — {if a.success, do: "ok", else: "fail"} — {a.ip_address}
          </p>
        <% end %>

        <h2 class="mn-latin">Linked apps</h2>
        <%= for app <- @apps do %>
          <p class="mn-p mn-latin">{(app.client && app.client.name) || app.client_id}</p>
        <% end %>
      </article>
    </.admin_shell>
    """
  end
end
