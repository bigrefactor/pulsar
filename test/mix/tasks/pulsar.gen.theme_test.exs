defmodule Mix.Tasks.Pulsar.Gen.ThemeTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.theme" do
    test "creates theme.css with theme definitions" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/theme.css")
      |> apply_igniter!()
    end

    test "backs up existing app.css to app.css.bak" do
      igniter =
        test_project()
        |> Igniter.create_new_file(
          "assets/css/app.css",
          """
          /* Original app.css content */
          @import "tailwindcss";
          """
        )

      igniter
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/app.css.bak")
      |> apply_igniter!()
    end

    test "creates new app.css with theme import" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/app.css")
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

      test_project()
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

      test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/app.css", expected_app)
      |> apply_igniter!()
    end

    test "is idempotent - running twice doesn't change theme.css" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.gen.theme", [])
        |> apply_igniter!()

      # Run task again - theme.css should be unchanged
      igniter
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_unchanged("assets/css/theme.css")
    end

    test "is idempotent - running twice doesn't change app.css" do
      igniter =
        test_project()
        |> Igniter.compose_task("pulsar.gen.theme", [])
        |> apply_igniter!()

      # Run task again - app.css should be unchanged
      igniter
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_unchanged("assets/css/app.css")
    end

    test "handles missing assets/css directory" do
      test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/theme.css")
      |> assert_creates("assets/css/app.css")
      |> apply_igniter!()
    end

    test "preserves original app.css when backing up" do
      original_content = """
      /* My custom CSS */
      @import "tailwindcss";

      .my-custom-class {
        color: red;
      }
      """

      test_project()
      |> Igniter.create_new_file("assets/css/app.css", original_content)
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/app.css.bak", original_content)
      |> apply_igniter!()
    end
  end
end
