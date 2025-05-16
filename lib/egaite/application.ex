defmodule Egaite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EgaiteWeb.Telemetry,
      Egaite.Repo,
      {DNSCluster, query: Application.get_env(:egaite, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Egaite.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Egaite.Finch},
      # Start a worker by calling: Egaite.Worker.start_link(arg)
      # {Egaite.Worker, arg},
      # Start to serve requests, typically the last entry
      EgaiteWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Egaite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EgaiteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
