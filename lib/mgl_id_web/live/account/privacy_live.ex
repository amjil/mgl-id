defmodule MglIdWeb.Account.PrivacyLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Privacy", message: nil)}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, user} = Accounts.request_deletion(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(current_user: user)
     |> assign(message: "Deletion requested. Account marked deletion_pending.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="privacy">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Privacy</h1>
        <p class="mn-p mn-latin">
          Request account deletion. This starts a deletion workflow and does not erase data immediately.
        </p>
        <button
          phx-click="delete"
          data-confirm="Request account deletion?"
          class="btn btn-ghost mn-latin"
        >
          Request deletion
        </button>
        <%= if @message do %>
          <p class="mn-p mn-latin">{@message}</p>
        <% end %>
      </article>
    </.account_shell>
    """
  end
end
