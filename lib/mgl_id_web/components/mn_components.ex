defmodule MglIdWeb.MnComponents do
  @moduledoc """
  Traditional Mongolian shell layout helpers (mgl-common-ui).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :title, :string, default: "Mgl ID"
  attr :subtitle, :string, default: nil
  attr :flash, :map, default: %{}
  slot :inner_block, required: true
  slot :rail

  def mn_shell(assigns) do
    ~H"""
    <div class={["mn-shell", @rail == [] && "mn-shell--standalone"]}>
      <aside class="mn-rail">
        <a class="mn-brand" href="/" title={@title}>
          <span class="mn-brand-seal" aria-hidden="true">ᠮ</span>
          <span class="mn-brand-name">{@title}</span>
          <span :if={@subtitle} class="mn-brand-sub">{@subtitle}</span>
        </a>
        <nav :if={@rail != []} class="mn-rail-nav">
          {render_slot(@rail)}
        </nav>
      </aside>
      <main class="mn-surface" data-mn-drag phx-hook="MongolianScroll" id="mn-surface">
        <div class="mn-surface-inner mn-columns">
          <%!-- Clickable inline flash notices in vertical-lr flow --%>
          <div
            :if={msg = Phoenix.Flash.get(@flash, :info)}
            id="mn-flash-info"
            class="mn-flash mn-flash--info mn-text"
            role="status"
            phx-click={JS.push("lv:clear-flash", value: %{key: :info}) |> JS.hide(to: "#mn-flash-info")}
          >
            {msg}
          </div>
          <div
            :if={msg = Phoenix.Flash.get(@flash, :error)}
            id="mn-flash-error"
            class="mn-flash mn-flash--error mn-text"
            role="alert"
            phx-click={JS.push("lv:clear-flash", value: %{key: :error}) |> JS.hide(to: "#mn-flash-error")}
          >
            {msg}
          </div>
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end

  @doc """
  Page title pillar: ornament + optional kicker + h1 + optional lede.
  """
  attr :title, :string, required: true
  attr :kicker, :string, default: nil
  slot :inner_block

  def mn_page_head(assigns) do
    ~H"""
    <header class="mn-page-head">
      <span class="mn-ornament" aria-hidden="true"></span>
      <p :if={@kicker} class="mn-kicker">{@kicker}</p>
      <h1 class="mn-h1 mn-text">{@title}</h1>
      <div :if={@inner_block != []} class="mn-page-head__lede">
        {render_slot(@inner_block)}
      </div>
    </header>
    """
  end
end
