defmodule MglIdWeb.Admin.ClientsLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents

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
       |> assign(page_title: "Clients")
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
           |> assign(message: "Client created. Secret shown once.")}

        {:error, _} ->
          {:noreply, assign(socket, message: "Failed to create client")}
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
     |> assign(message: "Secret rotated.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="clients">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">OAuth clients</h1>

        <form phx-submit="create" class="mn-stack mn-latin" style="gap: 0.75rem;">
          <label>
            Name <input class="mn-input mn-input-latin" name="name" required />
          </label>
          <label>
            Redirect URIs (comma-separated)
            <input
              class="mn-input mn-input-latin"
              name="redirect_uris"
              placeholder="http://localhost:4001/callback"
              required
            />
          </label>
          <label>
            <input type="checkbox" name="confidential" value="true" checked /> Confidential
          </label>
          <button type="submit" class="btn btn-primary">Create</button>
        </form>

        <%= if @created do %>
          <p class="mn-p mn-latin">client_id={@created.id}</p>
          <p class="mn-p mn-latin">secret={@created.secret}</p>
        <% end %>
        <%= if @message do %>
          <p class="mn-p mn-latin">{@message}</p>
        <% end %>

        <div class="mn-stack mn-latin" style="gap: 1rem; margin-top: 1.5rem;">
          <%= for c <- @clients do %>
            <div>
              <p>{c.name} — {c.id}</p>
              <p>PKCE: {inspect(c.pkce)} confidential: {inspect(c.confidential)}</p>
              <button phx-click="rotate" phx-value-id={c.id} class="btn btn-sm">Rotate secret</button>
            </div>
          <% end %>
        </div>
      </article>
    </.admin_shell>
    """
  end
end
