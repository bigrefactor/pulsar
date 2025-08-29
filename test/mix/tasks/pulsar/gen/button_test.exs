defmodule Mix.Tasks.Pulsar.Gen.ButtonTest do
  use ExUnit.Case
  
  import ExUnit.CaptureIO
  
  alias Mix.Tasks.Pulsar.Gen.Button

  describe "info/2" do
    test "returns task info" do
      info = Button.info([], nil)
      
      assert info.group == :pulsar
      assert info.example == "mix pulsar.gen.button"
      assert is_list(info.positional)
      assert is_list(info.schema)
    end
  end

  describe "task functionality" do
    test "has required igniter implementation" do
      # Test that the module implements the Igniter.Mix.Task behaviour
      assert function_exported?(Button, :igniter, 2)
      assert function_exported?(Button, :info, 2)
    end
  end

  # Note: Full integration tests would require setting up a test Phoenix project
  # and testing the actual file generation, which is complex for a unit test.
  # These would typically be done as integration tests in a separate test suite.
end