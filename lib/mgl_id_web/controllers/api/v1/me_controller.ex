defmodule MglIdWeb.Api.V1.MeController do
  use MglIdWeb, :controller

  alias MglId.Accounts
  alias MglId.Accounts.User
  alias MglId.Errors

  def show(conn, _params) do
    json(conn, %{data: User.public_attrs(conn.assigns.current_user), meta: %{}})
  end

  def update(conn, params) do
    case Accounts.update_profile(conn.assigns.current_user, params) do
      {:ok, user} ->
        json(conn, %{data: User.public_attrs(user), meta: %{}})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: %{
            code: "VALIDATION_ERROR",
            message: "Invalid profile",
            details: Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
          }
        })
    end
  end

  def delete(conn, _params) do
    case Accounts.request_deletion(conn.assigns.current_user) do
      {:ok, user} ->
        json(conn, %{data: User.public_attrs(user), meta: %{}})

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: Errors.to_error(:unknown)})
    end
  end
end
