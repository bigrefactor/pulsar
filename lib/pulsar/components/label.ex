defmodule Pulsar.Components.Label do
  @moduledoc """
  Beautiful, accessible label component with typography variants and visual indicators.

  Provides styled form labels with required indicators and error state styling.
  All styling is applied via Tailwind CSS utilities with semantic color tokens
  supporting both light and dark modes.

  ## Features

  - **Accessibility-First**: Proper label-input association
  - **Typography Variants**: Multiple sizes (xs through xl) matching input components
  - **Required Indicators**: Clear visual cues for field requirements
  - **Error State Styling**: Automatic styling coordination with form validation
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Works seamlessly with Phoenix forms
  - **Data Attributes**: State exposed for additional CSS targeting

  ## Examples

      # Basic label
      <.label for="email">Email Address</.label>

      # Required field with size
      <.label for="password" required size="lg">Password</.label>

      # Error state
      <.label for="invalid-field" error>Invalid Field</.label>

      # Large size with custom styling
      <.label for="title" size="xl" class="mb-4">
        Document Title
      </.label>

  ## Accessibility Features

  - **Proper Association**: Uses `for` attribute to associate with form inputs
  - **Required Field Support**: Visual indicator paired with the control's `required` attribute
  - **Data Attributes**: Exposes state via `data-required` and `data-error` for CSS targeting
  - **ARIA Compliance**: Follows WCAG 2.2 AA accessibility guidelines

  ## Required Indicator

  - **Visual**: Red asterisk (*) displayed after label text with proper size matching

  Required state is announced from the associated control's `required`
  attribute, which `field` sets for you.

  ## Data Attributes for Styling

  - `data-required="true|false"` - Required field state
  - `data-error="true|false"` - Error state
  - `data-size="xs|sm|md|lg|xl"` - Size variant
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.Rendered

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Size configuration for label typography and required indicator margins
  @size_config %{
    "lg" => %{
      margin: "after:ml-1",
      text: "text-lg"
    },
    "md" => %{
      margin: "after:ml-1",
      text: "text-base"
    },
    "sm" => %{
      margin: "after:ml-0.5",
      text: "text-sm"
    },
    "xl" => %{
      margin: "after:ml-1",
      text: "text-xl"
    },
    "xs" => %{
      margin: "after:ml-0.5",
      text: "text-xs"
    }
  }

  # Base label styling classes
  @label_base_classes "font-medium transition-colors duration-fast ease-standard cursor-pointer"

  @doc """
  Renders a styled label component with typography variants and visual indicators.
  """
  @spec label(map()) :: Rendered.t()
  attr(:for, :string, required: true, doc: "ID of the associated input element")
  attr(:required, :boolean, default: false, doc: "Whether the associated field is required")
  attr(:error, :boolean, default: false, doc: "Whether the label should show error styling")

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the label text"
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes passed through to the underlying label element")

  slot(:inner_block, required: true, doc: "Label text content")

  def label(assigns) do
    ~H"""
    <label
      for={@for}
      class={
        merge([
          base_label_classes(),
          size_text_classes(@size),
          color_classes(@error),
          required_indicator_classes(@required, @size),
          @class
        ])
      }
      data-required={to_string(@required)}
      data-error={to_string(@error)}
      data-size={@size}
      {@rest}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end

  # ============================================================================
  # LABEL COMPONENT HELPERS
  # ============================================================================

  # Base classes for all labels
  @spec base_label_classes() :: String.t()
  defp base_label_classes do
    @label_base_classes
  end

  # Size-based typography classes
  @spec size_text_classes(String.t()) :: String.t()
  defp size_text_classes(size) do
    @size_config[size][:text]
  end

  # Color classes based on error state
  @spec color_classes(boolean()) :: String.t()
  defp color_classes(true) do
    "text-danger"
  end

  defp color_classes(false) do
    "text-foreground"
  end

  # Required indicator, rendered as a pseudo-element so it stays out of the
  # label's accessible name and text content
  @spec required_indicator_classes(boolean() | nil, String.t()) :: String.t()
  defp required_indicator_classes(true, size) do
    "after:content-['*'] after:text-danger " <> indicator_margin_classes(size)
  end

  defp required_indicator_classes(_required, _size), do: ""

  # Size-appropriate margin for the required indicator
  @spec indicator_margin_classes(String.t()) :: String.t()
  defp indicator_margin_classes(size) do
    @size_config[size][:margin] || ""
  end
end
