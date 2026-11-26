defmodule MglIdWeb.Account.HomeLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AccountComponents
  import MglIdWeb.MnComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "ᠪᠦᠷᠲᠦᠭᠡᠯ")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.account_shell current_user={@current_user} active="home" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="Account" title="ᠪᠦᠷᠲᠦᠭᠡᠯ">
          <p class="mn-lead mn-text">ᠲᠠᠨ ᠤ ᠪᠦᠷᠲᠦᠭᠡᠯ ᠶᠢᠨ ᠲᠣᠪᠴᠢ</p>
        </.mn_page_head>
        <div class="mn-callout mn-callout--profile">
          <div class="mn-kv">
            <p class="mn-kv-row">
              <span class="mn-kv-key mn-text">ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ</span>
              <span class="mn-sideways">{@current_user.username}</span>
            </p>
            <p class="mn-kv-row">
              <span class="mn-kv-key mn-text">ᠨᠡᠷ᠎ᠡ</span>
              <span class="mn-text">{@current_user.display_name}</span>
            </p>
            <p class="mn-kv-row">
              <span class="mn-kv-key mn-text">ᠪᠠᠶᠢᠳᠠᠯ</span>
              <span class={["mn-sideways mn-badge", status_badge_class(@current_user.status)]}>
                {@current_user.status}
              </span>
            </p>
          </div>
        </div>
      </article>
    </.account_shell>
    """
  end

  defp status_badge_class("active"), do: "mn-badge--ok"
  defp status_badge_class("pending"), do: "mn-badge--warn"
  defp status_badge_class(_), do: "mn-badge--danger"
end
