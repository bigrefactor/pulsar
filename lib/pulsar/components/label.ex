defmodule Pulsar.Components.Label do
  @moduledoc """
  Styled label component built on Stellar.Components.Label with typography variants and visual indicators.

  Provides beautiful, accessible form labels with required indicators 
  and error state styling. All styling is applied via Tailwind CSS utilities with semantic 
  color tokens supporting both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible label component
  - **Typography Variants**: Multiple sizes (xs through xl) matching input components
  - **Required Indicators**: Clear visual cues for field requirements
  - **Error State Styling**: Automatic styling coordination with form validation
  - **Dark Mode**: Automatic light/dark mode support
  - **Phoenix Integration**: Works seamlessly with Phoenix forms
  - **Full Stellar API**: All Stellar label props are supported

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

      # With internationalized required text
      <.label for="email" required sr_required_text={gettext("(required)")}>
        Email Address
      </.label>

  ## Error State Handling

  When a label is in an error state (typically when the associated form field has 
  validation errors), the label text automatically switches to danger color styling 
  to provide clear visual feedback.

  ## Stellar Integration

  This component wraps Stellar.Components.Label and passes through all its props:
  - Proper `for` attribute association with form inputs
  - Required field accessibility with screen reader support
  - All accessibility features and ARIA attributes
  - Data attributes for styling (`data-required="true|false"`)
  - All standard HTML attributes

  ## Required Indicator

  - **Required**: Red asterisk (*) displayed after label text with proper ARIA attributes

  The required indicator is sized proportionally to the label size and uses semantic colors
  that automatically adapt to light/dark themes. Screen readers will announce the field
  as required through Stellar's built-in accessibility features.
  """

  use Phoenix.Component
  alias Stellar.Components.Label, as: StellarLabel

  import TailwindMerge, only: [merge: 1]

  @doc """
  Renders a styled label component with typography variants and visual indicators.
  """
  attr :for, :string, required: true, doc: "ID of the associated input element"
  attr :required, :boolean, default: false, doc: "Whether the associated field is required"
  attr :error, :boolean, default: false, doc: "Whether the label should show error styling"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the label text"

  attr :sr_required_text, :string, 
    default: "(required)", 
    doc: "Screen reader text for required fields. Use with i18n: gettext(\"(required)\")"

  attr :class, :string, default: "", doc: "Additional CSS classes"

  attr :rest, :global,
    doc: "Additional HTML attributes passed through to the underlying label element"

  slot :inner_block, required: true, doc: "Label text content"

  def label(assigns) do
    assigns =
      assigns
      |> assign(:computed_classes, compute_label_classes(assigns))

    ~H"""
    <StellarLabel.label
      for={@for}
      required={@required}
      sr_required_text={@sr_required_text}
      class={@computed_classes}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
      <span :if={@required} class={required_indicator_classes(@size)} aria-hidden="true">*</span>
    </StellarLabel.label>
    """
  end

  # Compute all label classes
  defp compute_label_classes(assigns) do
    merge([
      base_label_classes(),
      size_classes(assigns.size),
      color_classes(assigns.error),
      assigns.class
    ])
  end

  # Base classes for all labels
  defp base_label_classes do
    "font-medium transition-colors duration-200"
  end

  # Size-based typography classes
  defp size_classes("xs"), do: "text-xs"
  defp size_classes("sm"), do: "text-sm"
  defp size_classes("md"), do: "text-base"
  defp size_classes("lg"), do: "text-lg"
  defp size_classes("xl"), do: "text-xl"

  # Color classes based on state
  defp color_classes(true = _error) do
    "text-danger dark:text-dark-danger"
  end

  defp color_classes(false = _error) do
    "text-foreground dark:text-dark-foreground"
  end

  # Required indicator classes with size-appropriate spacing and ARIA hidden
  defp required_indicator_classes("xs"), do: "text-danger dark:text-dark-danger ml-0.5 text-xs"
  defp required_indicator_classes("sm"), do: "text-danger dark:text-dark-danger ml-0.5 text-sm"
  defp required_indicator_classes("md"), do: "text-danger dark:text-dark-danger ml-1 text-base"
  defp required_indicator_classes("lg"), do: "text-danger dark:text-dark-danger ml-1 text-lg"
  defp required_indicator_classes("xl"), do: "text-danger dark:text-dark-danger ml-1 text-xl"
end