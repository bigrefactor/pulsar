defmodule Pulsar.Components.NavbarTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Navbar

  describe "navbar/1 basic functionality" do
    test "renders a banner with default attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar">
          <:left>Acme</:left>
        </Navbar.navbar>
        """)

      assert html =~ "<header"
      assert html =~ ~s(id="bar")
      assert html =~ "Acme"
    end

    test "auto-generates an id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar>
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ ~s(id="navbar-)
    end

    test "renders start, center, and end regions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar">
          <:left>BrandHere</:left>
          <:center>SearchHere</:center>
          <:right>AccountHere</:right>
        </Navbar.navbar>
        """)

      assert html =~ "BrandHere"
      assert html =~ "SearchHere"
      assert html =~ "AccountHere"
    end

    test "does not force a nav landmark" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      refute html =~ "<nav"
    end
  end

  describe "navbar/1 menu button (sidebar pairing)" do
    test "renders no hamburger by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar">
          <:left>Acme</:left>
        </Navbar.navbar>
        """)

      refute html =~ "data-navbar-toggle"
    end

    test "renders a labeled hamburger wired to on_menu_toggle when set" do
      assigns = %{toggle: JS.dispatch("pulsar:sidebar-toggle", to: "#app-sidebar")}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" on_menu_toggle={@toggle}>
          <:left>Acme</:left>
        </Navbar.navbar>
        """)

      assert html =~ "data-navbar-toggle"
      assert html =~ ~s(aria-label="Menu")
      # the override is composed into the button's click handler
      assert html =~ "pulsar:sidebar-toggle"
      assert html =~ "phx-click"
    end

    test "menu_controls sets aria-controls on the hamburger (sidebar id)" do
      assigns = %{toggle: JS.dispatch("pulsar:sidebar-toggle", to: "#app-sidebar")}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" on_menu_toggle={@toggle} menu_controls="app-sidebar">
          <:left>Acme</:left>
        </Navbar.navbar>
        """)

      assert html =~ ~s(aria-controls="app-sidebar")
    end

    test "menu_label overrides the hamburger accessible name (i18n)" do
      assigns = %{toggle: JS.dispatch("x", to: "#y")}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" on_menu_toggle={@toggle} menu_label="Open menu">
          <:left>Acme</:left>
        </Navbar.navbar>
        """)

      assert html =~ ~s(aria-label="Open menu")
    end
  end

  describe "navbar/1 variants and colors" do
    test "solid color fills with the semantic background + foreground" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" variant="solid" color="primary">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ "bg-primary"
      assert html =~ "text-primary-foreground"
    end

    test "outline color uses a colored border" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" variant="outline" color="primary">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ "border-primary"
    end

    test "ghost is transparent" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" variant="ghost">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ "bg-transparent"
    end

    test "elevated carries a shadow" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" variant="elevated">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ "shadow-dropdown"
    end

    test "neutral solid uses a panel surface token" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" variant="solid" color="neutral">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ "bg-surface-1"
    end
  end

  describe "navbar/1 sizes" do
    test "size controls the bar height" do
      cases = %{
        "xs" => "h-12",
        "sm" => "h-14",
        "md" => "h-16",
        "lg" => "h-20",
        "xl" => "h-24"
      }

      for {size, height} <- cases do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Navbar.navbar id="bar" size={@size}>
            <:left>x</:left>
          </Navbar.navbar>
          """)

        assert html =~ height, "expected size=#{size} to render #{height}"
      end
    end
  end

  describe "navbar/1 sticky" do
    test "sticky=true pins the bar to the top of the viewport" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" sticky>
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ "sticky"
      assert html =~ "top-0"
    end

    test "is not sticky by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      refute html =~ "sticky top-0"
    end
  end

  describe "navbar/1 accessibility" do
    test "label sets an accessible name on the banner (multiple-banner pages)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" label="Primary">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ ~s(aria-label="Primary")
    end

    test "passes through global/aria attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" aria-describedby="hint" data-test="x">
          <:left>y</:left>
        </Navbar.navbar>
        """)

      assert html =~ ~s(aria-describedby="hint")
      assert html =~ ~s(data-test="x")
    end
  end

  describe "navbar/1 customization (Twm merge)" do
    test "user class overrides defaults (last-in-wins)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Navbar.navbar id="bar" size="md" class="h-10">
          <:left>x</:left>
        </Navbar.navbar>
        """)

      assert html =~ "h-10"
      refute html =~ "h-16"
    end
  end
end
