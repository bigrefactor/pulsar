defmodule Pulsar.Docs.A11yCitationTest do
  # Enforces the docs/a11y citation convention (see docs/a11y/README.md):
  # evidence cites durable anchors (file + function, or exact test name),
  # never line numbers.
  use ExUnit.Case, async: true

  @docs "docs/a11y/*.md" |> Path.wildcard() |> Enum.sort()

  @line_citation ~r/\.exs?:\d/
  @cited_file ~r{`([\w./-]*\w\.exs?)`}
  @fun_anchor ~r{`([a-z_][a-zA-Z0-9_?!]*)/\d+`}
  @test_anchor ~r/test "([^"]+)"/
  @test_anchor_bt ~r/Test `([^`]+)`/

  test "a11y docs are present" do
    assert length(@docs) > 40
  end

  test "no line-number citations" do
    offenders =
      for doc <- @docs, Regex.match?(@line_citation, File.read!(doc)), do: doc

    assert offenders == [],
           "line-number citations (file.ex:123) found in:\n#{Enum.join(offenders, "\n")}"
  end

  test "cited files exist" do
    missing =
      for doc <- @docs,
          file <- cited_files(File.read!(doc)),
          resolve(file) == nil,
          do: "#{doc}: #{file}"

    assert missing == [],
           "citations to missing files:\n#{missing |> Enum.uniq() |> Enum.join("\n")}"
  end

  test "function anchors resolve to definitions" do
    bad =
      for doc <- @docs,
          content = File.read!(doc),
          block <- evidence_blocks(content),
          sources = block_sources(block, content),
          {name, anchor} <- fun_anchors(block),
          not Enum.any?(sources, &defines?(&1, name)),
          do: "#{doc}: #{anchor} (searched #{inspect(sources)})"

    assert bad == [],
           "unresolvable function anchors:\n#{bad |> Enum.uniq() |> Enum.join("\n")}"
  end

  test "test-name anchors resolve" do
    bad =
      for doc <- @docs,
          content = File.read!(doc),
          block <- evidence_blocks(content),
          test_files = block_test_files(block, content),
          name <- test_names(block),
          needle = ~s(test "#{String.replace(name, ~s("), ~s(\\"))}"),
          not Enum.any?(test_files, &(File.read!(&1) =~ needle)),
          do: "#{doc}: test \"#{name}\" (searched #{inspect(test_files)})"

    assert bad == [],
           "unresolvable test citations:\n#{bad |> Enum.uniq() |> Enum.join("\n")}"
  end

  defp evidence_blocks(content) do
    content
    |> String.split(~r/\n\s*\n/)
    |> Enum.filter(&String.contains?(&1, "**Evidence:**"))
  end

  defp cited_files(text) do
    @cited_file |> Regex.scan(text) |> Enum.map(fn [_, file] -> file end)
  end

  defp fun_anchors(block) do
    @fun_anchor |> Regex.scan(block) |> Enum.map(fn [anchor, name] -> {name, anchor} end)
  end

  defp test_names(block) do
    quoted = @test_anchor |> Regex.scan(block) |> Enum.map(fn [_, name] -> name end)
    backticked = @test_anchor_bt |> Regex.scan(block) |> Enum.map(fn [_, name] -> name end)
    quoted ++ backticked
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

  # Files searched for a block's function anchors: source files cited in
  # the block itself, falling back to the page's **Source:** header.
  defp block_sources(block, content) do
    block
    |> cited_files()
    |> Enum.reject(&String.ends_with?(&1, ".exs"))
    |> Enum.map(&resolve/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> header_files(content, ".ex")
      files -> files
    end
  end

  defp block_test_files(block, content) do
    block
    |> cited_files()
    |> Enum.filter(&String.ends_with?(&1, "_test.exs"))
    |> Enum.map(&resolve/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> header_files(content, "_test.exs")
      files -> files
    end
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

  defp defines?(file, name) do
    source = File.read!(file)
    escaped = Regex.escape(name)

    Regex.match?(~r/\b(?:def|defp)\s+#{escaped}[\s(,]/, source) or
      Regex.match?(~r/\b(?:attr|slot)[\s(]+:#{escaped}\b/, source)
  end
end
