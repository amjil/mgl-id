defmodule MglIdWeb.Admin.MigrationLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents
  import MglIdWeb.MnComponents

  alias MglId.AccountLinks

  @impl true
  def mount(_params, _session, socket) do
    stats = AccountLinks.migration_stats()
    {:ok, assign(socket, page_title: "ᠰᠢᠯᠵᠢᠭᠦᠯᠭᠡ", stats: stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="migration" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="Admin" title="ᠪᠦᠷᠲᠦᠭᠡᠯ ᠰᠢᠯᠵᠢᠭᠦᠯᠭᠡ">
          <p class="mn-lead mn-text">
            ᠵᠥᠪᠬᠡᠨ ᠬᠣᠯᠪᠤᠬᠤ ᠭᠣᠷᠢᠮ᠃ ᠬᠠᠭᠤᠴᠢᠨ ᠨᠡᠪᠲᠡᠷᠡᠯᠲᠡ ᠨᠢ ᠬᠡᠷᠡᠭᠯᠡᠭᠡ ᠬᠠᠭᠠᠬᠤ ᠬᠦᠷᠲᠡᠯ᠎ᠡ ᠠᠵᠢᠯᠯᠠᠨ᠎ᠠ᠃
          </p>
        </.mn_page_head>
        <div class="mn-columns" style="gap: 0.85rem;">
          <p class="mn-p mn-text">
            ᠨᠡᠢᠲᠡ ᠬᠣᠯᠪᠤᠭᠰᠠᠨ: <span class="mn-sideways">{@stats.linked_total}</span>
          </p>
          <p class="mn-p mn-text">
            ᠬᠦᠯᠢᠶᠡᠭᠳᠡᠵᠦ ᠪᠤᠢ: <span class="mn-sideways">{@stats.pending_initiations}</span>
          </p>
          <%= for provider <- @stats.providers do %>
            <p class="mn-p mn-text">
              <span class="mn-sideways">{String.capitalize(provider)}</span> —
              ᠬᠣᠯᠪᠤᠭᠰᠠᠨ: <span class="mn-sideways">{Map.get(@stats.linked_by_provider, provider, 0)}</span> ·
              ᠰᠠᠯᠭᠠᠭᠰᠠᠨ: <span class="mn-sideways">{Map.get(@stats.unlinked_by_provider, provider, 0)}</span>
            </p>
          <% end %>
        </div>
      </article>
    </.admin_shell>
    """
  end
end
