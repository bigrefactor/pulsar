defmodule Pulsar.TemplateSyncTest do
  use ExUnit.Case, async: true

  alias Pulsar.TemplateSync

  describe "pairs/0" do
    test "every pair has a template and a target lib path" do
      for {component, lib_path, _ns, module_name} <- TemplateSync.pairs() do
        template = Path.join([:code.priv_dir(:pulsar), "templates", "#{component}.ex.eex"])

        assert File.exists?(template), "missing template for :#{component} at #{template}"
        assert String.starts_with?(lib_path, "lib/pulsar/")
        assert String.starts_with?(module_name, "Pulsar")
      end
    end
  end

  describe "expected/1" do
    test "produces module-wrapped, parseable source" do
      badge = Enum.find(TemplateSync.pairs(), &(elem(&1, 0) == :badge))
      expected = TemplateSync.expected(badge)

      assert expected =~ "defmodule Pulsar.Components.Badge do"
      assert {:ok, _} = Code.string_to_quoted(expected)
    end

    test "distinguishes meaningfully different templates" do
      pairs = TemplateSync.pairs()
      button = Enum.find(pairs, &(elem(&1, 0) == :button))
      input = Enum.find(pairs, &(elem(&1, 0) == :input))

      refute TemplateSync.expected(button) == TemplateSync.expected(input),
             "expected/1 collapsed two distinct templates — drift detection is no longer load-bearing"
    end
  end

  describe "diff/0" do
    test "committed lib files are in sync with their templates" do
      drifted =
        TemplateSync.diff()
        |> Enum.map(fn {{_c, lib_path, _ns, _m}, _expected} -> lib_path end)

      assert drifted == [],
             "Run `mix pulsar.sync` — these lib files have drifted from their templates: " <>
               Enum.join(drifted, ", ")
    end
  end
end
