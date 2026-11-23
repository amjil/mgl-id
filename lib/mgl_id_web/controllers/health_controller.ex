defmodule MglIdWeb.HealthController do
  @moduledoc """
  Liveness/readiness probes for reverse proxies and orchestration.
  """
  use MglIdWeb, :controller

  alias MglId.Ops

  @doc """
  Liveness: process is up (no dependency checks).
  """
  def live(conn, _params) do
    json(conn, %{
      status: "ok",
      service: "mgl-id",
      time: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  @doc """
  Readiness: database + Oban reachable. Used by load balancers.
  """
  def ready(conn, _params) do
    detail = Ops.health_detail()

    if detail.status == "ok" do
      json(conn, detail)
    else
      conn
      |> put_status(:service_unavailable)
      |> json(detail)
    end
  end

  @doc "Backward-compatible alias of readiness."
  def show(conn, params), do: ready(conn, params)
end
