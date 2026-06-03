defmodule Pulsar.DevApp.Storybook.Components.DropdownMenu do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.DropdownMenu

  def function, do: &DropdownMenu.dropdown_menu/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :placement,
        type: :string,
        values:
          ~w(top top-start top-end bottom bottom-start bottom-end left left-start left-end right right-start right-end),
        default: "bottom-start",
        doc: "Preferred anchor placement"
      },
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost elevated),
        default: "elevated",
        doc: "Visual style of the menu surface"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral",
        doc: "Color scheme of the menu surface"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Corner radius of the menu surface"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes for the menu panel"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :trigger, required: true, doc: "The activating control — a single <button>"},
      %Slot{id: :inner_block, required: true, doc: "Menu items, separators, labels, groups, and submenus"}
    ]
  end

  def variations do
    trigger =
      ~s|<:trigger><button type="button" class="rounded border border-border px-3 py-1.5 text-sm">Open menu</button></:trigger>|

    actions =
      ~s|<DropdownMenu.dropdown_menu_label>My account</DropdownMenu.dropdown_menu_label>| <>
        ~s|<DropdownMenu.dropdown_menu_item icon="hero-user" href="#">Profile</DropdownMenu.dropdown_menu_item>| <>
        ~s|<DropdownMenu.dropdown_menu_item icon="hero-cog-6-tooth" href="#">Settings</DropdownMenu.dropdown_menu_item>| <>
        ~s|<DropdownMenu.dropdown_menu_separator />| <>
        ~s|<DropdownMenu.dropdown_menu_item destructive icon="hero-arrow-right-start-on-rectangle" href="#">Sign out</DropdownMenu.dropdown_menu_item>|

    selections =
      ~s|<DropdownMenu.dropdown_menu_checkbox_item checked>Show grid</DropdownMenu.dropdown_menu_checkbox_item>| <>
        ~s|<DropdownMenu.dropdown_menu_separator />| <>
        ~s|<DropdownMenu.dropdown_menu_radio_group label="Sort by"><DropdownMenu.dropdown_menu_radio_item checked>Name</DropdownMenu.dropdown_menu_radio_item><DropdownMenu.dropdown_menu_radio_item>Date</DropdownMenu.dropdown_menu_radio_item></DropdownMenu.dropdown_menu_radio_group>|

    with_submenu =
      ~s|<DropdownMenu.dropdown_menu_item href="#">Edit</DropdownMenu.dropdown_menu_item>| <>
        ~s|<DropdownMenu.dropdown_menu_submenu id="sb-share" label="Share" icon="hero-share"><DropdownMenu.dropdown_menu_item href="#">Email</DropdownMenu.dropdown_menu_item><DropdownMenu.dropdown_menu_item href="#">Copy link</DropdownMenu.dropdown_menu_item></DropdownMenu.dropdown_menu_submenu>|

    [
      %Variation{
        id: :default,
        description: "Account menu with a destructive action",
        slots: [trigger, actions]
      },
      %Variation{
        id: :selections,
        description: "Checkbox and radio items (the menu stays open on toggle)",
        slots: [trigger, selections]
      },
      %Variation{
        id: :with_submenu,
        description: "Row actions with a nested submenu",
        slots: [trigger, with_submenu]
      },
      %Variation{
        id: :outline_primary,
        description: "Outline primary surface",
        attributes: %{variant: "outline", color: "primary"},
        slots: [trigger, actions]
      }
    ]
  end
end
