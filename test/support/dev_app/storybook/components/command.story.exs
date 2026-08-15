defmodule Pulsar.DevApp.Storybook.Components.Command do
  use PhoenixStorybook.Story, :live_component

  alias Pulsar.Components.Command

  def component, do: Command
  def render_source, do: :module

  def attributes do
    [
      %Attr{
        id: :variant,
        type: :string,
        values: ~w(solid outline ghost elevated),
        default: "ghost",
        doc: "List surface"
      },
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "primary",
        doc: "Active-row accent"
      },
      %Attr{
        id: :size,
        type: :string,
        values: ~w(xs sm md lg xl),
        default: "md",
        doc: "Row scale"
      },
      %Attr{
        id: :async,
        type: :boolean,
        default: false,
        doc: "Run the filter off-process"
      }
    ]
  end

  def variations do
    [
      %Variation{
        id: :flat,
        description: "Flat list",
        attributes: %{id: "sb-cmd-flat", label: "Search", options: ["Alpha", "Beta", "Gamma"]}
      },
      %Variation{
        id: :grouped,
        description: "Grouped",
        attributes: %{
          id: "sb-cmd-grouped",
          label: "Search regions",
          options: [{"Europe", ["UK", "Sweden"]}, {"Asia", ["Japan"]}]
        }
      },
      %Variation{
        id: :decorated,
        description: "Icons and shortcuts",
        attributes: %{
          id: "sb-cmd-decorated",
          label: "Search commands",
          options: [
            [key: "Home", value: "home", icon: "hero-home", shortcut: "G H"],
            [key: "Settings", value: "settings", icon: "hero-cog-6-tooth", shortcut: "G S"]
          ]
        }
      },
      %Variation{
        id: :empty,
        description: "Empty",
        attributes: %{id: "sb-cmd-empty", label: "Search", options: []}
      },
      %Variation{
        id: :elevated,
        description: "Standalone surface",
        attributes: %{id: "sb-cmd-elevated", label: "Search", options: ["Alpha"], variant: "elevated"}
      }
    ]
  end
end
