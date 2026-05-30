defmodule Mix.Tasks.Pulsar.Docs.CoverageTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Pulsar.Docs.Coverage

  describe "audit/0 (the live :pulsar lib surface)" do
    test "reports zero undocumented public functions" do
      assert {total, []} = Coverage.audit()
      assert total > 0
    end
  end

  describe "audit/1 (classification)" do
    test "flags only bare public functions, not documented/@doc false/callbacks" do
      assert {total, missing} = Coverage.audit([Pulsar.DocCoverageFixture])

      assert missing == [{Pulsar.DocCoverageFixture, :bare, 0}]
      # documented + hidden + bare + run/1 callback are all counted in the total.
      assert total >= 4
    end
  end
end
