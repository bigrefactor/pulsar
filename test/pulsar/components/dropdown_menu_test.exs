defmodule Pulsar.Components.DropdownMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.DropdownMenu

  describe "dropdown_menu/1 basic functionality" do
    test "renders a trigger and a menu panel wired for the menu-button pattern" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>Profile</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "Open"
      assert html =~ "Profile"
      assert html =~ ~s(id="dm")
      # Composes Popover in click mode and carries the menu role.
      assert html =~ ~s(popover="auto")
      assert html =~ ~s(data-trigger="click")
      assert html =~ ~s(role="menu")
      # Both the popover positioning hook and the menu keyboard hook are present.
      assert html =~ "PulsarPopover"
      assert html =~ "PulsarDropdownMenu"
    end

    test "auto-generates a menu id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu>
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(id="dropdown-menu-)
    end
  end

  describe "dropdown_menu_item/1" do
    test "renders an action button menuitem out of the tab order" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item phx-click="save">Save</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="menuitem")
      assert html =~ "data-menu-item"
      assert html =~ ~s(tabindex="-1")
      assert html =~ ~s(type="button")
      assert html =~ ~s(phx-click="save")
    end

    test "renders a navigation link menuitem when given a target" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item navigate="/profile">Profile</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(href="/profile")
      assert html =~ ~s(role="menuitem")
      assert html =~ "data-menu-item"
      assert html =~ ~s(tabindex="-1")
    end

    test "renders a leading icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item icon="hero-user">Profile</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "hero-user"
    end

    test "renders a trailing shortcut hint" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>
            Save
            <:trailing>⌘S</:trailing>
          </DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "⌘S"
    end

    test "a disabled item is marked aria-disabled and inert" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item disabled>Archived</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(aria-disabled="true")
      assert html =~ "data-disabled"
      assert html =~ "pointer-events-none"
    end

    test "a destructive item carries danger styling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item destructive>Delete</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "text-danger"
    end
  end

  describe "dropdown_menu_checkbox_item/1" do
    test "renders a checkbox menuitem reflecting its checked state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_checkbox_item checked phx-click="toggle">
            Show grid
          </DropdownMenu.dropdown_menu_checkbox_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="menuitemcheckbox")
      assert html =~ ~s(aria-checked="true")
      assert html =~ "data-menu-item"
    end

    test "renders aria-checked false when unchecked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_checkbox_item>Show grid</DropdownMenu.dropdown_menu_checkbox_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(aria-checked="false")
    end
  end

  describe "dropdown_menu_radio_group/1 + dropdown_menu_radio_item/1" do
    test "renders a labelled radio group of menuitemradio rows" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_radio_group label="Sort by">
            <DropdownMenu.dropdown_menu_radio_item checked>Name</DropdownMenu.dropdown_menu_radio_item>
            <DropdownMenu.dropdown_menu_radio_item>Date</DropdownMenu.dropdown_menu_radio_item>
          </DropdownMenu.dropdown_menu_radio_group>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="Sort by")
      assert html =~ ~s(role="menuitemradio")
      assert html =~ ~s(aria-checked="true")
      assert html =~ ~s(aria-checked="false")
    end
  end

  describe "dropdown_menu_label/1 and dropdown_menu_group/1" do
    test "label renders a non-interactive heading with accessible text color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_label>Account</DropdownMenu.dropdown_menu_label>
          <DropdownMenu.dropdown_menu_item>Profile</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "Account"
      # Essential heading text uses the foreground token so it clears AA contrast.
      assert html =~ "text-foreground"
    end

    test "group wraps items in role=group and wires aria-labelledby to its label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_group id="grp" label="Workspace">
            <DropdownMenu.dropdown_menu_item>Projects</DropdownMenu.dropdown_menu_item>
          </DropdownMenu.dropdown_menu_group>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-labelledby="grp-label")
      assert html =~ ~s(id="grp-label")
    end
  end

  describe "dropdown_menu_separator/1" do
    test "renders a separator role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
          <DropdownMenu.dropdown_menu_separator />
          <DropdownMenu.dropdown_menu_item>Two</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="separator")
    end
  end

  describe "dropdown_menu_submenu/1" do
    test "renders a submenu trigger that owns a nested menu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_submenu id="sub" label="Share">
            <DropdownMenu.dropdown_menu_item>Email</DropdownMenu.dropdown_menu_item>
          </DropdownMenu.dropdown_menu_submenu>
        </DropdownMenu.dropdown_menu>
        """)

      # The submenu trigger is itself a menuitem that announces a popup menu.
      assert html =~ ~s(aria-haspopup="menu")
      assert html =~ "data-menu-item"
      # A nested role="menu" panel (root + submenu => the role appears twice).
      assert html =~ "hero-chevron-right"
      assert length(String.split(html, ~s(role="menu"))) - 1 >= 2
      assert html =~ "Email"
    end
  end

  describe "dropdown_menu/1 surface (pass-through to Popover)" do
    test "defaults to an elevated neutral menu surface with tight padding" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "shadow-dropdown"
      assert html =~ "p-1"
    end

    test "variant and color pass through to the panel surface" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm" variant="solid" color="danger">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      # Popover's solid surface passes through, opaque (no alpha bleed-through).
      assert html =~ "color-mix(in_oklab,var(--color-danger)_10%,var(--color-surface-1))"
    end

    test "placement and offset pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm" placement="top-end" offset={12}>
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(data-placement="top-end")
      assert html =~ ~s(data-offset="12")
    end
  end

  describe "dropdown_menu/1 callbacks and passthrough" do
    test "on_open / on_close are emitted as JS commands" do
      assigns = %{
        on_open: JS.dispatch("opened", to: "#x"),
        on_close: JS.dispatch("closed", to: "#x")
      }

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm" on_open={@on_open} on_close={@on_close}>
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "data-on-open"
      assert html =~ "data-on-close"
      assert html =~ "opened"
      assert html =~ "closed"
    end

    test "passes through aria attributes onto the menu panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm" aria-label="Account menu">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(aria-label="Account menu")
    end

    test "a caller-supplied aria-label wins over label without duplicating the attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm" label="Folded" aria-label="Caller wins">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(aria-label="Caller wins")
      refute html =~ ~s(aria-label="Folded")
      # the folded label must never emit a second aria-label attribute
      assert html |> String.split("aria-label=") |> length() == 2
    end

    test "label yields to a caller-supplied aria-labelledby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm" label="Folded" aria-labelledby="heading">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(aria-labelledby="heading")
      refute html =~ "aria-label="
    end
  end

  describe "dropdown_menu/1 customization (Twm merge)" do
    test "user class overrides the default surface (last-in-wins)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="dm" class="rounded-none">
          <:trigger><button>Open</button></:trigger>
          <DropdownMenu.dropdown_menu_item>One</DropdownMenu.dropdown_menu_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "rounded-none"
    end
  end
end
