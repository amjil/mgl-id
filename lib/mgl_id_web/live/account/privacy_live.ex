defmodule MglIdWeb.Account.PrivacyLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents
  import MglIdWeb.MnComponents

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
     |> assign(message: "ᠪᠦᠷᠢᠳᠬᠡᠯ ᠤᠰᠠᠳᠬᠠᠬᠤ ᠬᠦᠰᠡᠯᠲᠡ ᠢᠯᠡᠭᠡᠭᠳᠡᠪᠡ᠃")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="privacy" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="Account" title="ᠨᠢᠭᠤᠴᠠᠯᠠᠯ">
          <p class="mn-lead mn-text">
            ᠪᠦᠷᠢᠳᠬᠡᠯ ᠤᠰᠠᠳᠬᠠᠬᠤ ᠬᠦᠰᠡᠯᠲᠡ ᠢᠯᠡᠭᠡᠬᠦ᠃ ᠢᠩᠭᠢᠭᠰᠡᠨ᠎ᠢᠶᠡᠷ ᠪᠦᠷᠢᠳᠬᠡᠯ ᠰᠢᠭᠤᠳ ᠤᠰᠠᠳᠬᠠᠭᠳᠠᠬᠤ ᠦᠭᠡᠢ ᠬᠠᠷᠢᠨ ᠤᠷᠢᠳᠴᠢᠯᠠᠨ ᠬᠢᠨᠠᠨ ᠰᠢᠯᠭᠠᠬᠤ ᠦᠢᠯᠡ ᠶᠠᠪᠤᠴᠠ ᠡᠬᠢᠯᠡᠬᠦ ᠪᠣᠯᠤᠨ᠎ᠠ᠃
          </p>
        </.mn_page_head>
        <button
          phx-click="delete"
          data-confirm="ᠪᠦᠷᠢᠳᠬᠡᠯ ᠤᠰᠠᠳᠬᠠᠬᠤ ᠬᠦᠰᠡᠯᠲᠡ ᠢᠯᠡᠭᠡᠬᠦ ᠦᠦ？"
          class="mn-text btn btn-ghost"
        >
          ᠪᠦᠷᠢᠳᠬᠡᠯ ᠤᠰᠠᠳᠬᠠᠬᠤ
        </button>
        <%= if @message do %>
          <p class="mn-p mn-text">{@message}</p>
        <% end %>
      </article>
    </.account_shell>
    """
  end
end
