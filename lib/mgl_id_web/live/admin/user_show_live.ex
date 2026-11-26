defmodule MglIdWeb.Admin.UserShowLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents
  import MglIdWeb.MnComponents

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
        <.mn_page_head kicker="Admin" title={@user.username} title_class="mn-sideways" />
        <p class="mn-p mn-text">
          <span class="mn-sideways">ID</span>: <span class="mn-sideways">{@user.id}</span>
        </p>
        <p class="mn-p mn-text">
          ᠪᠠᠶᠢᠳᠠᠯ: <span class="mn-sideways">{@user.status}</span>
        </p>
        <p class="mn-p mn-text">
          ᠰᠢᠯᠭᠠᠯᠲᠠ: <span class="mn-sideways">{@user.review_status}</span>
        </p>
        <p class="mn-p mn-text">
          ᠢᠲᠡᠭᠡᠯ ᠦᠨ ᠲᠦᠪᠰᠢᠨ: <span class="mn-sideways">{@user.trust_level}</span>
        </p>

        <div class="mn-actions">
          <button phx-click="status" phx-value-status="active" class="mn-text btn btn-primary">
            ᠢᠳᠡᠪᠬᠢᠵᠢᠭᠦᠯᠬᠦ
          </button>
          <button phx-click="status" phx-value-status="suspended" class="mn-text btn">
            ᠲᠦᠷ ᠵᠣᠭᠰᠤᠭᠠᠬᠤ
          </button>
          <button phx-click="status" phx-value-status="disabled" class="mn-text btn btn-ghost">
            ᠬᠠᠭᠠᠬᠤ
          </button>
        </div>

        <hr class="mn-hr" />

        <h2 class="mn-h2 mn-text">ᠨᠡᠪᠲᠡᠷᠡᠯᠲᠡ ᠶᠢᠨ ᠲᠡᠮᠳᠡᠭᠯᠡᠯ</h2>
        <%= for a <- @attempts do %>
          <p class="mn-p mn-text">
            <span class="mn-sideways">{format_time(a.inserted_at)}</span> —
            {if a.success, do: "ᠠᠮᠵᠢᠯᠲᠠᠲᠠᠢ", else: "ᠠᠮᠵᠢᠯᠲᠠᠭᠦᠢ"} —
            <span class="mn-sideways">{a.ip_address}</span>
          </p>
        <% end %>

        <hr class="mn-hr" />

        <h2 class="mn-h2 mn-text">ᠬᠣᠯᠪᠤᠭᠰᠠᠨ ᠬᠡᠷᠡᠭᠯᠡᠭᠡ</h2>
        <%= for app <- @apps do %>
          <p class="mn-p mn-sideways">{(app.client && app.client.name) || app.client_id}</p>
        <% end %>
      </article>
    </.admin_shell>
    """
  end

  defp format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_time(_), do: "—"
end
