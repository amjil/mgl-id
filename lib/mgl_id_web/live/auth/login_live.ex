defmodule MglIdWeb.Auth.LoginLive do
  use MglIdWeb, :live_view

  import MglIdWeb.MnComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Login")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠨᠡᠪᠲᠡᠷᠡᠬᠦ</h1>
        <p class="mn-p mn-latin">Sign in with your username</p>

        <form action={~p"/login"} method="post" class="mn-stack" style="gap: 1rem;">
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
            Password
            <input
              class="mn-input mn-input-latin"
              type="password"
              name="password"
              required
              autocomplete="current-password"
            />
          </label>
          <button type="submit" class="mn-latin btn btn-primary">Sign in</button>
        </form>

        <p class="mn-p mn-latin">
          <a href={~p"/register"}>Create account</a>
          · <a href={~p"/password/forgot"}>Forgot password</a>
        </p>
      </article>
    </.mn_shell>
    """
  end
end
