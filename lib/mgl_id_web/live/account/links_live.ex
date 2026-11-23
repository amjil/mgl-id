defmodule MglIdWeb.Account.LinksLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents

  alias MglId.AccountLinks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, refresh(socket)}
  end

  @impl true
  def handle_event("initiate", %{"provider" => provider}, socket) do
    case AccountLinks.initiate(socket.assigns.current_user, provider, %{}) do
      {:ok, result} ->
        {:noreply, redirect(socket, external: result.redirect_url)}

      {:error, {:account_link_exists, _}} ->
        {:noreply, put_flash(socket, :error, "Already linked")}

      {:error, :invalid_provider} ->
        {:noreply, put_flash(socket, :error, "Unknown provider")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not start linking")}
    end
  end

  def handle_event("unlink", %{"link_id" => id, "password" => password}, socket) do
    case AccountLinks.unlink(socket.assigns.current_user, id, password) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Unlinked") |> refresh()}

      {:error, :invalid_credentials} ->
        {:noreply, put_flash(socket, :error, "Password incorrect")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Link not found")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not unlink")}
    end
  end

  defp refresh(socket) do
    links = AccountLinks.list_for_user(socket.assigns.current_user.id)
    linked_providers = MapSet.new(Enum.map(links, & &1.provider))

    providers =
      AccountLinks.known_providers()
      |> Enum.map(fn p ->
        cfg = AccountLinks.provider_config(p) || %{}
        %{id: p, name: Map.get(cfg, :name, p), linked?: MapSet.member?(linked_providers, p)}
      end)

    assign(socket, page_title: "Linked accounts", links: links, providers: providers)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="links">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Linked accounts</h1>
        <p class="mn-p mn-latin">
          Prove ownership of a product account before linking. Never auto-merged by username or email.
        </p>

        <div class="mn-stack mn-latin" style="gap: 1.25rem; margin-top: 1rem;">
          <%= for p <- @providers do %>
            <div>
              <p class="font-semibold">{p.name}</p>
              <%= if p.linked? do %>
                <% link = Enum.find(@links, &(&1.provider == p.id)) %>
                <p>Linked · external id {link.external_user_id}</p>
                <form phx-submit="unlink" class="mn-stack" style="gap: 0.5rem; margin-top: 0.5rem;">
                  <input type="hidden" name="link_id" value={link.id} />
                  <input
                    type="password"
                    name="password"
                    placeholder="Password to unlink"
                    class="mn-latin input input-bordered input-sm"
                    required
                  />
                  <button type="submit" class="btn btn-sm btn-outline">Unlink</button>
                </form>
              <% else %>
                <button
                  type="button"
                  class="btn btn-sm"
                  phx-click="initiate"
                  phx-value-provider={p.id}
                >
                  Link {p.name}
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
      </article>
    </.account_shell>
    """
  end
end
