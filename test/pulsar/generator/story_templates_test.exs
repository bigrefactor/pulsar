defmodule Pulsar.Generator.StoryTemplatesTest do
  @moduledoc """
  Compiles every generated storybook story.

  Story files are `.exs` scripts that phoenix_storybook evaluates at runtime, so
  nothing in the build compiles them and nothing in the dev-app storybook smoke
  test does either — it reads the content tree without evaluating the sources.
  A malformed `~H` template, an unterminated `<%!-- --%>` comment, or an
  unbalanced tag therefore reaches the user's first `mix compile` after
  `mix pulsar.install --storybook`, taking their whole storybook down with it.
  """

  use ExUnit.Case, async: false

  # Rendered under a namespace no other module uses, so compiling the stories
  # cannot redefine the dev app's own storybook modules.
  @assigns [web_module: "PulsarStoryTemplateTest", components_module: "Pulsar.Components"]

  describe "generated story templates" do
    test "every story template compiles once rendered" do
      templates = story_templates()

      assert length(templates) > 40,
             "expected the storybook templates to be discovered, found #{length(templates)}"

      failures =
        for template <- templates, reduce: [] do
          acc ->
            source = EEx.eval_file(template, assigns: @assigns, engine: EEx.SmartEngine)

            try do
              source
              |> Code.compile_string(template)
              |> Enum.each(fn {module, _bin} ->
                :code.purge(module)
                :code.delete(module)
              end)

              acc
            rescue
              error -> [{template, Exception.message(error)} | acc]
            end
        end

      assert failures == [],
             "story templates failed to compile:\n" <>
               Enum.map_join(failures, "\n\n", fn {template, message} ->
                 "#{template}:\n#{message}"
               end)
    end
  end

  defp story_templates do
    :pulsar
    |> :code.priv_dir()
    |> Path.join("templates/storybook/**/*.story.exs.eex")
    |> Path.wildcard()
  end
end
