defmodule BitcoinSimulator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      BitcoinSimulatorWeb.Endpoint,
      Bitcoin.NetworkSupervisor,
      # Starts a worker by calling: BitcoinSimulator.Worker.start_link(arg)
      {BitcoinSimulatorWeb.ChartChannel.Monitor, [%{"msg" => [], "tx" => [], "tx_trans" => [], "btc_mined" => [], "hash_rate" => []}]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BitcoinSimulator.Supervisor]
    Supervisor.start_link(children, opts)

    BitcoinSimulator.simulation(20, 5, 10)
    
    timer = 5000
    startTime = DateTime.utc_now
    BitcoinSimulator.FetchData.update_all(timer, startTime)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BitcoinSimulatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
