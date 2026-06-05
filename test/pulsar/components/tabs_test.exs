defmodule Pulsar.Components.TabsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Tabs

  describe "tabs/1 structure & ARIA" do
    test "renders tablist, tabs and panels with roles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" aria_label="Sections">
          <:tab id="one" label="One">Panel one</:tab>
          <:tab id="two" label="Two">Panel two</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~s(role="tablist")
      assert html =~ ~s(role="tab")
      assert html =~ ~s(role="tabpanel")
      assert html =~ ~s(aria-label="Sections")
      assert html =~ ~s(aria-orientation="horizontal")
      assert html =~ "PulsarTabs"
    end

    test "tabs reference their panels via aria-controls / aria-labelledby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t">
          <:tab id="one" label="One">Panel one</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~s(id="one")
      assert html =~ ~s(aria-controls="one-panel")
      assert html =~ ~s(id="one-panel")
      assert html =~ ~s(aria-labelledby="one")
    end

    test "first tab is selected and its panel visible; others hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t">
          <:tab id="one" label="One">Panel one</:tab>
          <:tab id="two" label="Two">Panel two</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~r/id="one"[^>]*aria-selected="true"/s or
               html =~ ~r/aria-selected="true"[^>]*id="one"/s

      assert html =~ ~r/id="one"[^>]*tabindex="0"/s or html =~ ~r/tabindex="0"[^>]*id="one"/s
      assert html =~ ~r/id="two"[^>]*tabindex="-1"/s or html =~ ~r/tabindex="-1"[^>]*id="two"/s
      assert html =~ ~r/id="two-panel"[^>]*hidden/s
    end

    test "active attr selects a non-first tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" active="two">
          <:tab id="one" label="One">Panel one</:tab>
          <:tab id="two" label="Two">Panel two</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~r/id="two"[^>]*aria-selected="true"/s
      assert html =~ ~r/id="one-panel"[^>]*hidden/s
    end

    test "vertical orientation sets aria-orientation and data-orientation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" orientation="vertical">
          <:tab id="one" label="One">Panel one</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~s(aria-orientation="vertical")
      assert html =~ ~s(data-orientation="vertical")
    end
  end

  describe "variants" do
    test "ghost (default) uses an underline indicator on the active tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t">
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "border-b-2"
      # Active styling is gated on aria-selected so the hook can move the indicator.
      assert html =~ "aria-selected:border-foreground"
      assert html =~ "aria-selected:text-foreground"
    end

    test "solid uses a filled pill on the active tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" variant="solid" color="primary">
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "bg-muted"
      assert html =~ "aria-selected:bg-primary"
      assert html =~ "aria-selected:text-primary-foreground"
    end

    test "elevated lifts the active pill with shadow-dropdown" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" variant="elevated">
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "aria-selected:shadow-dropdown"
      # elevated floats the pill on the page — no recessed muted track (that's solid).
      refute html =~ "bg-muted"
    end

    test "outline uses border-border-strong on the active tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" variant="outline">
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "aria-selected:border-border-strong"
    end
  end

  describe "colors & sizes" do
    test "color tints the active tab text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" color="success">
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "aria-selected:text-success"
    end

    test "size scales tab padding/text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" size="lg">
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "text-base"
    end
  end

  describe "per-tab color override (active state)" do
    test "a tab's own color overrides the group color on its active state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" color="neutral">
          <:tab id="one" label="One" color="danger">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "aria-selected:text-danger"
    end

    test "the override is gated to active state — never an always-on color class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" color="neutral" active="one">
          <:tab id="one" label="One">P</:tab>
          <:tab id="two" label="Two" color="danger">P</:tab>
        </Tabs.tabs>
        """)

      # The override exists, but only as an aria-selected-gated class — so it
      # applies when the tab is selected, never unconditionally.
      assert html =~ "aria-selected:text-danger"
      refute html =~ ~r/[^:]text-danger/
    end
  end

  describe "tab features" do
    test "renders an icon when given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t">
          <:tab id="one" label="One" icon="hero-user">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "hero-user"
    end

    test "disabled tab is rendered disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t">
          <:tab id="one" label="One">P</:tab>
          <:tab id="two" label="Two" disabled>P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~r/id="two"[^>]*disabled/s
      assert html =~ ~r/id="two"[^>]*aria-disabled="true"/s
    end

    test "default active skips a leading disabled tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t">
          <:tab id="one" label="One" disabled>P</:tab>
          <:tab id="two" label="Two">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~r/id="two"[^>]*aria-selected="true"/s
    end

    test "active pointing at a disabled tab falls back to the first enabled tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" active="one">
          <:tab id="one" label="One" disabled>P</:tab>
          <:tab id="two" label="Two">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~r/id="two"[^>]*aria-selected="true"/s
    end
  end

  describe "callbacks & customization" do
    test "on_change is encoded into data-on-change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" on_change={JS.push("changed")}>
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "data-on-change="
      assert html =~ "changed"
    end

    test "user class is merged onto the root (Twm override)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" class="max-w-md">
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ "max-w-md"
    end

    test "passes through global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" data-test="x">
          <:tab id="one" label="One">P</:tab>
        </Tabs.tabs>
        """)

      assert html =~ ~s(data-test="x")
    end
  end
end
