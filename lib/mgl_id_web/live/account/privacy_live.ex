defmodule MglIdWeb.Account.PrivacyLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "ᠨᠢᠭᠤᠴᠠᠯᠠᠯ", message: nil)}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, user} = Accounts.request_deletion(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(current_user: user)
     |> assign(message: "ᠪᠦᠷᠲᠦᠭᠡᠯ ᠤᠰᠠᠳᠬᠠᠬᠤ ᠬᠦᠰᠡᠯᠲᠡ ᠢᠯᠡᠭᠡᠭᠳᠡᠪᠡ᠃")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="privacy" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠨᠢᠭᠤᠴᠠᠯᠠᠯ</h1>
        <p class="mn-p mn-text">
          ᠪᠦᠷᠲᠦᠭᠡᠯ ᠤᠰᠠᠳᠬᠠᠬᠤ ᠬᠦᠰᠡᠯᠲᠡ ᠢᠯᠡᠭᠡᠬᠦ᠃ ᠡᠨᠡ ᠨᠢ ᠳᠠᠷᠤᠢ ᠤᠰᠠᠳᠬᠠᠬᠤ ᠦᠭᠡᠢ ᠪᠥᠭᠡᠳ ᠰᠢᠯᠭᠠᠬᠤ ᠶᠠᠪᠤᠴᠠ ᠡᠬᠢᠯᠡᠭᠦᠯᠦᠨ᠎ᠡ᠃
        </p>
        <button
          phx-click="delete"
          data-confirm="ᠪᠦᠷᠲᠦᠭᠡᠯ ᠤᠰᠠᠳᠬᠠᠬᠤ ᠬᠦᠰᠡᠯᠲᠡ ᠢᠯᠡᠭᠡᠬᠦ ᠦᠦ?"
          class="mn-text btn btn-ghost"
        >
          ᠪᠦᠷᠲᠦᠭᠡᠯ ᠤᠰᠠᠳᠬᠠᠬᠤ
        </button>
        <%= if @message do %>
          <p class="mn-p mn-text">{@message}</p>
        <% end %>
      </article>
    </.account_shell>
    """
  end
end
