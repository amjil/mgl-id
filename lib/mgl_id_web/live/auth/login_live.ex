defmodule MglIdWeb.Auth.LoginLive do
  use MglIdWeb, :live_view

  import MglIdWeb.MnComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "ᠨᠡᠪᠲᠡᠷᠡᠬᠦ")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠨᠡᠪᠲᠡᠷᠡᠬᠦ</h1>
        <p class="mn-p mn-text">ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ ᠶᠢᠨ ᠨᠡᠷ᠎ᠡ ᠪᠡᠷ ᠨᠡᠪᠲᠡᠷᠡ</p>

        <form action={~p"/login"} method="post" class="mn-stack" style="gap: 1rem;">
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <label class="mn-field">
            <span class="mn-text">ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ ᠶᠢᠨ ᠨᠡᠷ᠎ᠡ</span>
            <input
              class="mn-input mn-input-latin"
              type="text"
              name="username"
              required
              autocomplete="username"
            />
          </label>
          <label class="mn-field">
            <span class="mn-text">ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ</span>
            <input
              class="mn-input mn-input-latin"
              type="password"
              name="password"
              required
              autocomplete="current-password"
            />
          </label>
          <button type="submit" class="mn-text btn btn-primary">ᠨᠡᠪᠲᠡᠷᠡᠬᠦ</button>
        </form>

        <p class="mn-p mn-text">
          <a href={~p"/register"}>ᠪᠦᠷᠢᠳᠬᠡᠭᠦᠯᠬᠦ</a>
          · <a href={~p"/password/forgot"}>ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠪᠡᠨ ᠮᠠᠷᠲᠠᠪᠤᠤ?</a>
        </p>
      </article>
    </.mn_shell>
    """
  end
end
