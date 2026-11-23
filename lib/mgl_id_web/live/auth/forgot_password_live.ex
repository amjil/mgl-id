defmodule MglIdWeb.Auth.ForgotPasswordLive do
  use MglIdWeb, :live_view

  import MglIdWeb.MnComponents

  alias MglId.Authentication

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Forgot password", sent: false)}
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
    <.mn_shell title="Mgl ID">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Forgot password</h1>
        <%= if @sent do %>
          <p class="mn-p mn-latin">If the account exists, a reset email was sent.</p>
        <% else %>
          <form phx-submit="submit" class="mn-stack" style="gap: 1rem;">
            <label class="mn-latin">
              Username <input class="mn-input mn-input-latin" type="text" name="username" required />
            </label>
            <button type="submit" class="mn-latin btn btn-primary">Send reset</button>
          </form>
        <% end %>
        <p class="mn-p mn-latin"><a href={~p"/login"}>Back to login</a></p>
      </article>
    </.mn_shell>
    """
  end
end
