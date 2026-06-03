defmodule Pulsar.Components.MenuTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Menu

  describe "menu/1 landmark and structure" do
    test "renders a nav landmark wrapping a list by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu id="m" label="Primary">
          <Menu.menu_item navigate="/">Home</Menu.menu_item>
        </Menu.menu>
        """)

      assert html =~ "<nav"
      assert html =~ ~s(aria-label="Primary")
      assert html =~ "<ul"
      assert html =~ ~s(role="list")
      assert html =~ "Home"
    end

    test "landmark=false renders the list without a nav landmark" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu id="m" label="Primary" landmark={false}>
          <Menu.menu_item navigate="/">Home</Menu.menu_item>
        </Menu.menu>
        """)

      refute html =~ "<nav"
      assert html =~ "<ul"
      # the accessible name moves onto the list itself
      assert html =~ ~s(aria-label="Primary")
    end

    test "auto-generates an id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu>
          <Menu.menu_item navigate="/">Home</Menu.menu_item>
        </Menu.menu>
        """)

      assert html =~ ~s(id="menu-)
    end

    test "passes through global/data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu id="m" data-fixture-cell="x">
          <Menu.menu_item navigate="/">Home</Menu.menu_item>
        </Menu.menu>
        """)

      assert html =~ ~s(data-fixture-cell="x")
    end
  end

  describe "menu/1 orientation contract" do
    test "defaults to a vertical orientation contract" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu id="m">
          <Menu.menu_item navigate="/">Home</Menu.menu_item>
        </Menu.menu>
        """)

      assert html =~ ~s(data-orientation="vertical")
      # publishes a named group marker for descendants to key off
      assert html =~ "group/menu"
      assert html =~ "flex-col"
    end

    test "horizontal orientation flips the layout direction" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu id="m" orientation="horizontal">
          <Menu.menu_item navigate="/">Home</Menu.menu_item>
        </Menu.menu>
        """)

      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ "flex-row"
    end
  end

  describe "menu/1 group callbacks (%JS{} attrs)" do
    test "publishes on_group_open / on_group_close as data attributes" do
      assigns = %{
        open: JS.push("opened"),
        close: JS.push("closed")
      }

      html =
        rendered_to_string(~H"""
        <Menu.menu id="m" on_group_open={@open} on_group_close={@close}>
          <Menu.menu_item navigate="/">Home</Menu.menu_item>
        </Menu.menu>
        """)

      assert html =~ "data-on-group-open"
      assert html =~ "data-on-group-close"
      assert html =~ "opened"
      assert html =~ "closed"
    end
  end

  describe "menu/1 customization (Twm merge)" do
    test "user class overrides defaults (last-in-wins)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu id="m" class="gap-8">
          <Menu.menu_item navigate="/">Home</Menu.menu_item>
        </Menu.menu>
        """)

      assert html =~ "gap-8"
    end
  end

  describe "menu_item/1 link variants" do
    test "renders an anchor for navigate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item navigate="/dashboard">Dashboard</Menu.menu_item>
        """)

      assert html =~ "<li"
      assert html =~ "<a"
      assert html =~ ~s(href="/dashboard")
      assert html =~ "Dashboard"
      assert html =~ ~s(data-menu-item)
    end

    test "renders an anchor for href" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item href="/settings">Settings</Menu.menu_item>
        """)

      assert html =~ ~s(href="/settings")
    end

    test "renders a button when no navigation target is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item phx-click="do-thing">Action</Menu.menu_item>
        """)

      assert html =~ "<button"
      assert html =~ ~s(type="button")
      assert html =~ "phx-click"
      assert html =~ ~s(data-menu-item)
    end
  end

  describe "menu_item/1 active state" do
    test "active marks the item as the current page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item navigate="/" active>Home</Menu.menu_item>
        """)

      assert html =~ ~s(aria-current="page")
    end

    test "inactive items carry no aria-current" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item navigate="/">Home</Menu.menu_item>
        """)

      refute html =~ "aria-current"
    end
  end

  describe "menu_item/1 composition" do
    test "renders a leading icon by name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item navigate="/" icon="hero-home">Home</Menu.menu_item>
        """)

      assert html =~ "hero-home"
    end

    test "renders a trailing slot (badge/affordance)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item navigate="/inbox">
          Inbox
          <:trailing>9</:trailing>
        </Menu.menu_item>
        """)

      assert html =~ "Inbox"
      assert html =~ "9"
    end

    test "label stays named but folds away in the collapsed sidebar rail" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item navigate="/" icon="hero-home">Home</Menu.menu_item>
        """)

      # sr-only (not display:none) keeps the link's accessible name in the icon rail
      assert html =~ "group-data-[state=collapsed]/sidebar:lg:sr-only"
    end

    test "applies a visible focus ring" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_item navigate="/">Home</Menu.menu_item>
        """)

      assert html =~ "focus-visible:ring-2"
    end
  end

  describe "menu_section/1" do
    test "renders a labelled grouping list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_section id="sec" label="Workspace">
          <Menu.menu_item navigate="/projects">Projects</Menu.menu_item>
        </Menu.menu_section>
        """)

      assert html =~ "Workspace"
      assert html =~ ~s(aria-labelledby="sec-label")
      assert html =~ ~s(id="sec-label")
      assert html =~ "Projects"
    end

    test "section label honors the sidebar collapse contract" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_section id="sec" label="Workspace">
          <Menu.menu_item navigate="/projects">Projects</Menu.menu_item>
        </Menu.menu_section>
        """)

      assert html =~ "group-data-[state=collapsed]/sidebar:lg:hidden"
    end

    test "renders without a label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_section id="sec">
          <Menu.menu_item navigate="/projects">Projects</Menu.menu_item>
        </Menu.menu_section>
        """)

      assert html =~ "Projects"
      refute html =~ "aria-labelledby"
    end
  end

  describe "menu_group/1 disclosure" do
    test "renders a trigger that controls a child list (APG disclosure)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_group id="grp" label="Reports">
          <Menu.menu_item navigate="/reports/sales">Sales</Menu.menu_item>
        </Menu.menu_group>
        """)

      assert html =~ "<button"
      assert html =~ ~s(data-menu-trigger)
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="grp-panel")
      assert html =~ ~s(id="grp-panel")
      assert html =~ "Reports"
      assert html =~ "Sales"
    end

    test "open starts expanded" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_group id="grp" label="Reports" open>
          <Menu.menu_item navigate="/reports/sales">Sales</Menu.menu_item>
        </Menu.menu_group>
        """)

      assert html =~ ~s(aria-expanded="true")
      assert html =~ "data-expanded"
    end

    test "renders a leading icon and a disclosure chevron" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_group id="grp" label="Reports" icon="hero-chart-bar">
          <Menu.menu_item navigate="/reports/sales">Sales</Menu.menu_item>
        </Menu.menu_group>
        """)

      assert html =~ "hero-chart-bar"
      assert html =~ "hero-chevron-down"
    end

    test "trigger is reachable by arrow-key roving focus and is an item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_group id="grp" label="Reports">
          <Menu.menu_item navigate="/reports/sales">Sales</Menu.menu_item>
        </Menu.menu_group>
        """)

      assert html =~ ~s(data-menu-item)
      assert html =~ ~s(data-menu-group)
    end

    test "trigger label stays named but folds away in the collapsed sidebar rail" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_group id="grp" label="Reports">
          <Menu.menu_item navigate="/reports/sales">Sales</Menu.menu_item>
        </Menu.menu_group>
        """)

      assert html =~ "group-data-[state=collapsed]/sidebar:lg:sr-only"
    end
  end

  describe "menu_group/1 horizontal dropdown" do
    test "renders the dropdown through the Popover primitive" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_group id="grp" orientation="horizontal" label="Products">
          <Menu.menu_item navigate="/products/app">App</Menu.menu_item>
        </Menu.menu_group>
        """)

      # The panel is a native popover supplied by the Popover primitive.
      assert html =~ ~s(popover="auto")
      assert html =~ ~s(id="grp-panel")
      assert html =~ ~s(data-menu-panel)
      # The trigger keeps the APG disclosure wiring server-side.
      assert html =~ ~s(data-menu-trigger)
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="grp-panel")
      # The trigger is a roving menu item (arrow nav + callback bridge depend on it).
      assert html =~ ~s(data-menu-item)
      # The chevron rotates with the popover's aria-expanded.
      assert html =~ "group-aria-expanded/trigger:rotate-180"
      assert html =~ "Products"
      assert html =~ "App"
    end

    test "does not render the vertical in-place disclosure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Menu.menu_group id="grp" orientation="horizontal" label="Products">
          <Menu.menu_item navigate="/products/app">App</Menu.menu_item>
        </Menu.menu_group>
        """)

      refute html =~ "grid-rows-[0fr]"
    end
  end
end
