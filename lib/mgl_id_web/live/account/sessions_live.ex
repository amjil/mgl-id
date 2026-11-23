defmodule MglIdWeb.Account.SessionsLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.Sessions

  @impl true
  def mount(_params, _session, socket) do
    sessions = Sessions.list_user_sessions(socket.assigns.current_user.id)
    {:ok, assign(socket, page_title: "Sessions", sessions: sessions)}
  end

  @impl true
  def handle_event("revoke", %{"id" => id}, socket) do
    _ = Sessions.revoke_session(socket.assigns.current_user.id, id)
    sessions = Sessions.list_user_sessions(socket.assigns.current_user.id)
    {:noreply, assign(socket, sessions: sessions)}
  end

  def handle_event("revoke_all", _params, socket) do
    except = socket.assigns.current_session && socket.assigns.current_session.id
    _ = Sessions.revoke_all_user_sessions(socket.assigns.current_user.id, except)
    sessions = Sessions.list_user_sessions(socket.assigns.current_user.id)
    {:noreply, assign(socket, sessions: sessions)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="sessions">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Sessions</h1>
        <button phx-click="revoke_all" class="btn btn-ghost mn-latin">Revoke other sessions</button>
        <div class="mn-stack mn-latin" style="gap: 1rem; margin-top: 1rem;">
          <%= for s <- @sessions do %>
            <div>
              <p>Device: {s.device_name || "unknown"}</p>
              <p>IP: {s.ip_address}</p>
              <p>Last active: {s.last_active_at}</p>
              <%= if @current_session && s.id == @current_session.id do %>
                <p>Current session</p>
              <% else %>
                <button phx-click="revoke" phx-value-id={s.id} class="btn btn-sm">Revoke</button>
              <% end %>
            </div>
          <% end %>
        </div>
      </article>
    </.account_shell>
    """
  end
end
