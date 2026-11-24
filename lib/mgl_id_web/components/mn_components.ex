defmodule MglIdWeb.MnComponents do
  @moduledoc """
  Traditional Mongolian shell layout helpers (mgl-common-ui).
  """
  use Phoenix.Component

  attr :title, :string, default: "Mgl ID"
  attr :flash, :map, default: %{}
  slot :inner_block, required: true
  slot :rail

  def mn_shell(assigns) do
    ~H"""
    <div class="mn-shell min-h-screen">
      <aside class="mn-rail">
        <a class="mn-rail-link mn-text" href="/">{@title}</a>
        {render_slot(@rail)}
      </aside>
      <main class="mn-surface" data-mn-drag phx-hook="MongolianScroll" id="mn-surface">
        <div class="mn-surface-inner mn-columns">
          <%!-- Render flash messages inline in vertical-lr flow --%>
          <div :if={msg = Phoenix.Flash.get(@flash, :info)} class="mn-callout mn-text" role="status">
            {msg}
          </div>
          <div :if={msg = Phoenix.Flash.get(@flash, :error)} class="mn-callout mn-text text-error" role="alert">
            {msg}
          </div>
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end
end
