defmodule Pulsar.NoInlineStyleTest do
  use ExUnit.Case, async: true

  # Inline `style` attributes are dropped by browsers under a Content-Security-
  # Policy whose `style-src` lacks `'unsafe-inline'` — silently, with no error
  # and no fallback. A CSP nonce does not help: nonces whitelist `<style>` and
  # `<script>` elements, not style attributes. Components must express styling
  # as classes or, for dynamic values, as SVG presentation attributes. This
  # guards the generated lib modules and every template (source of truth),
  # including those under priv/templates/{storybook,test,themes} that ship into
  # host apps, plus the dev_app storybook mirror used for local development.
  #
  # The lookbehind is required: a bare `style=` also matches `line_style="..."`.
  #
  # `priv/templates/test` is excluded: those are ExUnit sources that *assert
  # about* markup rather than emit it, so their `refute html =~ ~s( style=")`
  # guards would otherwise be reported as the very thing they prevent.
  @roots ["lib/pulsar/components", "priv/templates", "test/support/dev_app/storybook"]
  @excluded_dirs ["priv/templates/test"]
  @pattern ~r/(?<![-\w])style=/

  test "no component source renders an inline style attribute" do
    offenders =
      @roots
      |> Enum.flat_map(&Path.wildcard(Path.join(&1, "**/*")))
      |> Enum.filter(&File.regular?/1)
      |> Enum.reject(fn path -> Enum.any?(@excluded_dirs, &String.starts_with?(path, &1)) end)
      |> Enum.flat_map(fn path ->
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.filter(fn {line, _no} -> Regex.match?(@pattern, line) end)
        |> Enum.map(fn {line, no} -> "#{path}:#{no}: #{String.trim(line)}" end)
      end)

    assert offenders == [],
           "Found inline style attributes:\n" <> Enum.join(offenders, "\n")
  end
end
