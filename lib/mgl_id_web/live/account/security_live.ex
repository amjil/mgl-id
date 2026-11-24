defmodule MglIdWeb.Account.SecurityLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.{Authentication, Mfa}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(page_title: "ᠠᠮᠤᠷ ᠲᠠᠤᠯᠠᠢ")
     |> assign(mfa_enabled: Mfa.enabled?(user))
     |> assign(mfa_uri: nil)
     |> assign(password_message: nil)
     |> assign(mfa_message: nil)}
  end

  @impl true
  def handle_event("change_password", params, socket) do
    case Authentication.change_password(
           socket.assigns.current_user,
           params["current_password"],
           params["new_password"]
         ) do
      :ok ->
        {:noreply,
         assign(socket,
           password_message: "ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠰᠣᠯᠢᠭᠳᠠᠪᠠ᠃ ᠳᠠᠬᠢᠨ ᠨᠡᠪᠲᠡᠷᠡᠭᠡᠷᠡᠢ᠃"
         )}

      {:error, _} ->
        {:noreply, assign(socket, password_message: "ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠰᠣᠯᠢᠵᠤ ᠴᠢᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ᠃")}
    end
  end

  def handle_event("mfa_setup", _params, socket) do
    {:ok, user, _secret, uri} = Mfa.begin_setup(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(current_user: user)
     |> assign(mfa_uri: uri)
     |> assign(
       mfa_message: "ᠪᠠᠲᠤᠮᠵᠢ ᠶᠢᠨ ᠬᠡᠷᠡᠭᠯᠡᠭᠡ ᠪᠡᠷ ᠤᠩᠰᠢᠭᠤᠯᠵᠤ ᠺᠣᠳ ᠢ ᠪᠠᠲᠤᠯᠠᠭᠠᠷᠠᠢ᠃"
     )}
  end

  def handle_event("mfa_confirm", %{"code" => code}, socket) do
    case Mfa.confirm_setup(socket.assigns.current_user, code) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
         |> assign(mfa_enabled: true)
         |> assign(mfa_uri: nil)
         |> assign(mfa_message: "ᠬᠣᠶᠠᠷ ᠠᠯᠬᠤᠮᠲᠤ ᠪᠠᠲᠤᠮᠵᠢ ᠨᠡᠭᠡᠭᠡᠭᠳᠡᠪᠡ᠃")}

      {:error, _} ->
        {:noreply, assign(socket, mfa_message: "ᠺᠣᠳ ᠪᠤᠷᠤᠤ ᠪᠠᠢᠨ᠎ᠠ᠃")}
    end
  end

  def handle_event("mfa_disable", _params, socket) do
    {:ok, user} = Mfa.disable(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(current_user: user)
     |> assign(mfa_enabled: false)
     |> assign(mfa_message: "ᠬᠣᠶᠠᠷ ᠠᠯᠬᠤᠮᠲᠤ ᠪᠠᠲᠤᠮᠵᠢ ᠬᠠᠭᠠᠭᠳᠠᠪᠠ᠃")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="security" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠠᠮᠤᠷ ᠲᠠᠤᠯᠠᠢ</h1>

        <h2 class="mn-h2 mn-text">ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠰᠣᠯᠢᠬᠤ</h2>
        <form phx-submit="change_password" class="mn-stack" style="gap: 1rem;">
          <label class="mn-field">
            <span class="mn-text">ᠣᠳᠤ ᠶᠢᠨ ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ</span>
            <input class="mn-input mn-input-latin" type="password" name="current_password" required />
          </label>
          <label class="mn-field">
            <span class="mn-text">ᠰᠢᠨ᠎ᠡ ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ</span>
            <input
              class="mn-input mn-input-latin"
              type="password"
              name="new_password"
              required
              minlength="12"
            />
          </label>
          <button type="submit" class="mn-text btn btn-primary">ᠰᠢᠨᠡᠴᠢᠯᠡᠬᠦ</button>
        </form>
        <%= if @password_message do %>
          <p class="mn-p mn-text">{@password_message}</p>
        <% end %>

        <hr class="mn-hr" />

        <h2 class="mn-h2 mn-text">ᠬᠣᠶᠠᠷ ᠠᠯᠬᠤᠮᠲᠤ ᠪᠠᠲᠤᠮᠵᠢ</h2>
        <%= if @mfa_enabled do %>
          <p class="mn-p mn-text">ᠬᠣᠶᠠᠷ ᠠᠯᠬᠤᠮᠲᠤ ᠪᠠᠲᠤᠮᠵᠢ ᠨᠡᠭᠡᠭᠡᠯᠲᠡᠲᠡᠢ ᠪᠠᠢᠨ᠎ᠠ᠃</p>
          <button phx-click="mfa_disable" class="mn-text btn btn-ghost">ᠬᠠᠭᠠᠬᠤ</button>
        <% else %>
          <button phx-click="mfa_setup" class="mn-text btn btn-primary">ᠲᠣᠬᠢᠷᠠᠭᠤᠯᠬᠤ</button>
          <%= if @mfa_uri do %>
            <%!-- Keep otpauth URI readable for copy/paste --%>
            <p class="mn-p mn-latin" style="word-break: break-all;">{@mfa_uri}</p>
            <form phx-submit="mfa_confirm" class="mn-stack" style="gap: 0.75rem;">
              <label class="mn-field">
                <span class="mn-text">ᠪᠠᠲᠤᠮᠵᠢ ᠶᠢᠨ ᠺᠣᠳ</span>
                <input
                  class="mn-input mn-input-latin"
                  type="text"
                  name="code"
                  placeholder="123456"
                  required
                />
              </label>
              <button type="submit" class="mn-text btn btn-primary">ᠪᠠᠲᠤᠯᠠᠬᠤ</button>
            </form>
          <% end %>
        <% end %>
        <%= if @mfa_message do %>
          <p class="mn-p mn-text">{@mfa_message}</p>
        <% end %>
      </article>
    </.account_shell>
    """
  end
end
