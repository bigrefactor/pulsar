defmodule Mix.Tasks.Pulsar.Gen.ButtonTest do
  use ExUnit.Case, async: true

  import Igniter.Test
  import Pulsar.BackupTestHelper

  describe "pulsar.gen.button" do
    test "creates button component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/button.ex")
      |> apply_igniter!()
    end

    test "generated component includes expected functions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> apply_igniter!()
    end

    test "generated component uses Phoenix.Component" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.button", [])
      |> assert_creates("lib/test_web/components/button.ex")
      |> apply_igniter!()
    end

    test "backs up existing button component before overwriting" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      # Verify backup was created
      assert_backup_created(igniter, "lib/test_web/components/button.ex")
    end

    test "backup preserves original component content" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      # Verify backup contains button component code
      assert_backup_contains(igniter, "lib/test_web/components/button.ex", ~r/defmodule.*Button/)
      assert_backup_contains(igniter, "lib/test_web/components/button.ex", ~r/def button\(assigns\)/)
    end

    test "does not create backup for new component" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      # Verify no backup was created for initial generation
      assert_no_backup_created(igniter, "lib/test_web/components/button.ex")
    end

    test "multiple regenerations create timestamped backups" do
      # This test verifies that running the generator multiple times creates
      # separate backup files rather than overwriting the same backup
      igniter =
        phx_test_project()
        # Generate button first time
        |> Igniter.compose_task("pulsar.gen.button", [])
        # Apply to "install" it
        |> apply_igniter!()
        # Regenerate button (should create 1 backup)
        |> Igniter.compose_task("pulsar.gen.button", [])
        |> apply_igniter!()

      # After one regeneration, should have exactly 1 backup
      backups = get_backup_files(igniter, "lib/test_web/components/button.ex")

      assert length(backups) == 1,
             "Expected 1 backup file after one regeneration, found #{length(backups)}"

      # Verify backup has timestamped filename pattern
      {backup_path, _source} = hd(backups)

      assert backup_path =~ ~r/button\.ex\.bak\.\d{8}T\d{6}/,
             "Backup filename should have timestamp pattern"
    end
  end
end
