defmodule MglId.Registrations do
  @moduledoc """
  Hybrid registration review.
  """

  import Ecto.Query

  alias MglId.Accounts
  alias MglId.Accounts.User
  alias MglId.Audit
  alias MglId.Registrations.RegistrationReview
  alias MglId.Repo
  alias MglId.Security

  def evaluate_risk(attrs) do
    signals = []

    signals =
      case Map.get(attrs, :ip_address) do
        ip when is_binary(ip) and ip != "" ->
          count = Security.recent_registration_count(ip, 60)

          if count >= 5 do
            ["high_registration_rate" | signals]
          else
            signals
          end

        _ ->
          signals
      end

    review_mode = Application.get_env(:mgl_id, :registration_review_mode, "conditional")

    require_review =
      case review_mode do
        "always" -> true
        "never" -> false
        _ -> signals != []
      end

    %{require_review: require_review, signals: signals}
  end

  def create_pending_review(user_id, signals) do
    %RegistrationReview{}
    |> RegistrationReview.changeset(%{
      user_id: user_id,
      status: "pending_review",
      risk_signals: %{signals: signals}
    })
    |> Repo.insert()
  end

  def list_pending do
    Repo.all(
      from r in RegistrationReview,
        where: r.status == "pending_review",
        preload: [:user],
        order_by: [asc: r.inserted_at]
    )
  end

  def approve(%RegistrationReview{} = review, %User{} = admin, reason \\ nil) do
    Repo.transaction(fn ->
      {:ok, review} =
        review
        |> RegistrationReview.changeset(%{
          status: "approved",
          reviewed_by_id: admin.id,
          reviewed_at: DateTime.utc_now(),
          reason: reason
        })
        |> Repo.update()

      user = Accounts.get_user!(review.user_id)
      {:ok, user} = Accounts.set_review_status(user, "approved")
      {:ok, user} = Accounts.change_status(user, "active")

      Audit.log("registrations.approve", %{
        actor_id: admin.id,
        resource_type: "user",
        resource_id: user.id,
        metadata: %{reason: reason}
      })

      %{review: review, user: user}
    end)
  end

  def reject(%RegistrationReview{} = review, %User{} = admin, reason) do
    Repo.transaction(fn ->
      {:ok, review} =
        review
        |> RegistrationReview.changeset(%{
          status: "rejected",
          reviewed_by_id: admin.id,
          reviewed_at: DateTime.utc_now(),
          reason: reason
        })
        |> Repo.update()

      user = Accounts.get_user!(review.user_id)
      {:ok, user} = Accounts.set_review_status(user, "rejected")
      {:ok, user} = Accounts.change_status(user, "disabled")

      Audit.log("registrations.reject", %{
        actor_id: admin.id,
        resource_type: "user",
        resource_id: user.id,
        metadata: %{reason: reason}
      })

      %{review: review, user: user}
    end)
  end

  def get_review!(id), do: Repo.get!(RegistrationReview, id) |> Repo.preload(:user)
end
