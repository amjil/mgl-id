defmodule MglIdWeb.Admin.RegistrationsLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents
  import MglIdWeb.MnComponents

  alias MglId.{Policies, Registrations}

  @impl true
  def mount(_params, _session, socket) do
    unless Policies.allow?(socket.assigns.current_user, "registrations.review") or
             socket.assigns.current_user.is_admin do
      {:ok, push_navigate(socket, to: ~p"/account")}
    else
      {:ok,
       socket
       |> assign(page_title: "ᠪᠦᠷᠢᠳᠬᠡᠯ᠎ᠦᠨ ᠰᠢᠯᠭᠠᠯᠲᠠ")
       |> assign(reviews: Registrations.list_pending())}
    end
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    review = Registrations.get_review!(id)
    {:ok, _} = Registrations.approve(review, socket.assigns.current_user, "approved")
    {:noreply, assign(socket, reviews: Registrations.list_pending())}
  end

  def handle_event("reject", %{"id" => id}, socket) do
    review = Registrations.get_review!(id)
    {:ok, _} = Registrations.reject(review, socket.assigns.current_user, "rejected")
    {:noreply, assign(socket, reviews: Registrations.list_pending())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="registrations" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="Admin" title="ᠬᠦᠯᠢᠶᠡᠭᠳᠡᠵᠦ ᠪᠤᠢ ᠪᠦᠷᠢᠳᠬᠡᠯ" />
        <%= if @reviews == [] do %>
          <p class="mn-p mn-text">ᠰᠢᠯᠭᠠᠬᠤ ᠪᠦᠷᠢᠳᠬᠡᠯ ᠦᠭᠡᠢ᠃</p>
        <% else %>
          <div class="mn-columns" style="gap: 1.25rem;">
            <%= for review <- @reviews do %>
              <div class="mn-callout">
                <p class="mn-p mn-text">
                  <span class="mn-sideways">{review.user.username}</span> —
                  <span class="mn-sideways">{inspect(review.risk_signals)}</span>
                </p>
                <div class="mn-actions">
                  <button
                    phx-click="approve"
                    phx-value-id={review.id}
                    class="mn-text btn btn-primary"
                  >
                    ᠵᠥᠪᠰᠢᠶᠡᠷᠡᠬᠦ
                  </button>
                  <button phx-click="reject" phx-value-id={review.id} class="mn-text btn btn-ghost">
                    ᠲᠠᠲᠠᠭᠠᠯᠵᠠᠬᠤ
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </article>
    </.admin_shell>
    """
  end
end
