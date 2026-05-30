defmodule Pulsar.DevApp.Storybook.Components.Link do
  # Note: the component function is `a/1`, not `link/1`
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Link

  def function, do: &Link.a/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid ghost outline),
        default: "outline",
        doc:
          "Visual style variant: outline=always underlined (inline body text), solid=no underline (standalone/nav links), ghost=hover underline"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(primary secondary muted danger success warning info inherit),
        default: "primary",
        doc: "Color scheme of the link"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl inherit),
        default: "inherit",
        doc: "Text size of the link (inherit adapts to parent text size)"
      },
      %Attr{
        id: :href,
        type: :string,
        default: nil,
        doc: "External URL to navigate to"
      },
      %Attr{
        id: :navigate,
        type: :any,
        default: nil,
        doc: "Phoenix route to navigate to (string or VerifiedRoute)"
      },
      %Attr{
        id: :patch,
        type: :any,
        default: nil,
        doc: "Phoenix route to patch navigate to"
      },
      %Attr{
        id: :replace,
        type: :boolean,
        default: false,
        doc: "Replace current history entry"
      },
      %Attr{
        id: :target,
        type: :string,
        default: nil,
        doc: "Link target attribute"
      },
      %Attr{
        id: :rel,
        type: :string,
        default: nil,
        doc: "Link relationship"
      },
      %Attr{
        id: :class,
        type: :string,
        default: "",
        doc: "Additional CSS classes"
      }
    ]
  end

  def slots do
    [
      %Slot{id: :inner_block, required: true, doc: "Link content"},
      %Slot{id: :start_icon, doc: "Icon shown before the link text"},
      %Slot{id: :end_icon, doc: "Icon shown after the link text"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :external_href,
        description: "External link opening in new tab",
        attributes: %{href: "https://elixir-lang.org", target: "_blank"},
        slots: ["Visit Elixir Lang"]
      },
      %Variation{
        id: :internal_navigate,
        description: "Internal navigation link (Phoenix navigate)",
        attributes: %{navigate: "/"},
        slots: ["Go to Home"]
      },
      %Variation{
        id: :patch_link,
        description: "LiveView patch link",
        attributes: %{patch: "/"},
        slots: ["Patch to Home"]
      },
      %Variation{
        id: :outline_variant,
        description: "Outline variant (always underlined)",
        attributes: %{href: "#", variant: "outline", color: "primary"},
        slots: ["Learn More"]
      },
      %Variation{
        id: :ghost_hover_underline,
        description: "Ghost variant (underline on hover)",
        attributes: %{href: "#", variant: "ghost", color: "primary"},
        slots: ["Terms of Service"]
      },
      %Variation{
        id: :danger_link,
        description: "Danger color link",
        attributes: %{href: "#", color: "danger"},
        slots: ["Delete Account"]
      },
      %Variation{
        id: :size_sm,
        description: "Small text link",
        attributes: %{href: "#", size: "sm", color: "primary"},
        slots: ["Forgot password?"]
      }
    ]
  end
end
