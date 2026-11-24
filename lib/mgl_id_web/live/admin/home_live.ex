defmodule MglIdWeb.Admin.HomeLive do
  use MglIdWeb, :live_view

  import MglIdWeb.AdminComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Admin")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell active="home" flash={@flash}>
      <article class="mn-doc">
        <h1 class="mn-h1 mn-latin">Admin</h1>
        <p class="mn-p mn-latin">Manage users, registration reviews, and OAuth clients.</p>
      </article>
    </.admin_shell>
    """
  end
end
