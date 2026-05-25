defmodule Pulsar.TestApp.Application do
  @moduledoc false

  use Application

  alias Pulsar.TestApp.Endpoint
  alias Pulsar.TestApp.PubSub

  @impl Application
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: PubSub},
      Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Pulsar.TestApp.Supervisor)
  end

  @impl Application
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
