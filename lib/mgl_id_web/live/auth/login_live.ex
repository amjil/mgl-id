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
        <.mn_page_head kicker="Mgl ID" title="ᠨᠡᠪᠲᠡᠷᠡᠬᠦ">
          <p class="mn-lead mn-text">ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ ᠶᠢᠨ ᠨᠡᠷ᠎ᠡ ᠪᠡᠷ ᠨᠡᠪᠲᠡᠷᠡ</p>
        </.mn_page_head>

        <form action={~p"/login"} method="post" class="mn-form">
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
          <.link navigate={~p"/register"}>ᠪᠦᠷᠢᠳᠬᠡᠭᠦᠯᠬᠦ</.link>
          · <.link navigate={~p"/password/forgot"}>ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠪᠡᠨ ᠮᠠᠷᠲᠠᠪᠤᠤ?</.link>
        </p>
      </article>
    </.mn_shell>
    """
  end
end
