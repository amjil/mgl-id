defmodule MglIdWeb.Plugs.RequireAuthenticated do
  @moduledoc false
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      format = get_format(conn)

      if format == "json" do
        conn
        |> put_status(:unauthorized)
        |> json(%{error: MglId.Errors.to_error(:unauthorized)})
        |> halt()
      else
        conn
        |> put_flash(:error, "Please log in")
        |> redirect(to: "/login")
        |> halt()
      end
    end
  end
end
