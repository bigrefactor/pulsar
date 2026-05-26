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

    test "creates themes/light.css and themes/dark.css alongside the entry" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/themes/light.css")
      |> assert_creates("assets/css/themes/dark.css")
      |> apply_igniter!()
    end

    test "entry theme.css imports both themes" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.theme", [])
        |> apply_igniter!()

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/theme.css")
      content = Rewrite.Source.get(source, :content)
      assert content =~ ~s(@import "./themes/light.css";)
      assert content =~ ~s(@import "./themes/dark.css";)
    end

    test "backs up existing themes/dark.css before overwriting" do
      igniter =
        phx_test_project(
          files: %{
            "assets/css/themes/dark.css" => """
            [data-theme="dark"] {
              --color-primary: hotpink;
            }
            """
          }
        )
        |> Igniter.compose_task("pulsar.gen.theme", [])
        |> apply_igniter!()

      assert_backup_created(igniter, "assets/css/themes/dark.css")
      assert_backup_contains(igniter, "assets/css/themes/dark.css", ~r/hotpink/)
    end
  end

  describe "pulsar.gen.theme <name> — scaffolding" do
    test "creates themes/<name>.css from the scaffold template" do
      igniter =
        phx_test_project(
          files: %{
            "assets/css/theme.css" => existing_theme_css()
          }
        )
        |> Igniter.compose_task("pulsar.gen.theme", ["cupcake"])
        |> assert_creates("assets/css/themes/cupcake.css")
        |> apply_igniter!()

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/themes/cupcake.css")
      content = Rewrite.Source.get(source, :content)
      assert content =~ ~s([data-theme="cupcake"])
    end

    test "appends @import to theme.css" do
      igniter =
        phx_test_project(
          files: %{
            "assets/css/theme.css" => existing_theme_css()
          }
        )
        |> Igniter.compose_task("pulsar.gen.theme", ["cupcake"])
        |> apply_igniter!()

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/theme.css")
      content = Rewrite.Source.get(source, :content)
      assert content =~ ~s(@import "./themes/cupcake.css";)
    end

    test "re-running with the same name does not duplicate the @import" do
      seed_content = existing_theme_css() <> ~s(\n@import "./themes/cupcake.css";\n)

      igniter =
        phx_test_project(
          files: %{
            "assets/css/theme.css" => seed_content
          }
        )
        |> Igniter.compose_task("pulsar.gen.theme", ["cupcake"])
        |> apply_igniter!()

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/theme.css")
      content = Rewrite.Source.get(source, :content)
      occurrences = content |> String.split(~s(@import "./themes/cupcake.css";)) |> length()
      # Splitting on N matches yields N+1 chunks; 1 match -> 2 chunks.
      assert occurrences == 2, "expected exactly one @import; got #{occurrences - 1}"
    end

    test "refuses to overwrite an existing themes/<name>.css" do
      original = ~s([data-theme="cupcake"] { --color-primary: red; }\n)

      igniter =
        phx_test_project(
          files: %{
            "assets/css/theme.css" => existing_theme_css(),
            "assets/css/themes/cupcake.css" => original
          }
        )
        |> Igniter.compose_task("pulsar.gen.theme", ["cupcake"])
        |> apply_igniter!()

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/themes/cupcake.css")
      content = Rewrite.Source.get(source, :content)
      assert content == original
    end

    test "rejects invalid theme names" do
      assert_raise Mix.Error, ~r/Invalid theme name/, fn ->
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.theme", ["Bad Name!"])
        |> apply_igniter!()
      end
    end
  end

  defp existing_theme_css do
    """
    @import "tailwindcss";

    @import "./themes/light.css";
    @import "./themes/dark.css";
    """
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
