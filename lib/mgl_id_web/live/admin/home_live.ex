defmodule MglIdWeb.Admin.HomeLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents
  import MglIdWeb.MnComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "ᠤᠳᠤᠷᠢᠳᠤᠯᠭ᠎ᠠ")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="home" flash={@flash}>
      <article class="mn-doc">
        <.mn_page_head kicker="Admin" title="ᠤᠳᠤᠷᠢᠳᠤᠯᠭ᠎ᠠ">
          <p class="mn-lead mn-text">
            ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ᠂ ᠪᠦᠷᠢᠳᠬᠡᠯ᠎ᠦᠨ ᠰᠢᠯᠭᠠᠯᠲᠠ ᠪᠠ <span class="mn-sideways">OAuth</span> ᠬᠡᠷᠡᠭᠯᠡᠭᠡ᠎ᠶᠢ ᠤᠳᠤᠷᠢᠳᠬᠤ᠃
          </p>
        </.mn_page_head>
      </article>
    </.admin_shell>
    """
  end
end
