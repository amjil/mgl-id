defmodule MglIdWeb.Account.HomeLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "ᠪᠦᠷᠲᠦᠭᠡᠯ")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="home">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠪᠦᠷᠲᠦᠭᠡᠯ</h1>
        <p class="mn-p mn-text">
          ᠨᠡᠪᠲᠡᠷᠡᠭᠰᠡᠨ:
          <span class="mn-upright">{@current_user.username}</span>
        </p>
        <p class="mn-p">
          <span class="mn-text">ᠨᠡᠷ᠎ᠡ:</span>
          <span class="mn-text">{@current_user.display_name}</span>
        </p>
        <p class="mn-p mn-text">
          ᠪᠠᠶᠢᠳᠠᠯ: <span class="mn-upright">{@current_user.status}</span>
        </p>
      </article>
    </.account_shell>
    """
  end
end
