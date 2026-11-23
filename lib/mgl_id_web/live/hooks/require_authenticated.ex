defmodule MglIdWeb.Live.Hooks.RequireAuthenticated do
  @moduledoc false
  import Phoenix.LiveView
  import Phoenix.Component

  alias MglId.Accounts.User
  alias MglId.Mfa
  alias MglId.Policies

  def on_mount(:default, _params, session, socket) do
    case load_user(session) do
      {user, user_session} ->
        {:cont,
         socket
         |> assign(:current_user, user)
         |> assign(:current_session, user_session)
         |> assign(:mfa_ok, session["mfa_ok"] == true)}

      nil ->
        {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:admin, _params, session, socket) do
    case load_user(session) do
      {user, user_session} ->
        cond do
          not (User.admin?(user) or Policies.user_permissions(user) != []) ->
            {:halt, redirect(socket, to: "/")}

          Mfa.required_for?(user) and not Mfa.enabled?(user) ->
            {:halt, redirect(socket, to: "/account/security")}

          Mfa.required_for?(user) and Mfa.enabled?(user) and session["mfa_ok"] != true ->
            {:halt, redirect(socket, to: "/mfa")}

          true ->
            {:cont,
             socket
             |> assign(:current_user, user)
             |> assign(:current_session, user_session)
             |> assign(:mfa_ok, true)}
        end

      nil ->
        {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:maybe, _params, session, socket) do
    case load_user(session) do
      {user, user_session} ->
        {:cont,
         socket
         |> assign(:current_user, user)
         |> assign(:current_session, user_session)
         |> assign(:mfa_ok, session["mfa_ok"] == true)}

      nil ->
        {:cont,
         socket
         |> assign(:current_user, nil)
         |> assign(:current_session, nil)
         |> assign(:mfa_ok, false)}
    end
  end

  defp load_user(session) do
    token = session["session_token"]
    token && MglId.Sessions.get_user_by_session_token(token)
  end
end
