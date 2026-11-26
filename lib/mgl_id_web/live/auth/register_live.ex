defmodule MglIdWeb.Auth.RegisterLive do
  use MglIdWeb, :live_view

  import MglIdWeb.MnComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "ᠪᠦᠷᠢᠳᠬᠡᠭᠦᠯᠬᠦ")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠪᠦᠷᠢᠳᠬᠡᠭᠦᠯᠬᠦ</h1>
        <p class="mn-lead mn-text">ᠮᠢᠨᠤ Mgl ID ᠪᠦᠷᠲᠦᠭᠡᠯ ᠡᠭᠦᠰᠬᠡᠬᠦ</p>

        <form action={~p"/register"} method="post" class="mn-form">
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
            <span class="mn-text">ᠨᠡᠷ᠎ᠡ</span>
            <input class="mn-input" type="text" name="display_name" autocomplete="nickname" />
          </label>
          <label class="mn-field">
            <span class="mn-text">ᠢᠮᠡᠯ （ᠰᠣᠩᠭᠣᠯᠲᠠᠲᠠᠢ）</span>
            <input class="mn-input mn-input-latin" type="email" name="email" autocomplete="email" />
          </label>
          <label class="mn-field">
            <span class="mn-text">ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ <span class="mn-sideways">(≥12)</span></span>
            <input
              class="mn-input mn-input-latin"
              type="password"
              name="password"
              required
              minlength="12"
              autocomplete="new-password"
            />
          </label>
          <button type="submit" class="mn-text btn btn-primary">ᠪᠦᠷᠢᠳᠬᠡᠭᠦᠯᠬᠦ</button>
        </form>

        <p class="mn-p mn-text">
          <a href={~p"/login"}>ᠪᠦᠷᠲᠦᠭᠡᠯ ᠪᠤᠢ ᠤᠤ? ᠨᠡᠪᠲᠡᠷᠡᠬᠦ</a>
        </p>
      </article>
    </.mn_shell>
    """
  end
end
