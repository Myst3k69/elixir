defmodule Rideau.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RideauWeb.Telemetry,
      Rideau.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:rideau, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:rideau, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Rideau.PubSub},
      RideauWeb.Presence,
      RideauWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rideau.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RideauWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
