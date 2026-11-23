defmodule MglIdWeb.Plugs.RequireAdmin do
  @moduledoc false
  import Plug.Conn
  import Phoenix.Controller

  alias MglId.Accounts.User

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && User.admin?(user) do
      conn
    else
      format = get_format(conn)

      if format == "json" do
        conn
        |> put_status(:forbidden)
        |> json(%{error: MglId.Errors.to_error(:forbidden)})
        |> halt()
      else
        conn
        |> put_flash(:error, "Forbidden")
        |> redirect(to: "/")
        |> halt()
      end
    end
  end
end
