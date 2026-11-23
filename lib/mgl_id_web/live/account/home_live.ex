defmodule MglIdWeb.Account.HomeLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Account")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="home">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Account</h1>
        <p class="mn-p mn-latin">Signed in as {@current_user.username}</p>
        <p class="mn-p">
          <span class="mn-latin">Display name:</span>
          <span class="mn-text">{@current_user.display_name}</span>
        </p>
        <p class="mn-p mn-latin">Status: {@current_user.status}</p>
      </article>
    </.account_shell>
    """
  end
end
