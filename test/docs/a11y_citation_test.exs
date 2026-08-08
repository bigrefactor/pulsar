defmodule Pulsar.Docs.A11yCitationTest do
  # Enforces the docs/a11y citation convention (see docs/a11y/README.md):
  # evidence cites durable anchors (file + function, or exact test name),
  # never line numbers.
  use ExUnit.Case, async: true

  @docs "docs/a11y/*.md" |> Path.wildcard() |> Enum.sort()

  @line_citation ~r/\.(?:exs?|eex|heex|js|mjs|ts|css):\d/
  @cited_file ~r{`([\w./-]*\w\.exs?)`}
  @fun_anchor ~r{`([a-z_][a-zA-Z0-9_?!]*)/(\d+)`}
  @test_anchor ~r/test "([^"]+)"/
  @test_anchor_bt ~r/[Tt]est `([^`]+)`/

  @def_kinds [:def, :defp, :defmacro, :defmacrop, :defguard, :defguardp]

  setup_all do
    docs = Map.new(@docs, &{&1, File.read!(&1)})

    source_paths =
      for {_doc, content} <- docs,
          file <- cited_files(content),
          path = resolve(file),
          path != nil,
          uniq: true,
          do: path

    sources = Map.new(source_paths, &{&1, File.read!(&1)})

    defs =
      for {path, content} <- sources, not String.ends_with?(path, ".exs"), into: %{} do
        {path, definitions(path, content)}
      end

    %{docs: docs, sources: sources, defs: defs}
  end

  test "a11y docs are present" do
    assert length(@docs) > 40
  end

  test "no line-number citations", %{docs: docs} do
    offenders =
      for {doc, content} <- docs, Regex.match?(@line_citation, content), do: doc

    assert offenders == [],
           "line-number citations (file.ex:123) found in:\n#{Enum.join(offenders, "\n")}"
  end

  test "cited files exist", %{docs: docs} do
    missing =
      for {doc, content} <- docs,
          file <- cited_files(content),
          resolve(file) == nil,
          do: "#{doc}: #{file}"

    assert missing == [],
           "citations to missing files:\n#{missing |> Enum.uniq() |> Enum.join("\n")}"
  end

  test "function anchors resolve to definitions", %{docs: docs, defs: defs} do
    bad =
      for {doc, content} <- docs,
          paragraph <- paragraphs(content),
          sources = paragraph_sources(paragraph, content),
          {name, arity, anchor} <- fun_anchors(paragraph),
          not Enum.any?(sources, &defines?(Map.get(defs, &1, MapSet.new()), name, arity)),
          do: "#{doc}: #{anchor} (searched #{inspect(sources)})"

    assert bad == [],
           "unresolvable function anchors:\n#{bad |> Enum.uniq() |> Enum.join("\n")}"
  end

  test "test-name anchors resolve", %{docs: docs, sources: sources} do
    bad =
      for {doc, content} <- docs,
          paragraph <- paragraphs(content),
          test_files = paragraph_test_files(paragraph, content),
          name <- test_names(paragraph),
          needle = test_needle(name),
          not Enum.any?(test_files, &Regex.match?(needle, Map.get(sources, &1, ""))),
          do: "#{doc}: test \"#{name}\" (searched #{inspect(test_files)})"

    assert bad == [],
           "unresolvable test citations:\n#{bad |> Enum.uniq() |> Enum.join("\n")}"
  end

  defp paragraphs(content), do: String.split(content, ~r/\n\s*\n/)

  defp cited_files(text) do
    @cited_file |> Regex.scan(text) |> Enum.map(fn [_, file] -> file end)
  end

  # Anchors markdown-linked to another audit page (e.g. [`modal/1`](modal.md))
  # cite that page, not this page's sources, so they are skipped here.
  defp fun_anchors(paragraph) do
    paragraph = String.replace(paragraph, ~r/\[[^\]]*\]\([^)]*\.md\)/, "")

    @fun_anchor
    |> Regex.scan(paragraph)
    |> Enum.map(fn [anchor, name, arity] -> {name, String.to_integer(arity), anchor} end)
  end

  defp test_names(paragraph) do
    quoted = @test_anchor |> Regex.scan(paragraph) |> Enum.map(fn [_, name] -> name end)

    backticked =
      @test_anchor_bt
      |> Regex.scan(paragraph)
      |> Enum.map(fn [_, name] -> name end)
      |> Enum.reject(&(&1 =~ ~r{^[\w.?!]+/\d+$} or &1 =~ ~r/^<.*>$/))

    Enum.map(quoted ++ backticked, &String.replace(&1, ~r/\s+/, " "))
  end

  # Test names in docs may be wrapped at the markdown line width, and names
  # containing double quotes are defined with escaped quotes in the test file;
  # match with whitespace-insensitive gaps and optional backslashes.
  defp test_needle(name) do
    pattern =
      name
      |> String.split(" ")
      |> Enum.map_join("\\s+", &Regex.escape/1)
      |> String.replace(~s("), ~s{(?:\\\\)?"})

    ~r/test\s+"#{pattern}"/
  end

  defp resolve(file) do
    candidates =
      if String.contains?(file, "/") do
        [file]
      else
        ["lib/pulsar/components/#{file}", "test/pulsar/components/#{file}"]
      end

    Enum.find(candidates, &File.exists?/1)
  end

  # Files searched for a paragraph's function anchors: source files cited in
  # the paragraph itself plus the page's **Source:** / **Tests:** headers.
  defp paragraph_sources(paragraph, content) do
    local =
      paragraph
      |> cited_files()
      |> Enum.reject(&String.ends_with?(&1, ".exs"))
      |> Enum.map(&resolve/1)
      |> Enum.reject(&is_nil/1)

    Enum.uniq(local ++ header_files(content, ".ex"))
  end

  defp paragraph_test_files(paragraph, content) do
    local =
      paragraph
      |> cited_files()
      |> Enum.filter(&String.ends_with?(&1, "_test.exs"))
      |> Enum.map(&resolve/1)
      |> Enum.reject(&is_nil/1)

    Enum.uniq(local ++ header_files(content, "_test.exs"))
  end

  defp header_files(content, suffix) do
    content
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, ["**Source:**", "**Tests:**"]))
    |> Enum.join("\n")
    |> cited_files()
    |> Enum.filter(&String.ends_with?(&1, suffix))
    |> Enum.map(&resolve/1)
    |> Enum.reject(&is_nil/1)
  end

  # All {name, arity} pairs defined in a source file (def/defp/defmacro/
  # defguard variants, expanding default arguments to every reachable arity),
  # plus bare attr/slot names.
  defp definitions(path, source) do
    case Code.string_to_quoted(source) do
      {:ok, ast} ->
        {_, defs} =
          Macro.prewalk(ast, MapSet.new(), fn
            {kind, _, [head | _]} = node, acc when kind in @def_kinds ->
              {node, add_head(acc, head)}

            {kind, _, [name | _]} = node, acc when kind in [:attr, :slot] and is_atom(name) ->
              {node, MapSet.put(acc, name)}

            node, acc ->
              {node, acc}
          end)

        defs

      {:error, reason} ->
        flunk("could not parse #{path}: #{inspect(reason)}")
    end
  end

  defp add_head(acc, {:when, _, [head | _]}), do: add_head(acc, head)

  defp add_head(acc, {name, _, args}) when is_atom(name) do
    args = if is_list(args), do: args, else: []
    arity = length(args)
    optional = Enum.count(args, &match?({:\\, _, _}, &1))

    Enum.reduce((arity - optional)..arity, acc, &MapSet.put(&2, {name, &1}))
  end

  defp add_head(acc, _), do: acc

  defp defines?(defs, name, arity) do
    name = String.to_existing_atom(name)
    MapSet.member?(defs, {name, arity}) or MapSet.member?(defs, name)
  rescue
    ArgumentError -> false
  end
end
