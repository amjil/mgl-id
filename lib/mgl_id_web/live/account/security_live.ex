defmodule MglIdWeb.Account.SecurityLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.{Authentication, Mfa}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(page_title: "Security")
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
        {:noreply, assign(socket, password_message: "Password changed. Please sign in again.")}

      {:error, _} ->
        {:noreply, assign(socket, password_message: "Could not change password.")}
    end
  end

  def handle_event("mfa_setup", _params, socket) do
    {:ok, user, _secret, uri} = Mfa.begin_setup(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(current_user: user)
     |> assign(mfa_uri: uri)
     |> assign(mfa_message: "Scan the otpauth URI with an authenticator, then confirm.")}
  end

  def handle_event("mfa_confirm", %{"code" => code}, socket) do
    case Mfa.confirm_setup(socket.assigns.current_user, code) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
         |> assign(mfa_enabled: true)
         |> assign(mfa_uri: nil)
         |> assign(mfa_message: "MFA enabled.")}

      {:error, _} ->
        {:noreply, assign(socket, mfa_message: "Invalid code.")}
    end
  end

  def handle_event("mfa_disable", _params, socket) do
    {:ok, user} = Mfa.disable(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(current_user: user)
     |> assign(mfa_enabled: false)
     |> assign(mfa_message: "MFA disabled.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="security">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Security</h1>

        <h2 class="mn-latin">Change password</h2>
        <form phx-submit="change_password" class="mn-stack mn-latin" style="gap: 1rem;">
          <label>
            Current password
            <input class="mn-input mn-input-latin" type="password" name="current_password" required />
          </label>
          <label>
            New password
            <input
              class="mn-input mn-input-latin"
              type="password"
              name="new_password"
              required
              minlength="12"
            />
          </label>
          <button type="submit" class="btn btn-primary">Update password</button>
        </form>
        <%= if @password_message do %>
          <p class="mn-p mn-latin">{@password_message}</p>
        <% end %>

        <h2 class="mn-latin">Authenticator MFA</h2>
        <%= if @mfa_enabled do %>
          <p class="mn-p mn-latin">MFA is enabled.</p>
          <button phx-click="mfa_disable" class="btn btn-ghost mn-latin">Disable MFA</button>
        <% else %>
          <button phx-click="mfa_setup" class="btn btn-primary mn-latin">Set up MFA</button>
          <%= if @mfa_uri do %>
            <p class="mn-p mn-latin" style="word-break: break-all;">{@mfa_uri}</p>
            <form phx-submit="mfa_confirm" class="mn-stack mn-latin" style="gap: 0.5rem;">
              <input
                class="mn-input mn-input-latin"
                type="text"
                name="code"
                placeholder="123456"
                required
              />
              <button type="submit" class="btn btn-primary">Confirm</button>
            </form>
          <% end %>
        <% end %>
        <%= if @mfa_message do %>
          <p class="mn-p mn-latin">{@mfa_message}</p>
        <% end %>
      </article>
    </.account_shell>
    """
  end
end
