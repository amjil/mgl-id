defmodule MglId.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    _ = MglId.Security.ensure_ets!()

    children = [
      MglIdWeb.Telemetry,
      MglId.Repo,
      {Oban, Application.fetch_env!(:mgl_id, Oban)},
      {DNSCluster, query: Application.get_env(:mgl_id, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MglId.PubSub},
      # Start a worker by calling: MglId.Worker.start_link(arg)
      # {MglId.Worker, arg},
      # Start to serve requests, typically the last entry
      MglIdWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MglId.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MglIdWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
