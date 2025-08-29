defmodule PulsarTest do
  use ExUnit.Case
  doctest Pulsar

  describe "version/0" do
    test "returns a version string" do
      version = Pulsar.version()
      assert is_binary(version)
      assert String.match?(version, ~r/^\d+\.\d+\.\d+/)
    end
  end
end
