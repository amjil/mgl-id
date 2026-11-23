defmodule MglId.RegistrationsTest do
  use MglId.DataCase, async: true

  alias MglId.{Accounts, Fixtures, Registrations}

  test "high registration rate triggers review" do
    ip = "10.0.0.#{System.unique_integer([:positive])}"

    for i <- 1..5 do
      assert {:ok, _} =
               Fixtures.register_user(%{
                 username: "rate_#{i}_#{System.unique_integer([:positive])}",
                 meta: %{ip_address: ip}
               })
    end

    assert %{require_review: true, signals: signals} =
             Registrations.evaluate_risk(%{ip_address: ip})

    assert "high_registration_rate" in signals
  end

  test "admin can approve pending review" do
    assert {:ok, admin} =
             Fixtures.register_user(%{username: "admin_#{System.unique_integer([:positive])}"})

    {:ok, admin} =
      admin
      |> Ecto.Changeset.change(%{is_admin: true})
      |> MglId.Repo.update()

    # Force a review by seeding signals
    assert {:ok, user} =
             Fixtures.register_user(%{username: "pending_#{System.unique_integer([:positive])}"})

    {:ok, review} = Registrations.create_pending_review(user.id, ["manual"])
    {:ok, user} = Accounts.set_review_status(user, "pending_review")
    {:ok, _user} = Accounts.change_status(user, "pending")

    assert {:ok, %{user: approved}} = Registrations.approve(review, admin, "ok")
    assert approved.status == "active"
    assert approved.review_status == "approved"
  end
end
