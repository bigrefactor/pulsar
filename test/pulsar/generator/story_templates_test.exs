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
  @form_control_story_templates ~w(
    checkbox.story.exs.eex
    input.story.exs.eex
    input_otp.story.exs.eex
    radio_group.story.exs.eex
    select.story.exs.eex
    switch.story.exs.eex
    textarea.story.exs.eex
  )

  describe "generated story templates" do
    test "every story template compiles and form controls have distinct DOM identities" do
      templates = story_templates()

      assert length(templates) > 40,
             "expected the storybook templates to be discovered, found #{length(templates)}"

      {compiled_stories, compilation_failures} =
        for template <- templates, reduce: {[], []} do
          {compiled_stories, failures} ->
            try do
              {template, story_module} = compile_story_template(template)
              {[{template, story_module} | compiled_stories], failures}
            rescue
              error -> {compiled_stories, [{template, Exception.message(error)} | failures]}
            end
        end

      on_exit(fn ->
        Enum.each(compiled_stories, fn {_template, story_module} ->
          :code.purge(story_module)
          :code.delete(story_module)
        end)
      end)

      assert compilation_failures == [],
             "story templates failed to compile:\n" <>
               Enum.map_join(compilation_failures, "\n\n", fn {template, message} ->
                 "#{template}:\n#{message}"
               end)

      identity_failures =
        compiled_stories
        |> Enum.filter(fn {template, _story_module} -> form_control_story?(template) end)
        |> Enum.flat_map(&identity_failures/1)

      assert identity_failures == [],
             "form-control story variations must have distinct DOM identities:\n" <>
               Enum.join(identity_failures, "\n")
    end
  end

  defp compile_story_template(template) do
    source = EEx.eval_file(template, assigns: @assigns, engine: EEx.SmartEngine)
    [{story_module, _bin}] = Code.compile_string(source, template)
    {template, story_module}
  end

  defp identity_failures({template, story_module}) do
    variation_identities =
      Enum.map(story_module.variations(), fn variation ->
        identity = variation.attributes[:id] || id_from_name(variation.attributes[:name])
        {variation.id, identity}
      end)

    assert length(variation_identities) >= 2,
           "expected at least two form-control identities in #{template}, found #{length(variation_identities)}"

    variation_identities
    |> Enum.group_by(fn {_variation_id, identity} -> identity end, fn {variation_id, _identity} -> variation_id end)
    |> Enum.filter(fn {_identity, variation_ids} -> length(variation_ids) > 1 end)
    |> Enum.map(fn {identity, variation_ids} ->
      "#{template}: #{inspect(identity)} is used by variations #{Enum.map_join(variation_ids, ", ", &inspect/1)}"
    end)
  end

  defp form_control_story?(template) do
    basename = Path.basename(template)

    # Avatar's :name is display content rather than a form-control identity.
    basename != "avatar.story.exs.eex" and basename in @form_control_story_templates
  end

  defp id_from_name(name) do
    name
    |> String.trim_trailing("]")
    |> String.replace(~r/\W+/u, "_")
  end

  defp story_templates do
    :pulsar
    |> :code.priv_dir()
    |> Path.join("templates/storybook/**/*.story.exs.eex")
    |> Path.wildcard()
  end
end
