defmodule MglIdWeb.Account.ProfileLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(page_title: "Profile")
     |> assign(
       form:
         to_form(%{
           "display_name" => user.display_name,
           "locale" => user.locale,
           "timezone" => user.timezone,
           "bio" => user.bio
         })
     )
     |> assign(saved: false)}
  end

  @impl true
  def handle_event("save", params, socket) do
    case Accounts.update_profile(socket.assigns.current_user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
         |> assign(saved: true)
         |> assign(form: to_form(params))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not save profile")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="profile">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Profile</h1>
        <form phx-submit="save" class="mn-stack mn-latin" style="gap: 1rem;">
          <label>
            Display name
            <input
              class="mn-input"
              type="text"
              name="display_name"
              value={@form[:display_name].value}
            />
          </label>
          <label>
            Locale
            <input
              class="mn-input mn-input-latin"
              type="text"
              name="locale"
              value={@form[:locale].value}
            />
          </label>
          <label>
            Timezone
            <input
              class="mn-input mn-input-latin"
              type="text"
              name="timezone"
              value={@form[:timezone].value}
            />
          </label>
          <label>
            Bio <textarea class="mn-textarea" name="bio">{@form[:bio].value}</textarea>
          </label>
          <button type="submit" class="btn btn-primary">Save</button>
        </form>
        <%= if @saved do %>
          <p class="mn-p mn-latin">Saved.</p>
        <% end %>
      </article>
    </.account_shell>
    """
  end
end
