defmodule Mix.Tasks.Pulsar.Gen.ThemeTest do
  use ExUnit.Case, async: true

  import Igniter.Test
  import Pulsar.BackupTestHelper

  describe "pulsar.gen.theme" do
    test "creates theme.css with theme definitions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/theme.css")
      |> apply_igniter!()
    end

    test "backs up existing app.css to timestamped backup file" do
      igniter =
        phx_test_project(
          files: %{
            "assets/css/app.css" => """
            /* Original app.css content */
            @import "tailwindcss";
            """
          }
        )
        |> Igniter.compose_task("pulsar.gen.theme", [])
        |> apply_igniter!()

      # Verify a timestamped backup file was created
      assert_backup_created(igniter, "assets/css/app.css")
    end

    test "creates new app.css with theme import" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_changed("assets/css/app.css")
      |> apply_igniter!()
    end

    test "theme.css contains semantic color definitions" do
      # Read the actual template to verify expected content
      expected_theme =
        :pulsar
        |> :code.priv_dir()
        |> Path.join("templates")
        |> Path.join("theme.css.eex")
        |> File.read!()

      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/theme.css", expected_theme)
      |> apply_igniter!()
    end

    test "new app.css imports theme.css" do
      # Read the actual app.css template
      expected_app =
        :pulsar
        |> :code.priv_dir()
        |> Path.join("templates")
        |> Path.join("app.css.eex")
        |> File.read!()
        |> String.replace("<%= @web_directory %>", "test_web")

      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_changed("assets/css/app.css")
      |> assert_content_equals("assets/css/app.css", expected_app)
      |> apply_igniter!()
    end

    test "preserves original app.css content when backing up" do
      igniter =
        phx_test_project(
          files: %{
            "assets/css/app.css" => """
            /* My custom CSS */
            @import "tailwindcss";

            .my-custom-class {
              color: red;
            }
            """
          }
        )
        |> Igniter.compose_task("pulsar.gen.theme", [])
        |> apply_igniter!()

      # Verify the backup contains the original app.css import
      assert_backup_contains(igniter, "assets/css/app.css", ~r/@import "tailwindcss"/)
    end
  end

  defp assert_changed(igniter, path_or_paths) do
    for path <- List.wrap(path_or_paths) do
      assert Igniter.changed?(igniter, path), """
      Expected #{inspect(path)} to be changed, but it was unchanged.
      """
    end

    igniter
  end
end
