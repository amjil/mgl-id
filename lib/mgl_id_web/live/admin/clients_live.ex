defmodule MglIdWeb.Admin.ClientsLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents
  import MglIdWeb.MnComponents

  alias Boruta.Ecto.Admin
  alias MglId.{Clients, Policies}

  @impl true
  def mount(_params, _session, socket) do
    unless Policies.allow?(socket.assigns.current_user, "applications.read") or
             socket.assigns.current_user.is_admin do
      {:ok, push_navigate(socket, to: ~p"/account")}
    else
      _ = Clients.ensure_default_scopes!()

      {:ok,
       socket
       |> assign(page_title: "OAuth ᠬᠡᠷᠡᠭᠯᠡᠭᠡ")
       |> assign(clients: Clients.list_clients())
       |> assign(created: nil)
       |> assign(message: nil)}
    end
  end

  @impl true
  def handle_event("create", params, socket) do
    unless Policies.allow?(socket.assigns.current_user, "applications.manage") or
             socket.assigns.current_user.is_admin do
      {:noreply, socket}
    else
      scopes = Admin.get_scopes_by_names(["openid", "profile", "email", "offline_access"])
      uris = params["redirect_uris"] |> String.split(",", trim: true) |> Enum.map(&String.trim/1)

      case Clients.create_client(%{
             name: params["name"],
             redirect_uris: uris,
             supported_grant_types: ["authorization_code", "refresh_token"],
             access_token_ttl: 600,
             authorization_code_ttl: 60,
             refresh_token_ttl: 60 * 60 * 24 * 30,
             id_token_ttl: 600,
             id_token_signature_alg: "RS256",
             pkce: true,
             confidential: params["confidential"] == "true",
             authorize_scope: true,
             authorized_scopes: Enum.map(scopes, &%{id: &1.id}),
             token_endpoint_auth_methods: ["client_secret_basic", "client_secret_post", "none"]
           }) do
        {:ok, client} ->
          {:noreply,
           socket
           |> assign(clients: Clients.list_clients())
           |> assign(created: client)
           |> assign(message: "ᠬᠡᠷᠡᠭᠯᠡᠭᠡ ᠡᠭᠦᠰᠭᠡᠪᠡ᠃ ᠨᠢᠭᠤᠴᠠ ᠲᠦᠯᠬᠢᠭᠦᠷ ᠭᠠᠭᠴᠠ ᠨᠢᠭᠡᠨ ᠦᠵᠡᠭᠦᠯᠦᠨ᠎ᠡ᠃")}

        {:error, _} ->
          {:noreply, assign(socket, message: "ᠬᠡᠷᠡᠭᠯᠡᠭᠡ ᠡᠭᠦᠰᠬᠡᠵᠦ ᠴᠢᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ᠃")}
      end
    end
  end

  def handle_event("rotate", %{"id" => id}, socket) do
    client = Clients.get_client!(id)
    {:ok, client} = Admin.regenerate_client_secret(client)

    {:noreply,
     socket
     |> assign(clients: Clients.list_clients())
     |> assign(created: client)
     |> assign(message: "ᠨᠢᠭᠤᠴᠠ ᠲᠦᠯᠬᠢᠭᠦᠷ ᠰᠣᠯᠢᠭᠳᠠᠪᠠ᠃")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="clients" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="OAuth" title="ᠬᠡᠷᠡᠭᠯᠡᠭᠡ" />

        <form phx-submit="create" class="mn-form">
          <label class="mn-field">
            <span class="mn-text">ᠨᠡᠷ᠎ᠡ</span>
            <input class="mn-input mn-input-latin" name="name" required />
          </label>
          <label class="mn-field">
            <span class="mn-text">ᠪᠤᠴᠠᠬᠤ ᠬᠠᠶᠢᠭ <span class="mn-sideways">(,)</span></span>
            <input
              class="mn-input mn-input-latin"
              name="redirect_uris"
              placeholder="http://localhost:4001/callback"
              required
            />
          </label>
          <label class="mn-field">
            <input type="checkbox" name="confidential" value="true" checked />
            <span class="mn-text">ᠨᠢᠭᠤᠴᠠ ᠬᠡᠷᠡᠭᠯᠡᠭᠡ</span>
          </label>
          <button type="submit" class="mn-text btn btn-primary">ᠡᠭᠦᠰᠬᠡᠬᠦ</button>
        </form>

        <%= if @created do %>
          <div class="mn-callout">
            <p class="mn-p mn-sideways">client_id={@created.id}</p>
            <p class="mn-p mn-sideways">secret={@created.secret}</p>
          </div>
        <% end %>
        <%= if @message do %>
          <p class="mn-p mn-text">{@message}</p>
        <% end %>

        <hr class="mn-hr" />

        <div class="mn-columns" style="gap: 1rem;">
          <%= for c <- @clients do %>
            <div class="mn-callout">
              <p class="mn-p mn-text">
                <span class="mn-sideways">{c.name}</span> — <span class="mn-sideways">{c.id}</span>
              </p>
              <p class="mn-p mn-text">
                <span class="mn-sideways">PKCE: {inspect(c.pkce)}</span> ·
                <span class="mn-sideways">confidential: {inspect(c.confidential)}</span>
              </p>
              <button phx-click="rotate" phx-value-id={c.id} class="mn-text btn">
                ᠨᠢᠭᠤᠴᠠ ᠲᠦᠯᠬᠢᠭᠦᠷ ᠰᠣᠯᠢᠬᠤ
              </button>
            </div>
          <% end %>
        </div>
      </article>
    </.admin_shell>
    """
  end
end
