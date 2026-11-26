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
        {:noreply, put_flash(socket, :error, "ᠨᠢᠭᠡᠨᠲᠡ ᠬᠣᠯᠪᠤᠭᠳᠠᠭᠰᠠᠨ ᠪᠠᠢᠨ᠎ᠠ")}

      {:error, :invalid_provider} ->
        {:noreply, put_flash(socket, :error, "ᠲᠣᠳᠤᠷᠬᠠᠢ ᠦᠭᠡᠢ ᠬᠡᠷᠡᠭᠯᠡᠭᠡ")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "ᠬᠣᠯᠪᠤᠬᠤ ᠶᠠᠪᠤᠴᠠ ᠡᠬᠢᠯᠡᠭᠦᠯᠵᠦ ᠴᠢᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ")}
    end
  end

  def handle_event("unlink", %{"link_id" => id, "password" => password}, socket) do
    case AccountLinks.unlink(socket.assigns.current_user, id, password) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "ᠬᠣᠯᠪᠤᠭ᠎ᠠ ᠰᠠᠯᠭᠠᠭᠳᠠᠪᠠ") |> refresh()}

      {:error, :invalid_credentials} ->
        {:noreply, put_flash(socket, :error, "ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ ᠪᠤᠷᠤᠤ")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "ᠬᠣᠯᠪᠤᠭ᠎ᠠ ᠣᠯᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "ᠬᠣᠯᠪᠤᠭ᠎ᠠ ᠰᠠᠯᠭᠠᠵᠤ ᠴᠢᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ")}
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

    assign(socket, page_title: "ᠬᠣᠯᠪᠤᠭᠰᠠᠨ ᠪᠦᠷᠲᠦᠭᠡᠯ", links: links, providers: providers)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="links" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠬᠣᠯᠪᠤᠭᠰᠠᠨ ᠪᠦᠷᠲᠦᠭᠡᠯ</h1>
        <p class="mn-lead mn-text">
          ᠬᠣᠯᠪᠤᠬᠤ ᠡᠴᠡ ᠡᠮᠦᠨ᠎ᠡ ᠲᠤᠰ ᠬᠡᠷᠡᠭᠯᠡᠭᠡᠨ ᠦ ᠪᠦᠷᠲᠦᠭᠡᠯ ᠢ ᠪᠠᠲᠤᠯᠠᠨ᠎ᠠ᠃
        </p>

        <div class="mn-columns" style="gap: 1.25rem;">
          <%= for p <- @providers do %>
            <div class="mn-callout">
              <p class="mn-p mn-sideways font-semibold">{p.name}</p>
              <%= if p.linked? do %>
                <% link = Enum.find(@links, &(&1.provider == p.id)) %>
                <p class="mn-p mn-text">
                  ᠬᠣᠯᠪᠤᠭᠳᠠᠭᠰᠠᠨ · <span class="mn-sideways">{link.external_user_id}</span>
                </p>
                <form phx-submit="unlink" class="mn-form">
                  <input type="hidden" name="link_id" value={link.id} />
                  <label class="mn-field">
                    <span class="mn-text">ᠨᠢᠭᠤᠴᠠ ᠦᠭᠡ</span>
                    <input
                      type="password"
                      name="password"
                      class="mn-input mn-input-latin"
                      required
                    />
                  </label>
                  <button type="submit" class="mn-text btn btn-ghost">ᠰᠠᠯᠭᠠᠬᠤ</button>
                </form>
              <% else %>
                <button
                  type="button"
                  class="mn-text btn btn-primary"
                  phx-click="initiate"
                  phx-value-provider={p.id}
                >
                  ᠬᠣᠯᠪᠤᠬᠤ
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
