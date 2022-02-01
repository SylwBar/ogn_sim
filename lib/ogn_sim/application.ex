defmodule OgnSim.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: Registry.ConnectionsTCP},
      # System.schedulers_online()}
      {Registry, keys: :duplicate, name: Registry.Objects, partitions: 1}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OgnSim.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
