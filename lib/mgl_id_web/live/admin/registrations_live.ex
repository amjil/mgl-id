defmodule MglIdWeb.Admin.RegistrationsLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents

  alias MglId.{Policies, Registrations}

  @impl true
  def mount(_params, _session, socket) do
    unless Policies.allow?(socket.assigns.current_user, "registrations.review") or
             socket.assigns.current_user.is_admin do
      {:ok, push_navigate(socket, to: ~p"/account")}
    else
      {:ok,
       socket
       |> assign(page_title: "Registration reviews")
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
        <h1 class="mn-h1 mn-latin">Pending registrations</h1>
        <%= if @reviews == [] do %>
          <p class="mn-p mn-latin">No pending reviews.</p>
        <% else %>
          <div class="mn-stack" style="gap: 1.5rem;">
            <%= for review <- @reviews do %>
              <div class="mn-latin">
                <p>
                  {review.user.username} — {inspect(review.risk_signals)}
                </p>
                <button phx-click="approve" phx-value-id={review.id} class="btn btn-primary btn-sm">
                  Approve
                </button>
                <button phx-click="reject" phx-value-id={review.id} class="btn btn-ghost btn-sm">
                  Reject
                </button>
              </div>
            <% end %>
          </div>
        <% end %>
      </article>
    </.admin_shell>
    """
  end
end
