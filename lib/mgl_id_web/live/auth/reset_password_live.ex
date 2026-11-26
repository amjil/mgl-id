defmodule MglIdWeb.Auth.ResetPasswordLive do
  use MglIdWeb, :live_view

  import MglIdWeb.MnComponents

  alias MglId.Authentication

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠰᠢᠨᠡᠴᠢᠯᠡᠬᠦ",
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
        {:noreply, assign(socket, error: "ᠰᠢᠯᠲᠠᠭᠠᠰᠤᠨ ᠪᠤᠷᠤᠤ ᠪᠤᠶᠤ ᠬᠦᠴᠦᠨ ᠡᠮᠦ ᠪᠠᠢᠨ᠎ᠠ")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mn_shell title="Mgl ID" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="Mgl ID" title="ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠰᠢᠨᠡᠴᠢᠯᠡᠬᠦ" />
        <%= if @done do %>
          <p class="mn-p mn-text">
            ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠰᠢᠨᠡᠴᠢᠯᠡᠭᠳᠡᠪᠡ᠃ <a href={~p"/login"}>ᠨᠡᠪᠲᠡᠷᠡᠬᠦ</a>
          </p>
        <% else %>
          <form phx-submit="submit" class="mn-form">
            <input type="hidden" name="token" value={@token} />
            <label class="mn-field">
              <span class="mn-text">ᠰᠢᠨ᠎ᠡ ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ</span>
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
              <p class="mn-p mn-text text-error">{@error}</p>
            <% end %>
            <button type="submit" class="mn-text btn btn-primary">ᠬᠠᠳᠠᠭᠠᠯᠠᠬᠤ</button>
          </form>
        <% end %>
      </article>
    </.mn_shell>
    """
  end
end
