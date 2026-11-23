defmodule MglIdWeb.Admin.MigrationLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents

  alias MglId.AccountLinks

  @impl true
  def mount(_params, _session, socket) do
    stats = AccountLinks.migration_stats()
    {:ok, assign(socket, page_title: "Migration", stats: stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="migration">
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Account migration</h1>
        <p class="mn-p mn-latin">
          Link-mode only. Old product logins stay available until products turn them off.
        </p>
        <div class="mn-stack mn-latin" style="gap: 0.75rem; margin-top: 1rem;">
          <p>Linked total: {@stats.linked_total}</p>
          <p>Pending initiations: {@stats.pending_initiations}</p>
          <%= for provider <- @stats.providers do %>
            <p>
              {String.capitalize(provider)} linked: {Map.get(@stats.linked_by_provider, provider, 0)} ·
              unlinked history: {Map.get(@stats.unlinked_by_provider, provider, 0)}
            </p>
          <% end %>
        </div>
      </article>
    </.admin_shell>
    """
  end
end
