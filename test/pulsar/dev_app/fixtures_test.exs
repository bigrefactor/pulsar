defmodule Pulsar.DevApp.FixturesTest do
  @moduledoc """
  Smoke test for the in-repo fixture app: every fixture LiveView must mount
  cleanly with no logger output above :warning level.

  This is the acceptance criterion that each fixture LiveView renders
  without warnings, and the safety net for the browser-audit Tier E work.
  """

  # async: false so capture_log doesn't pick up warnings from concurrent
  # component tests that intentionally trigger Logger.warning/1.
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Pulsar.DevApp.Endpoint

  @endpoint Endpoint

  @paths [
    "/",
    "/components/badge",
    "/components/button",
    "/components/card",
    "/components/checkbox",
    "/components/divider",
    "/components/field",
    "/components/flash",
    "/components/flash_group",
    "/components/form",
    "/components/header",
    "/components/icon",
    "/components/input",
    "/components/label",
    "/components/link",
    "/components/list",
    "/components/radio_group",
    "/components/select",
    "/components/switch",
    "/components/table",
    "/components/textarea"
  ]

  for path <- @paths do
    test "mounts #{path} without warnings" do
      path = unquote(path)

      logs =
        capture_log(fn ->
          {:ok, view, html} = live(build_conn(), path)
          assert html =~ "data-fixture"
          assert render(view) =~ "data-fixture"
        end)

      refute logs =~ "[error]", "expected no errors mounting #{path}, got: #{logs}"
      refute logs =~ "[warning]", "expected no warnings mounting #{path}, got: #{logs}"
    end
  end
end
