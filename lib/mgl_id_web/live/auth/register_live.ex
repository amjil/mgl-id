defmodule MglIdWeb.Auth.RegisterLive do
  use MglIdWeb, :live_view

  import MglIdWeb.MnComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Register")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠪᠦᠷᠢᠳᠬᠡᠭᠦᠯᠬᠦ</h1>
        <p class="mn-p mn-latin">Create your Mgl ID</p>

        <form action={~p"/register"} method="post" class="mn-stack" style="gap: 1rem;">
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <label class="mn-latin">
            Username
            <input
              class="mn-input mn-input-latin"
              type="text"
              name="username"
              required
              autocomplete="username"
            />
          </label>
          <label class="mn-latin">
            Display name
            <input class="mn-input" type="text" name="display_name" autocomplete="nickname" />
          </label>
          <label class="mn-latin">
            Email (optional)
            <input class="mn-input mn-input-latin" type="email" name="email" autocomplete="email" />
          </label>
          <label class="mn-latin">
            Password (min 12)
            <input
              class="mn-input mn-input-latin"
              type="password"
              name="password"
              required
              minlength="12"
              autocomplete="new-password"
            />
          </label>
          <button type="submit" class="mn-latin btn btn-primary">Register</button>
        </form>

        <p class="mn-p mn-latin"><a href={~p"/login"}>Already have an account?</a></p>
      </article>
    </.mn_shell>
    """
  end
end
