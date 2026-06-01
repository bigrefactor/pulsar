defmodule Pulsar.Theme.MotionTokensTest do
  @moduledoc """
  Guards the motion-token wiring so the "inert token" class of bug
  (custom property declared, no utility generated) can't return.
  """
  use ExUnit.Case, async: true

  @template Path.expand("../../../priv/templates/theme.css.eex", __DIR__)
  @built_css Path.expand(
               "../../support/dev_app/priv/static/assets/app.css",
               __DIR__
             )

  defp template, do: File.read!(@template)

  describe "easing tokens (Tailwind v4 --ease-* namespace)" do
    test "declares the four easing curves" do
      css = template()
      assert css =~ "--ease-standard:"
      assert css =~ "--ease-decelerate:"
      assert css =~ "--ease-accelerate:"
      assert css =~ "--ease-emphasized:"
    end

    test "drops the old non-generating --easing-* namespace" do
      refute template() =~ "--easing-"
    end

    test "the four curves are pairwise distinct (no standard==emphasized no-op)" do
      curves =
        Regex.scan(~r/--ease-[a-z]+:\s*(cubic-bezier\([^;]+\))/, template())
        |> Enum.map(fn [_, curve] -> String.replace(curve, ~r/\s+/, "") end)

      assert length(curves) == 4
      assert length(Enum.uniq(curves)) == 4, "easing curves must all differ: #{inspect(curves)}"
    end
  end

  describe "duration utilities" do
    test "declares fast/normal/slow tokens" do
      css = template()
      assert css =~ "--duration-fast:"
      assert css =~ "--duration-normal:"
      assert css =~ "--duration-slow:"
    end

    test "exposes named duration utilities via @utility" do
      css = template()
      assert css =~ "@utility duration-fast"
      assert css =~ "@utility duration-normal"
      assert css =~ "@utility duration-slow"
    end
  end

  describe "reduced motion" do
    test "has a single global prefers-reduced-motion rule targeting all elements" do
      css = template()
      assert css =~ "@media (prefers-reduced-motion: reduce)"
      assert css =~ ~r/\*,\s*\*::before,\s*\*::after/
      assert css =~ "transition-duration: 0.01ms"
    end
  end

  describe "built CSS (only when assets have been built)" do
    @describetag :built_css

    test "ease-* and duration-* utilities actually emit rules" do
      if File.exists?(@built_css) do
        css = File.read!(@built_css)
        assert css =~ "transition-timing-function:var(--ease-standard)" or
                 css =~ "cubic-bezier(0.2,0,0,1)",
               "ease-standard utility not found in built CSS"
        assert css =~ "var(--duration-fast)", "duration-fast utility not found in built CSS"
      else
        IO.puts(:stderr, "skip: build assets (mix assets.build) to verify generated CSS")
      end
    end
  end
end
