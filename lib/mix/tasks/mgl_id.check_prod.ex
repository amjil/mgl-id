defmodule Mix.Tasks.MglId.CheckProd do
  @shortdoc "Print production go-live checklist status"
  @moduledoc """
  Validates required/recommended env vars and basic readiness checks.

      mix mgl_id.check_prod
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.config")
    {:ok, _} = Application.ensure_all_started(:mgl_id)

    report = MglId.Ops.go_live_checklist()

    Mix.shell().info("Mgl ID production checklist")
    Mix.shell().info("ready?: #{report.ready?}")

    Mix.shell().info("\nRequired env:")

    for item <- report.required do
      Mix.shell().info("  [#{mark(item.present)}] #{item.key}")
    end

    Mix.shell().info("\nRecommended env:")

    for item <- report.recommended do
      Mix.shell().info("  [#{mark(item.present)}] #{item.key}")
    end

    Mix.shell().info("\nChecks:")

    for check <- report.checks do
      Mix.shell().info("  [#{mark(check.ok)}] #{check.detail}")
    end

    if report.ready? do
      Mix.shell().info("\nAll required checks passed.")
    else
      Mix.shell().error("\nMissing required: #{Enum.join(report.missing_required, ", ")}")
      exit({:shutdown, 1})
    end
  end

  defp mark(true), do: "ok"
  defp mark(false), do: "!!"
end
