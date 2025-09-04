defmodule Pulsar.Components.Label do
  @moduledoc """
  Beautiful, accessible label component with typography variants and visual indicators.

  Provides styled form labels with required indicators and error state styling.
  All styling is applied via Tailwind CSS utilities with semantic color tokens 
  supporting both light and dark modes.

  ## Features

  - **Accessibility-First**: Proper label-input association and screen reader support
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

      # With internationalized required text
      <.label for="email" required sr_required_text={gettext("(required)")}>
        Email Address
      </.label>

  ## Accessibility Features

  - **Proper Association**: Uses `for` attribute to associate with form inputs
  - **Required Field Support**: Screen reader-only text for required fields
  - **Data Attributes**: Exposes state via `data-required` and `data-error` for CSS targeting
  - **ARIA Compliance**: Follows WCAG 2.1 AA accessibility guidelines

  ## Required Indicator

  - **Visual**: Red asterisk (*) displayed after label text with proper size matching
  - **Screen Reader**: Hidden screen reader text announces "(required)" separately

  The required indicator uses semantic colors that automatically adapt to light/dark themes.
  Screen readers will announce both the label text and required status appropriately.

  ## Data Attributes for Styling

  - `data-required="true|false"` - Required field state
  - `data-error="true|false"` - Error state  
  - `data-size="xs|sm|md|lg|xl"` - Size variant

  ## Screen Reader Support

  Uses a `.sr-only` class for screen reader-only text. Ensure this class is available:
  ```css
  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border-width: 0;
  }
  ```
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  @doc """
  Renders a styled label component with typography variants and visual indicators.
  """
  attr(:for, :string, required: true, doc: "ID of the associated input element")
  attr(:required, :boolean, default: false, doc: "Whether the associated field is required")
  attr(:error, :boolean, default: false, doc: "Whether the label should show error styling")

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the label text"
  )

  attr(:sr_required_text, :string,
    default: "(required)",
    doc: "Screen reader text for required fields. Use with i18n: gettext(\"(required)\")"
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes")

  attr(:rest, :global,
    doc: "Additional HTML attributes passed through to the underlying label element"
  )

  slot(:inner_block, required: true, doc: "Label text content")

  def label(assigns) do
    assigns =
      assigns
      |> assign(:computed_classes, compute_label_classes(assigns))
      |> assign(:data_error, data_boolean(assigns.error))
      |> assign(:data_required, data_boolean(assigns.required))
      |> assign(:data_size, assigns.size)

    ~H"""
    <label
      for={@for}
      class={@computed_classes}
      data-required={@data_required}
      data-error={@data_error}
      data-size={@data_size}
      {@rest}
    >
      {render_slot(@inner_block)}
      <span :if={@required} class="sr-only">{@sr_required_text}</span>
      <span :if={@required} class={required_indicator_classes(@size)} aria-hidden="true">*</span>
    </label>
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
    "font-medium transition-colors duration-200 cursor-pointer"
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

  # Convert boolean to data attribute string
  defp data_boolean(true), do: "true"
  defp data_boolean(false), do: "false"
end
