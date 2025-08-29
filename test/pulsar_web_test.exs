defmodule PulsarWebTest do
  use ExUnit.Case

  describe "use PulsarWeb, :components" do
    test "imports all component functions" do
      # Create a test module that uses PulsarWeb
      defmodule TestComponents do
        use PulsarWeb, :components
      end

      # Check that component functions are available
      exported_functions = TestComponents.__info__(:functions)

      # Should have button function imported
      assert Keyword.has_key?(exported_functions, :button)
    end
  end

  describe "use PulsarWeb, :button" do
    test "imports only button component" do
      defmodule TestButton do
        use PulsarWeb, :button
      end

      exported_functions = TestButton.__info__(:functions)

      # Should have button function
      assert Keyword.has_key?(exported_functions, :button)
    end
  end

  describe "individual component imports" do
    test "supports individual component functions" do
      # Test that the component functions exist
      assert function_exported?(PulsarWeb, :components, 0)
      assert function_exported?(PulsarWeb, :button, 0)
      assert function_exported?(PulsarWeb, :card, 0)
      assert function_exported?(PulsarWeb, :alert, 0)
      assert function_exported?(PulsarWeb, :badge, 0)
    end
  end
end
