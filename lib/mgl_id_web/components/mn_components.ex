defmodule MglIdWeb.MnComponents do
  @moduledoc """
  Traditional Mongolian shell layout helpers (mgl-common-ui).
  """
  use Phoenix.Component

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
          <span :if={@subtitle} class="mn-rail-link mn-text">{@subtitle}</span>
        </a>
        <nav :if={@rail != []} class="mn-rail-nav">
          {render_slot(@rail)}
        </nav>
      </aside>
      <main class="mn-surface" data-mn-drag phx-hook="MongolianScroll" id="mn-surface">
        <div class="mn-surface-inner mn-columns">
          <%!-- Render flash messages inline in vertical-lr flow --%>
          <div :if={msg = Phoenix.Flash.get(@flash, :info)} class="mn-flash mn-flash--info mn-text" role="status">
            {msg}
          </div>
          <div :if={msg = Phoenix.Flash.get(@flash, :error)} class="mn-flash mn-flash--error mn-text" role="alert">
            {msg}
          </div>
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end
end
