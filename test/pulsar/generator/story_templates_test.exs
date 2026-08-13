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
  @identity_candidate_story_templates MapSet.new(~w(
    avatar.story.exs.eex
    checkbox.story.exs.eex
    date_picker.story.exs.eex
    dropzone.story.exs.eex
    field.story.exs.eex
    input.story.exs.eex
    input_otp.story.exs.eex
    radio_group.story.exs.eex
    select.story.exs.eex
    switch.story.exs.eex
    textarea.story.exs.eex
  ))
  @identity_exclusions %{
    "avatar.story.exs.eex" => "its :name is display content rather than a form-control identity"
  }
  @normalized_name_identity_story_templates MapSet.new(~w(
    checkbox.story.exs.eex
    input.story.exs.eex
    radio_group.story.exs.eex
    switch.story.exs.eex
    textarea.story.exs.eex
  ))

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
        |> form_control_stories()
        |> Enum.flat_map(&identity_failures/1)

      assert identity_failures == [],
             "form-control story variations must have distinct DOM identities:\n" <>
               Enum.join(identity_failures, "\n")
    end

    test "the Field story guard catches duplicate injected form-field identities" do
      template = Enum.find(story_templates(), &(Path.basename(&1) == "field.story.exs.eex"))
      {^template, story_module} = compile_story_template(template)

      on_exit(fn ->
        :code.purge(story_module)
        :code.delete(story_module)
      end)

      [first, second | remaining] = story_module.variations()

      collided_variations =
        [
          %{first | attributes: Map.delete(first.attributes, :id)},
          %{second | attributes: Map.delete(second.attributes, :id)}
          | remaining
        ]

      assert [failure] = identity_failures(template, collided_variations)
      assert failure =~ "#{template}: \"demo_demo\" is used by variations"
      assert failure =~ inspect(first.id)
      assert failure =~ inspect(second.id)
    end

    test "the Themes story scaffold excerpt matches generator output except for its abbreviated TODO" do
      expected =
        :pulsar
        |> :code.priv_dir()
        |> Path.join("templates/themes/scaffold.css.eex")
        |> EEx.eval_file(assigns: [theme_name: "purple", color_scheme: "light"])
        |> normalize_scaffold_excerpt()

      actual =
        theme_story_scaffold_output()
        |> normalize_scaffold_excerpt()

      assert actual == expected
    end
  end

  defp theme_story_scaffold_output do
    template = Enum.find(story_templates(), &(Path.basename(&1) == "themes.story.exs.eex"))
    source = EEx.eval_file(template, assigns: @assigns, engine: EEx.SmartEngine)
    {:ok, ast} = Code.string_to_quoted(source)
    {_ast, scaffold_output} = Macro.prewalk(ast, nil, &find_scaffold_output/2)

    scaffold_output
  end

  defp find_scaffold_output({:@, _, [{:scaffold_output, _, [scaffold_output]}]} = node, _acc)
       when is_binary(scaffold_output), do: {node, scaffold_output}

  defp find_scaffold_output(node, acc), do: {node, acc}

  defp normalize_scaffold_excerpt(output) do
    ~r/\/\* TODO: override semantic tokens for this theme\..*?\*\//s
    |> Regex.replace(
      output,
      "/* TODO: override semantic tokens for this theme. */"
    )
    |> String.split()
    |> Enum.join(" ")
  end

  defp compile_story_template(template) do
    source = EEx.eval_file(template, assigns: @assigns, engine: EEx.SmartEngine)
    [{story_module, _bin}] = Code.compile_string(source, template)
    {template, story_module}
  end

  defp identity_failures({template, story_module}), do: identity_failures(template, story_module.variations())

  defp identity_failures(template, variations) do
    {variation_identities, identity_failures} =
      Enum.reduce(variations, {[], []}, fn variation, {identities, failures} ->
        case identity_for(template, variation.attributes) do
          {:ok, identity} -> {[{variation.id, identity} | identities], failures}
          {:error, reason} -> {identities, ["#{template}: variation #{inspect(variation.id)} #{reason}" | failures]}
        end
      end)

    assert length(variation_identities) >= 2,
           "expected at least two form-control identities in #{template}, found #{length(variation_identities)}"

    duplicate_failures =
      variation_identities
      |> Enum.group_by(fn {_variation_id, identity} -> identity end, fn {variation_id, _identity} -> variation_id end)
      |> Enum.filter(fn {_identity, variation_ids} -> length(variation_ids) > 1 end)
      |> Enum.map(fn {identity, variation_ids} ->
        "#{template}: #{inspect(identity)} is used by variations #{Enum.map_join(variation_ids, ", ", &inspect/1)}"
      end)

    identity_failures ++ duplicate_failures
  end

  defp form_control_stories(compiled_stories) do
    identity_candidates =
      Enum.filter(compiled_stories, fn {template, _story_module} ->
        Path.basename(template) in @identity_candidate_story_templates
      end)

    discovered_templates =
      identity_candidates
      |> MapSet.new(fn {template, _story_module} -> Path.basename(template) end)

    assert discovered_templates == @identity_candidate_story_templates,
           "expected identity candidates #{inspect(@identity_candidate_story_templates)}, found #{inspect(discovered_templates)}"

    excluded_templates = Map.keys(@identity_exclusions) |> MapSet.new()

    assert MapSet.subset?(excluded_templates, discovered_templates),
           "expected explicitly excluded identity candidates #{inspect(excluded_templates)} to be discovered"

    Enum.reject(identity_candidates, fn {template, _story_module} ->
      Path.basename(template) in excluded_templates
    end)
  end

  defp identity_for(template, attributes) do
    basename = Path.basename(template)

    cond do
      basename == "select.story.exs.eex" ->
        explicit_identity(attributes, "requires an explicit :id because unbound Selects do not derive one from :name")

      basename == "date_picker.story.exs.eex" ->
        explicit_identity(attributes, "requires an explicit :id because this standalone story has no bound field")

      basename == "dropzone.story.exs.eex" ->
        dropzone_identity(attributes)

      basename == "field.story.exs.eex" ->
        field_identity(attributes)

      basename == "input_otp.story.exs.eex" ->
        raw_name_identity(attributes, "requires :id or :name to avoid a generated, non-deterministic identity")

      basename in @normalized_name_identity_story_templates ->
        normalized_name_identity(attributes)
    end
  end

  defp explicit_identity(attributes, missing_id_reason) do
    case attributes[:id] do
      nil -> {:error, missing_id_reason}
      id -> {:ok, id}
    end
  end

  defp dropzone_identity(%{id: id}) when not is_nil(id), do: {:ok, id}

  defp dropzone_identity(%{upload: %{name: name}}), do: {:ok, "dropzone-#{name}"}

  defp dropzone_identity(_attributes), do: {:error, "requires :id or an upload with a name"}

  # The Field story template injects `f[:demo]` from a form named `demo`.
  # Without a caller override, Field therefore renders the stable id `demo_demo`.
  defp field_identity(%{id: id}) when not is_nil(id), do: {:ok, id}
  defp field_identity(_attributes), do: {:ok, "demo_demo"}

  defp raw_name_identity(%{id: id}, _reason) when not is_nil(id), do: {:ok, id}
  defp raw_name_identity(%{name: name}, _reason) when not is_nil(name), do: {:ok, name}
  defp raw_name_identity(_attributes, reason), do: {:error, reason}

  defp normalized_name_identity(%{id: id}) when not is_nil(id), do: {:ok, id}

  defp normalized_name_identity(%{name: name}) when not is_nil(name), do: {:ok, id_from_name(name)}

  defp normalized_name_identity(_attributes), do: {:error, "requires :id or :name to derive a stable identity"}

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
