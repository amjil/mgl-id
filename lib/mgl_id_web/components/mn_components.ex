defmodule MglIdWeb.MnComponents do
  @moduledoc """
  Traditional Mongolian shell layout helpers (mgl-common-ui).
  """
  use Phoenix.Component

  attr :title, :string, default: "Mgl ID"
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
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end
end
