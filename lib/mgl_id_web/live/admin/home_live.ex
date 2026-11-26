defmodule MglIdWeb.Admin.HomeLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "ᠤᠳᠢᠷᠳᠤᠯᠭ᠎ᠠ")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="home" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-text">ᠤᠳᠢᠷᠳᠤᠯᠭ᠎ᠠ</h1>
        <p class="mn-lead mn-text">
          ᠬᠡᠷᠡᠭᠯᠡᠭᠴᠢ᠂ ᠪᠦᠷᠢᠳᠬᠡᠯ ᠦᠨ ᠰᠢᠯᠭᠠᠯᠲᠠ ᠪᠠ <span class="mn-sideways">OAuth</span> ᠬᠡᠷᠡᠭᠯᠡᠭᠡ ᠶᠢ ᠤᠳᠢᠷᠳᠤᠬᠤ᠃
        </p>
      </article>
    </.admin_shell>
    """
  end
end
