defmodule MglIdWeb.Account.ProfileLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents
  import MglIdWeb.MnComponents

  alias MglId.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(page_title: "ᠮᠡᠳᠡᠭᠡᠯᠡᠯ")
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
        {:noreply, put_flash(socket, :error, "ᠮᠡᠳᠡᠭᠡᠯᠡᠯ ᠬᠠᠳᠠᠭᠠᠯᠠᠵᠤ ᠴᠢᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="profile" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="Account" title="ᠮᠡᠳᠡᠭᠡᠯᠡᠯ" />
        <form phx-submit="save" class="mn-form">
          <label class="mn-field">
            <span class="mn-text">ᠨᠡᠷ᠎ᠡ</span>
            <input
              class="mn-input"
              type="text"
              name="display_name"
              value={@form[:display_name].value}
            />
          </label>
          <label class="mn-field">
            <span class="mn-text">ᠬᠡᠯᠡ</span>
            <input
              class="mn-input mn-input-latin"
              type="text"
              name="locale"
              value={@form[:locale].value}
            />
          </label>
          <label class="mn-field">
            <span class="mn-text">ᠴᠠᠭ ᠤᠨ ᠪᠦᠰᠡ</span>
            <input
              class="mn-input mn-input-latin"
              type="text"
              name="timezone"
              value={@form[:timezone].value}
            />
          </label>
          <label class="mn-field">
            <span class="mn-text">ᠲᠠᠨᠢᠯᠴᠠᠭᠤᠯᠭ᠎ᠠ</span>
            <textarea class="mn-textarea" name="bio">{@form[:bio].value}</textarea>
          </label>
          <button type="submit" class="mn-text btn btn-primary">ᠬᠠᠳᠠᠭᠠᠯᠠᠬᠤ</button>
        </form>
        <%= if @saved do %>
          <p class="mn-p mn-text">ᠬᠠᠳᠠᠭᠠᠯᠠᠭᠳᠠᠪᠠ᠃</p>
        <% end %>
      </article>
    </.account_shell>
    """
  end
end
