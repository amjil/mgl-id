defmodule MglIdWeb.PageController do
  use MglIdWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
