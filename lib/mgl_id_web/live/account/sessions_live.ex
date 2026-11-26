defmodule MglIdWeb.Account.SessionsLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents
  import MglIdWeb.MnComponents

  alias MglId.Sessions

  @impl true
  def mount(_params, _session, socket) do
    sessions = Sessions.list_user_sessions(socket.assigns.current_user.id)
    {:ok, assign(socket, page_title: "ᠨᠡᠪᠲᠡᠷᠡᠯᠲᠡ", sessions: sessions)}
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
    <.account_shell current_user={@current_user} active="sessions" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="Account" title="ᠨᠡᠪᠲᠡᠷᠡᠯᠲᠡ" />
        <button phx-click="revoke_all" class="mn-text btn btn-ghost">
          ᠪᠤᠰᠤᠳ ᠨᠠᠪᠲᠠᠷᠠᠯᠲᠠ᠎ᠶᠢ ᠬᠦᠴᠦᠨ ᠦᠭᠡᠢ ᠪᠣᠯᠭᠠᠬᠤ
        </button>
        <div class="mn-columns" style="gap: 1rem;">
          <%= for s <- @sessions do %>
            <div class="mn-callout">
              <p class="mn-p mn-text">
                ᠲᠥᠬᠥᠭᠡᠷᠦᠮᠵᠢ: <span class="mn-sideways">{s.device_name || "ᠲᠣᠳᠤᠷᠬᠠᠢ ᠦᠭᠡᠢ"}</span>
              </p>
              <p class="mn-p mn-text">
                <span class="mn-sideways">IP</span>: <span class="mn-sideways">{s.ip_address}</span>
              </p>
              <p class="mn-p mn-text">
                ᠰᠡᠭᠦᠯᠴᠢ᠎ᠶᠢᠨ ᠢᠳᠡᠪᠬᠢ: <span class="mn-sideways">{format_time(s.last_active_at)}</span>
              </p>
              <%= if @current_session && s.id == @current_session.id do %>
                <p class="mn-p mn-text">ᠣᠳᠣ᠎ᠶᠢᠨ ᠨᠡᠪᠲᠡᠷᠡᠯᠲᠡ</p>
              <% else %>
                <button phx-click="revoke" phx-value-id={s.id} class="mn-text btn">
                  ᠬᠦᠴᠦᠨ ᠦᠭᠡᠢ ᠪᠣᠯᠭᠠᠬᠤ
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
      </article>
    </.account_shell>
    """
  end

  defp format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_time(_), do: "—"
end
