defmodule MglIdWeb.Auth.ResetPasswordLive do
  use MglIdWeb, :live_view

  import MglIdWeb.MnComponents

  alias MglId.Authentication

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Reset password",
       token: params["token"],
       done: false,
       error: nil
     )}
  end

  @impl true
  def handle_event("submit", %{"password" => password, "token" => token}, socket) do
    case Authentication.reset_password(token, password) do
      :ok ->
        {:noreply, assign(socket, done: true, error: nil)}

      {:error, _} ->
        {:noreply, assign(socket, error: "Invalid or expired token / weak password")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Reset password</h1>
        <%= if @done do %>
          <p class="mn-p mn-latin">Password updated. <a href={~p"/login"}>Sign in</a></p>
        <% else %>
          <form phx-submit="submit" class="mn-stack" style="gap: 1rem;">
            <input type="hidden" name="token" value={@token} />
            <label class="mn-latin">
              New password
              <input
                class="mn-input mn-input-latin"
                type="password"
                name="password"
                required
                minlength="12"
                autocomplete="new-password"
              />
            </label>
            <%= if @error do %>
              <p class="mn-p mn-latin text-error">{@error}</p>
            <% end %>
            <button type="submit" class="mn-latin btn btn-primary">Update password</button>
          </form>
        <% end %>
      </article>
    </.mn_shell>
    """
  end
end
