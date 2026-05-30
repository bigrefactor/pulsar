defmodule Pulsar.DocCoverageFixture do
  @moduledoc false
  # Exercises every doc state Mix.Tasks.Pulsar.Docs.Coverage must distinguish.
  # Lives in test/support (not lib/) so it is compiled with a docs chunk that
  # Code.fetch_docs/1 can read, yet is excluded from the live audit/0 (which
  # only scans lib/).
  @behaviour Mix.Task

  @doc "Documented public function."
  def documented, do: :ok

  @doc false
  def hidden, do: :ok

  # Bare public function with no @doc — the one and only failure mode.
  def bare, do: :ok

  # Behaviour callback implementation — exempt (documented by the behaviour).
  @impl Mix.Task
  def run(_argv), do: :ok
end
