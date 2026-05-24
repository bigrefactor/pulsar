defmodule Pulsar.GeneratorTest do
  use ExUnit.Case, async: true

  import Igniter.Test
  import Pulsar.BackupTestHelper

  @moduletag timeout: 180_000

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

  describe "install_component (shared codepath)" do
    test "backs up existing component before overwriting" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      assert_backup_created(igniter, "lib/test_web/components/button.ex")
    end

    test "backup preserves original component content" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      assert_backup_contains(igniter, "lib/test_web/components/button.ex", ~r/defmodule.*Button/)
      assert_backup_contains(igniter, "lib/test_web/components/button.ex", ~r/def button\(assigns\)/)
    end

    test "does not create backup when component is new" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      assert_no_backup_created(igniter, "lib/test_web/components/button.ex")
    end

    test "multiple regenerations create timestamped backups" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      backups = get_backup_files(igniter, "lib/test_web/components/button.ex")

      assert length(backups) == 1,
             "Expected 1 backup file after one regeneration, found #{length(backups)}"

      {backup_path, _source} = hd(backups)

      assert backup_path =~ ~r/button\.ex\.bak\.\d{8}T\d{6}/,
             "Backup filename should have timestamp pattern"
    end

    test "raises a descriptive error when a template is missing" do
      igniter = phx_test_project()

      assert_raise ArgumentError, ~r/Pulsar template missing for component :__nonexistent__/, fn ->
        igniter
        |> Pulsar.Generator.set_default_component_module()
        |> Pulsar.Generator.install_component(:__nonexistent__, [])
      end
    end

    test "tolerates trailing dot in --components-module" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [
        "--components-module",
        "MyApp.CustomComponents."
      ])
      |> assert_creates("lib/my_app/custom_components/button.ex")
      |> apply_igniter!()
    end

    test "handles deeply nested --components-module" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [
        "--components-module",
        "MyApp.Web.Live.Components.Generated"
      ])
      |> assert_creates("lib/my_app/web/live/components/generated/button.ex")
      |> apply_igniter!()
    end

    test "rejects empty --components-module" do
      assert_raise ArgumentError, ~r/non-empty module name/, fn ->
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", ["--components-module", ""])
        |> apply_igniter!()
      end
    end

    test "rejects invalid module name in --components-module" do
      assert_raise ArgumentError, ~r/invalid module name/, fn ->
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [
          "--components-module",
          "123_not_a_module"
        ])
        |> apply_igniter!()
      end
    end
  end
end
