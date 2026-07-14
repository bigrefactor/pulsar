defmodule Mix.Tasks.Pulsar.Gen.ThemeTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.theme" do
    test "creates theme.css with theme definitions" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_creates("assets/css/theme.css")
      |> apply_igniter!()
    end

    test "changes app.css to carry the theme import" do
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

    test "adds the theme import to the Phoenix app.css without dropping its defaults" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.theme", [])
        |> assert_changed("assets/css/app.css")

      content = source_content(igniter, "assets/css/app.css")

      assert content =~ ~s(@import "./theme.css";)
      assert content =~ ~s|@import "tailwindcss" source(none);|
      assert content =~ ~s(@source "../js";)
      assert content =~ ~s(@plugin "../vendor/heroicons";)

      apply_igniter!(igniter)
    end

    test "re-running the task writes nothing" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> apply_igniter!()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_unchanged()
    end

    test "creates no backup files" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("pulsar.gen.theme", [])
        |> apply_igniter!()
        |> Igniter.compose_task("pulsar.gen.theme", [])

      refute Enum.any?(igniter.rewrite.sources, fn {path, _} -> path =~ ".bak" end)
    end

    test "preserves an existing app.css and ensures the theme import" do
      igniter =
        """
        @import "tailwindcss" source(none);
        @source "../css";

        @plugin "../vendor/heroicons";

        .my-custom-class {
          color: red;
        }
        """
        |> project_with_app_css()
        |> Igniter.compose_task("pulsar.gen.theme", [])

      content = source_content(igniter, "assets/css/app.css")

      assert content =~ ~s(@import "./theme.css";)
      assert content =~ ".my-custom-class"
      assert content =~ ~s(@plugin "../vendor/heroicons";)

      apply_igniter!(igniter)
    end

    test "does not duplicate the theme import in an app.css that already has it" do
      """
      @import "tailwindcss" source(none);
      @source "../css";
      @import "./theme.css";
      """
      |> project_with_app_css()
      |> Igniter.compose_task("pulsar.gen.theme", [])
      |> assert_unchanged("assets/css/app.css")
      |> apply_igniter!()
    end

    test "inserts a real import when the only occurrence is commented out" do
      igniter =
        """
        @import "tailwindcss" source(none);
        /* @import "./theme.css"; -- disabled for now */
        """
        |> project_with_app_css()
        |> Igniter.compose_task("pulsar.gen.theme", [])

      content = source_content(igniter, "assets/css/app.css")

      assert has_import_line?(content, ~s(@import "./theme.css";)),
             "expected a real, uncommented `@import \"./theme.css\";` line, got:\n\n#{content}"

      apply_igniter!(igniter)
    end

    test "overwrites a customized themes/dark.css" do
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

      content = source_content(igniter, "assets/css/themes/dark.css")

      refute content =~ "hotpink"
      assert content =~ ~s([data-theme="dark"])

      apply_igniter!(igniter)
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

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/theme.css")
      content = Rewrite.Source.get(source, :content)
      assert content =~ ~s(@import "./themes/light.css";)
      assert content =~ ~s(@import "./themes/dark.css";)

      apply_igniter!(igniter)
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

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/themes/cupcake.css")
      content = Rewrite.Source.get(source, :content)
      assert content =~ ~s([data-theme="cupcake"])

      apply_igniter!(igniter)
    end

    test "appends @import to theme.css" do
      igniter =
        phx_test_project(
          files: %{
            "assets/css/theme.css" => existing_theme_css()
          }
        )
        |> Igniter.compose_task("pulsar.gen.theme", ["cupcake"])

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/theme.css")
      content = Rewrite.Source.get(source, :content)
      assert content =~ ~s(@import "./themes/cupcake.css";)

      apply_igniter!(igniter)
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

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/theme.css")
      content = Rewrite.Source.get(source, :content)
      occurrences = content |> String.split(~s(@import "./themes/cupcake.css";)) |> length()
      # Splitting on N matches yields N+1 chunks; 1 match -> 2 chunks.
      assert occurrences == 2, "expected exactly one @import; got #{occurrences - 1}"

      apply_igniter!(igniter)
    end

    test "inserts a real import when the only occurrence is commented out" do
      seed_content = existing_theme_css() <> ~s(\n/* @import "./themes/cupcake.css"; -- disabled */\n)

      igniter =
        phx_test_project(files: %{"assets/css/theme.css" => seed_content})
        |> Igniter.compose_task("pulsar.gen.theme", ["cupcake"])

      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/theme.css")
      content = Rewrite.Source.get(source, :content)

      assert has_import_line?(content, ~s(@import "./themes/cupcake.css";)),
             "expected a real, uncommented `@import \"./themes/cupcake.css\";` line, got:\n\n#{content}"

      apply_igniter!(igniter)
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

      # The task leaves the existing file untouched, so it is not in the
      # rewrite; load it to confirm its content is unchanged.
      refute Igniter.changed?(igniter, "assets/css/themes/cupcake.css")

      igniter = Igniter.include_existing_file(igniter, "assets/css/themes/cupcake.css")
      {:ok, source} = Map.fetch(igniter.rewrite.sources, "assets/css/themes/cupcake.css")
      content = Rewrite.Source.get(source, :content)
      assert content == original

      apply_igniter!(igniter)
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

  defp source_content(igniter, path) do
    {:ok, source} = Map.fetch(igniter.rewrite.sources, path)
    Rewrite.Source.get(source, :content)
  end

  defp has_import_line?(content, import_line) do
    content
    |> String.split("\n")
    |> Enum.any?(&(String.trim(&1) == import_line))
  end

  # phx_test_project/1 discards a `files:` seed for assets/css/app.css: it runs
  # the Phoenix installer, which writes its own app.css over the seed. Write the
  # customized file after the project exists instead.
  defp project_with_app_css(css) do
    phx_test_project()
    |> Igniter.create_new_file("assets/css/app.css", css, on_exists: :overwrite)
    |> apply_igniter!()
  end
end
