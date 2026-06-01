defmodule Pulsar.Components.SidebarTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Sidebar

  describe "sidebar/1 basic functionality" do
    test "renders a nav landmark with default attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav">Content</Sidebar.sidebar>
        """)

      assert html =~ "<nav"
      assert html =~ ~s(id="nav")
      assert html =~ "Content"
      # navigation landmark with a default accessible name
      assert html =~ ~s(aria-label="Sidebar")
      # colocated hook is attached
      assert html =~ "PulsarSidebar"
    end

    test "auto-generates an id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar>Content</Sidebar.sidebar>
        """)

      assert html =~ ~s(id="sidebar-)
    end

    test "renders header, content, and footer slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav">
          <:header>Brand</:header>
          Main nav
          <:footer>Account</:footer>
        </Sidebar.sidebar>
        """)

      assert html =~ "Brand"
      assert html =~ "Main nav"
      assert html =~ "Account"
    end

    test "renders a dismissible backdrop element for the mobile drawer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav">Content</Sidebar.sidebar>
        """)

      assert html =~ "data-sidebar-backdrop"
    end
  end

  describe "sidebar/1 CSS contract (data-* + group)" do
    test "publishes side, collapsible, and state as data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav">Content</Sidebar.sidebar>
        """)

      assert html =~ ~s(data-side="left")
      assert html =~ ~s(data-collapsible="offcanvas")
      assert html =~ ~s(data-state="expanded")
      assert html =~ ~s(data-mobile="closed")
    end

    test "exposes the named group marker so content can react to collapse" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav">Content</Sidebar.sidebar>
        """)

      assert html =~ "group/sidebar"
    end

    test "side=right flips the data-side attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" side="right">Content</Sidebar.sidebar>
        """)

      assert html =~ ~s(data-side="right")
    end

    test "collapsible mode is reflected in data-collapsible" do
      for mode <- ~w(icon offcanvas none) do
        assigns = %{mode: mode}

        html =
          rendered_to_string(~H"""
          <Sidebar.sidebar id="nav" collapsible={@mode}>Content</Sidebar.sidebar>
          """)

        assert html =~ ~s(data-collapsible="#{mode}")
      end
    end

    test "open=false renders the collapsed initial state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" open={false}>Content</Sidebar.sidebar>
        """)

      assert html =~ ~s(data-state="collapsed")
    end
  end

  describe "sidebar/1 variants and colors" do
    test "solid color fills with the semantic background + foreground" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" variant="solid" color="primary">Content</Sidebar.sidebar>
        """)

      assert html =~ "bg-primary"
      assert html =~ "text-primary-foreground"
    end

    test "outline color uses a colored border on a surface" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" variant="outline" color="primary">Content</Sidebar.sidebar>
        """)

      assert html =~ "border-primary"
    end

    test "ghost is transparent" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" variant="ghost">Content</Sidebar.sidebar>
        """)

      assert html =~ "bg-transparent"
    end

    test "elevated carries a shadow" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" variant="elevated">Content</Sidebar.sidebar>
        """)

      assert html =~ "shadow-dropdown"
    end

    test "neutral solid uses a panel surface token" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" variant="solid" color="neutral">Content</Sidebar.sidebar>
        """)

      assert html =~ "bg-surface-1"
    end
  end

  describe "sidebar/1 sizes" do
    test "size controls the expanded panel width" do
      cases = %{
        "xs" => "w-48",
        "sm" => "w-56",
        "md" => "w-64",
        "lg" => "w-72",
        "xl" => "w-80"
      }

      for {size, width} <- cases do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Sidebar.sidebar id="nav" size={@size}>Content</Sidebar.sidebar>
          """)

        assert html =~ width, "expected size=#{size} to render #{width}"
      end
    end
  end

  describe "sidebar/1 accessibility" do
    test "label overrides the navigation accessible name (i18n)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" label="Primary">Content</Sidebar.sidebar>
        """)

      assert html =~ ~s(aria-label="Primary")
    end

    test "backdrop is hidden from assistive tech" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav">Content</Sidebar.sidebar>
        """)

      assert html =~ ~s(aria-hidden="true")
    end

    test "passes through global/aria attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" aria-describedby="hint" data-test="x">Content</Sidebar.sidebar>
        """)

      assert html =~ ~s(aria-describedby="hint")
      assert html =~ ~s(data-test="x")
    end
  end

  describe "sidebar/1 callbacks" do
    test "on_open / on_close are emitted as JS commands" do
      assigns = %{
        on_open: JS.dispatch("opened", to: "#x"),
        on_close: JS.dispatch("closed", to: "#x")
      }

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" on_open={@on_open} on_close={@on_close}>Content</Sidebar.sidebar>
        """)

      assert html =~ "data-on-open"
      assert html =~ "data-on-close"
      assert html =~ "opened"
      assert html =~ "closed"
    end
  end

  describe "sidebar/1 customization (Twm merge)" do
    test "user class overrides defaults (last-in-wins)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" size="md" class="w-96">Content</Sidebar.sidebar>
        """)

      assert html =~ "w-96"
      refute html =~ "w-64"
    end
  end

  describe "JS helpers" do
    test "toggle/2 dispatches the toggle event to the panel id" do
      assert %JS{ops: ops} = Sidebar.toggle("nav")
      assert [["dispatch", %{event: "pulsar:sidebar-toggle", to: "#nav"}]] = ops
    end

    test "show/2 dispatches the show event to the panel id" do
      assert %JS{ops: ops} = Sidebar.show("nav")
      assert [["dispatch", %{event: "pulsar:sidebar-show", to: "#nav"}]] = ops
    end

    test "hide/2 dispatches the hide event to the panel id" do
      assert %JS{ops: ops} = Sidebar.hide("nav")
      assert [["dispatch", %{event: "pulsar:sidebar-hide", to: "#nav"}]] = ops
    end

    test "helpers compose onto an existing JS pipeline" do
      assert %JS{ops: ops} = Sidebar.toggle(JS.add_class("foo", to: "#bar"), "nav")
      assert [["add_class", _], ["dispatch", %{event: "pulsar:sidebar-toggle", to: "#nav"}]] = ops
    end
  end
end
