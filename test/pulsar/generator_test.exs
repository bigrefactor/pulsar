defmodule Pulsar.GeneratorTest do
  use ExUnit.Case, async: true

  describe "use Pulsar.Generator argument validation" do
    test ":component must be a non-nil atom" do
      assert_raise ArgumentError, ~r/:component to be an atom/, fn ->
        defmodule BadComponentString do
          use Pulsar.Generator,
            component: "button",
            example: "mix x",
            long_doc: "doc"
        end
      end

      assert_raise ArgumentError, ~r/:component to be an atom/, fn ->
        defmodule BadComponentNil do
          use Pulsar.Generator,
            component: nil,
            example: "mix x",
            long_doc: "doc"
        end
      end
    end

    test ":example must be a binary" do
      assert_raise ArgumentError, ~r/:example to be a binary/, fn ->
        defmodule BadExample do
          use Pulsar.Generator,
            component: :button,
            example: :not_a_binary,
            long_doc: "doc"
        end
      end
    end

    test ":long_doc must be a binary" do
      assert_raise ArgumentError, ~r/:long_doc to be a binary/, fn ->
        defmodule BadLongDoc do
          use Pulsar.Generator,
            component: :button,
            example: "mix x",
            long_doc: 123
        end
      end
    end

    test ":short_doc must be a binary or false" do
      assert_raise ArgumentError, ~r/:short_doc to be a binary or false/, fn ->
        defmodule BadShortDoc do
          use Pulsar.Generator,
            component: :button,
            example: "mix x",
            long_doc: "doc",
            short_doc: true
        end
      end
    end

    test "raises KeyError when a required option is missing" do
      assert_raise KeyError, fn ->
        defmodule MissingComponent do
          use Pulsar.Generator,
            example: "mix x",
            long_doc: "doc"
        end
      end
    end
  end

  describe "defoverridable" do
    defmodule OverridesIgniter do
      use Pulsar.Generator,
        component: :__test_override__,
        example: "mix pulsar.gen.__test_override__",
        long_doc: "test override"

      @impl Igniter.Mix.Task
      def igniter(igniter), do: igniter
    end

    test "downstream module can override igniter/1" do
      assert OverridesIgniter.igniter(:sentinel) == :sentinel
    end
  end
end
