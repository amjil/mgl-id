defmodule MglIdWeb.Auth.ForgotPasswordLive do
  use MglIdWeb, :live_view

  import MglIdWeb.MnComponents

  alias MglId.Authentication

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠰᠡᠷᠭᠡᠭᠡᠬᠦ", sent: false)}
  end

  @impl true
  def handle_event("submit", %{"username" => username}, socket) do
    meta = %{ip_address: nil}
    _ = Authentication.forgot_password(username, meta)
    {:noreply, assign(socket, sent: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠪᠡᠨ ᠮᠠᠷᠲᠠᠪᠤᠤ?</h1>
        <%= if @sent do %>
          <p class="mn-p mn-text">
            ᠪᠦᠷᠲᠦᠭᠡᠯ ᠪᠤᠢ ᠪᠤᠯ ᠰᠡᠷᠭᠡᠭᠡᠬᠦ ᠢᠮᠡᠯ ᠢᠯᠡᠭᠡᠪᠡ᠃
          </p>
        <% else %>
          <form phx-submit="submit" class="mn-stack" style="gap: 1rem;">
            <label class="mn-field">
              <span class="mn-text">ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ ᠶᠢᠨ ᠨᠡᠷ᠎ᠡ</span>
              <input class="mn-input mn-input-latin" type="text" name="username" required />
            </label>
            <button type="submit" class="mn-text btn btn-primary">ᠢᠯᠡᠭᠡᠬᠦ</button>
          </form>
        <% end %>
        <p class="mn-p mn-text"><a href={~p"/login"}>ᠨᠡᠪᠲᠡᠷᠡᠬᠦ ᠷᠤᠤ ᠪᠤᠴᠠᠬᠤ</a></p>
      </article>
    </.mn_shell>
    """
  end
end
