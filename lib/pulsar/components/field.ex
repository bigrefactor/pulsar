defmodule Pulsar.Components.Field do
  @moduledoc """
  A composable field component that wraps form inputs with label, description, error handling, and decorators.

  The Field component provides a unified interface for all form inputs, automatically handling
  labels, descriptions, error messages, and input rendering based on the specified type.
  All styling is applied via Tailwind CSS utilities with semantic color tokens
  supporting both light and dark modes.

  ## Features

  - **Type-Based Rendering**: Automatically renders appropriate Pulsar component based on type
  - **Automatic Label Generation**: Generates human-readable labels from field names using Phoenix.Naming.humanize/1
  - **Error Integration**: Extracts and displays errors from Phoenix form fields
  - **Decorator Support**: Passes through start/end decorators to compatible inputs
  - **Consistent Layout**: Standardized spacing and positioning for all field elements
  - **Accessibility Built-in**: Proper label association and ARIA attributes
  - **Phoenix Integration**: Seamless integration with Phoenix forms and changesets

  ## Examples

      # Basic text field with auto-generated label
      <.field field={@form[:email]} type="email" />

      # Field with custom label and description
      <.field field={@form[:username]} type="text" placeholder="Choose a username">
        <:label>Username</:label>
        <:description>This will be your public display name</:description>
      </.field>

      # Field with decorators (passed to Input component)
      <.field field={@form[:price]} type="number" step="0.01" min="0">
        <:label>Price</:label>
        <:start_decorator>$</:start_decorator>
        <:end_decorator>USD</:end_decorator>
      </.field>

      # Select field
      <.field field={@form[:country]} type="select" options={@countries} prompt="Choose a country">
        <:label>Country</:label>
        <:description>Select your country of residence</:description>
      </.field>

      # Checkbox field
      <.field field={@form[:terms]} type="checkbox">
        <:label>I agree to the terms and conditions</:label>
      </.field>

        # Switch field with description
        <.field field={@form[:notifications_enabled]} type="switch">
          <:label>Enable notifications</:label>
          <:description>Receive email updates about your account activity</:description>
        </.field>

        # File upload field (HTML attributes like accept pass through via rest)
        <.field field={@form[:avatar]} type="file" accept="image/*">
          <:label>Profile Picture</:label>
          <:description>Upload a profile image (JPG, PNG, or GIF)</:description>
        </.field>

        # Range input with min/max/step
        <.field field={@form[:volume]} type="range" min="0" max="100" step="10">
          <:label>Volume Level</:label>
          <:description>Adjust the audio volume</:description>
        </.field>

        # Radio field with tuple list options
        <.field field={@form[:size]} type="radio" options={[{"Small", "s"}, {"Medium", "m"}, {"Large", "l"}]}>
          <:label>T-Shirt Size</:label>
        </.field>

        # Radio field with keyword list options (alternative format)
        <.field field={@form[:priority]} type="radio" options={[low: "low", medium: "medium", high: "high"]}>
          <:label>Priority Level</:label>
        </.field>

        # Custom label styling and size override
        <.field field={@form[:title]} type="text">
          <:label class="font-bold text-primary-700" size="lg">Document Title</:label>
          <:description class="italic">Choose a descriptive title</:description>
        </.field>

  ## Label Generation

  When no `:label` slot is provided, labels are automatically generated from field names using
  `Phoenix.Naming.humanize/1`. This converts field names like:
  - `:email` → "Email"
  - `:first_name` → "First name"
  - `:user_email` → "User email"
  - `:created_at` → "Created at"

  ## Supported Input Types

  All input types support the full range of styling attributes including `variant`, `color`, and `size`:

  - **Text Inputs**: text, email, password, number, tel, url, search, date, time, datetime-local, file, range (via Pulsar.Components.Input)
  - **Select**: Renders Pulsar.Components.Select with dropdown options
  - **Textarea**: Renders Pulsar.Components.Textarea for multi-line text
  - **Checkbox**: Renders Pulsar.Components.Checkbox with optional card styling
  - **Switch**: Renders Pulsar.Components.Switch with iOS-style toggle
  - **Radio**: Renders Pulsar.Components.RadioGroup with grouped options

  ## Layout Customization

  The field wrapper can be customized with CSS classes for different layouts:

      # Horizontal layout
      <.field
        field={@form[:email]}
        type="email"
        class="grid grid-cols-3 gap-4 items-center"
      >
        <:label class="col-span-1">Email</:label>
        <:description class="col-span-2 col-start-2">Your primary email address</:description>
      </.field>

      # Inline layout for switches
      <.field
        field={@form[:dark_mode]}
        type="switch"
        class="flex items-center justify-between"
      >
        <:label>Dark mode</:label>
      </.field>

  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered

  # Import all the Pulsar components we'll be rendering
  alias Pulsar.Components.Checkbox
  alias Pulsar.Components.Icon
  alias Pulsar.Components.Input
  alias Pulsar.Components.Label
  alias Pulsar.Components.RadioGroup
  alias Pulsar.Components.Select
  alias Pulsar.Components.Switch
  alias Pulsar.Components.Textarea

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Description color configuration for different states
  @description_colors %{
    "danger" => "text-danger-600",
    "info" => "text-info-600",
    "neutral" => "text-gray-600",
    "primary" => "text-primary-600",
    "secondary" => "text-secondary-600",
    "success" => "text-success-600",
    "warning" => "text-warning-600"
  }

  # Inline label color configuration for checkbox/switch labels
  @inline_label_colors %{
    "danger" => "text-danger-900",
    "info" => "text-info-900",
    "neutral" => "text-gray-900",
    "primary" => "text-primary-900",
    "secondary" => "text-secondary-900",
    "success" => "text-success-900",
    "warning" => "text-warning-900"
  }

  # Inline label size configuration
  @inline_label_sizes %{
    "lg" => "text-base",
    "md" => "text-sm",
    "sm" => "text-sm",
    "xl" => "text-lg",
    "xs" => "text-xs"
  }

  # Error message styling - always uses danger color
  @error_message_classes "text-sm text-danger-600 flex items-center gap-1"

  # Base field wrapper classes
  @field_wrapper_base_classes "flex flex-col gap-2"

  # Label section wrapper classes
  @label_section_classes "flex flex-col gap-1"

  # Inline label base classes for checkbox/switch.
  # Note: `text-{size}` is added by `size_class` and would reset line-height in
  # Tailwind v4, so `leading-none` is appended AFTER `size_class` in the merge
  # below rather than declared here.
  @inline_label_base_classes "font-medium peer-disabled:cursor-not-allowed peer-disabled:opacity-70"

  # ============================================================================
  # MAIN FIELD COMPONENT
  # ============================================================================

  @doc """
  Renders a form field with automatic component selection based on type.
  """
  @spec field(map()) :: Rendered.t()

  # Required attributes
  attr(:field, FormField, required: true, doc: "Phoenix form field")

  attr(:type, :string,
    default: "text",
    values: ~w(text email password number tel url search date time datetime-local month week color file range
                select textarea checkbox radio switch),
    doc: "Input type - determines which component to render"
  )

  # Optional field-level attributes
  attr(:id, :string, default: nil, doc: "Override auto-generated field ID")
  attr(:name, :string, default: nil, doc: "Override field name")
  attr(:value, :any, default: nil, doc: "Override field value")
  attr(:class, :string, default: "", doc: "Additional CSS classes for field wrapper")

  attr(:show_errors, :atom,
    default: :touched,
    values: [:touched, :always, :never],
    doc: "When to show errors: :touched (default), :always, :never"
  )

  # Common input attributes that get passed through
  attr(:variant, :string, default: "outline", doc: "Visual variant (outline, solid, ghost)")
  attr(:color, :string, default: "neutral", doc: "Color theme")
  attr(:size, :string, default: "md", doc: "Input size")
  attr(:placeholder, :string, default: nil, doc: "Placeholder text")
  attr(:required, :boolean, default: false, doc: "Mark field as required")
  attr(:disabled, :boolean, default: false, doc: "Disable the field")
  attr(:readonly, :boolean, default: false, doc: "Make field read-only")

  # Type-specific attributes
  attr(:options, :list, default: nil, doc: "Options for select/radio (list or keyword list)")
  attr(:prompt, :string, default: nil, doc: "Prompt option for select")
  attr(:multiple, :boolean, default: false, doc: "Allow multiple selection (select)")
  attr(:rows, :integer, default: 4, doc: "Number of rows for textarea")
  attr(:min, :any, default: nil, doc: "Minimum value (number, date)")
  attr(:max, :any, default: nil, doc: "Maximum value (number, date)")
  attr(:step, :any, default: nil, doc: "Step increment (number)")
  attr(:pattern, :string, default: nil, doc: "Validation pattern")
  attr(:autocomplete, :string, default: nil, doc: "Autocomplete hint")
  attr(:checked, :boolean, default: nil, doc: "Checked state (checkbox/switch)")

  # Global attributes passed through to inputs
  attr(:rest, :global, doc: "Additional HTML attributes passed to the input")

  # Field-specific slots
  slot(:label, doc: "Custom label content (auto-generated from field name if not provided)") do
    attr(:class, :string, doc: "Additional CSS classes for label")
    attr(:size, :string, doc: "Override label size (defaults to field size)")
  end

  slot(:description, doc: "Help text displayed below the label") do
    attr(:class, :string, doc: "Additional CSS classes for description")
  end

  slot(:start_decorator, doc: "Leading decorator (passed to Input component)")
  slot(:end_decorator, doc: "Trailing decorator (passed to Input component)")

  def field(assigns) do
    assigns =
      assigns
      |> normalize_field_props()
      |> generate_label_if_missing()
      |> extract_field_errors()
      |> generate_aria_ids()
      |> assign(:error_message_classes, @error_message_classes)
      |> assign(:field_wrapper_base_classes, @field_wrapper_base_classes)
      |> assign(:label_section_classes, @label_section_classes)

    ~H"""
    <div class={merge([@field_wrapper_base_classes, @class])}>
      <!-- Label Section -->
      <div :if={has_label?(@label, @type)} class={@label_section_classes}>
        <Label.label
          for={get_label_for(@field_id, @type)}
          id={get_label_id(@field_id, @type)}
          required={@required}
          error={@has_errors}
          size={get_label_size(@label, @size)}
          class={get_label_class(@label)}
        >
          <%= if @label != [] do %>
            {render_slot(@label)}
          <% else %>
            {@generated_label}
          <% end %>
        </Label.label>

        <div
          :if={@description != []}
          id={@description_id}
          class={
            merge([
              get_description_color_class(@has_errors, @color),
              get_description_class(@description)
            ])
          }
        >
          {render_slot(@description)}
        </div>
      </div>
      
    <!-- Input Section -->
      {render_input(assigns)}
      
    <!-- Error Section -->
      <div :if={@has_errors} class="flex flex-col gap-1" aria-live="polite">
        <p
          :for={{error, index} <- Enum.with_index(@field_errors)}
          id={Enum.at(@error_ids, index)}
          class={@error_message_classes}
        >
          <Icon.icon name="hero-exclamation-circle" size="sm" color="current" class="flex-shrink-0" />
          {error}
        </p>
      </div>
    </div>
    """
  end

  # ============================================================================
  # INPUT RENDERING FUNCTIONS
  # ============================================================================

  # Renders the appropriate input component based on type
  defp render_input(%{type: "select"} = assigns) do
    ~H"""
    <Select.select
      field={@field}
      id={@field_id}
      name={@field_name}
      value={@field_value}
      options={@options || []}
      prompt={@prompt}
      multiple={@multiple}
      variant={@variant}
      color={@color}
      size={@size}
      required={@required}
      disabled={@disabled}
      invalid={@has_errors}
      aria-describedby={@aria_describedby}
      {@rest}
    />
    """
  end

  defp render_input(%{type: "textarea"} = assigns) do
    ~H"""
    <Textarea.textarea
      field={@field}
      id={@field_id}
      name={@field_name}
      value={@field_value}
      rows={@rows}
      placeholder={@placeholder}
      variant={@variant}
      color={@color}
      size={@size}
      required={@required}
      disabled={@disabled}
      readonly={@readonly}
      invalid={@has_errors}
      aria-describedby={@aria_describedby}
      {@rest}
    />
    """
  end

  defp render_input(%{type: "checkbox"} = assigns) do
    ~H"""
    <label for={@field_id} class="inline-flex items-center gap-2 cursor-pointer">
      <Checkbox.checkbox
        field={@field}
        id={@field_id}
        name={@field_name}
        value={@field_value}
        checked={@checked}
        variant={@variant}
        color={@color}
        size={@size}
        required={@required}
        disabled={@disabled}
        invalid={@has_errors}
        aria-describedby={@aria_describedby}
        {@rest}
      />
      <span class={get_inline_label_classes(@size, @has_errors, @color, get_label_class(@label))}>
        <%= if @label != [] do %>
          {render_slot(@label)}
        <% else %>
          {@generated_label}
        <% end %>
      </span>
    </label>
    """
  end

  defp render_input(%{type: "switch"} = assigns) do
    ~H"""
    <label for={@field_id} class="inline-flex items-center gap-2 cursor-pointer">
      <div class="flex items-center">
        <Switch.switch
          field={@field}
          id={@field_id}
          name={@field_name}
          value={@field_value}
          checked={@checked}
          variant={@variant}
          color={@color}
          size={@size}
          required={@required}
          disabled={@disabled}
          invalid={@has_errors}
          aria-describedby={@aria_describedby}
          {@rest}
        />
      </div>
      <span class={get_inline_label_classes(@size, @has_errors, @color, get_label_class(@label))}>
        <%= if @label != [] do %>
          {render_slot(@label)}
        <% else %>
          {@generated_label}
        <% end %>
      </span>
    </label>
    """
  end

  defp render_input(%{type: "radio"} = assigns) do
    ~H"""
    <RadioGroup.radio_group
      field={@field}
      id={@field_id}
      name={@field_name}
      value={@field_value}
      variant={@variant}
      color={@color}
      size={@size}
      required={@required}
      disabled={@disabled}
      invalid={@has_errors}
      aria-labelledby={has_label?(@label, @type) && @label_id}
      aria-describedby={@aria_describedby}
      {@rest}
    >
      <:option :for={{label, value} <- @options || []} value={value}>{label}</:option>
    </RadioGroup.radio_group>
    """
  end

  # Default case: render as Input component (text, email, password, number, etc.)
  defp render_input(assigns) do
    # Build HTML attributes for the Input component
    html_attrs = assigns.rest
    html_attrs = if assigns[:min], do: Map.put(html_attrs, :min, assigns.min), else: html_attrs
    html_attrs = if assigns[:max], do: Map.put(html_attrs, :max, assigns.max), else: html_attrs
    html_attrs = if assigns[:step], do: Map.put(html_attrs, :step, assigns.step), else: html_attrs
    html_attrs = if assigns[:pattern], do: Map.put(html_attrs, :pattern, assigns.pattern), else: html_attrs

    html_attrs =
      if assigns[:autocomplete], do: Map.put(html_attrs, :autocomplete, assigns.autocomplete), else: html_attrs

    assigns = assign(assigns, :html_attrs, html_attrs)

    ~H"""
    <Input.input
      field={@field}
      type={@type}
      id={@field_id}
      name={@field_name}
      value={@field_value}
      placeholder={@placeholder}
      variant={@variant}
      color={@color}
      size={@size}
      required={@required}
      disabled={@disabled}
      readonly={@readonly}
      invalid={@has_errors}
      aria-describedby={@aria_describedby}
      {@html_attrs}
    >
      <:start_decorator :if={@start_decorator != []}>
        {render_slot(@start_decorator)}
      </:start_decorator>
      <:end_decorator :if={@end_decorator != []}>
        {render_slot(@end_decorator)}
      </:end_decorator>
    </Input.input>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # Generates ARIA-related IDs for accessibility
  defp generate_aria_ids(assigns) do
    label_id = "#{assigns.field_id}-label"
    description_id = if assigns.description != [], do: "#{assigns.field_id}-description"

    error_ids =
      if assigns.has_errors do
        Enum.with_index(assigns.field_errors)
        |> Enum.map(fn {_, index} -> "#{assigns.field_id}-error-#{index}" end)
      else
        []
      end

    # Build aria-describedby from available elements
    describedby_ids = [description_id | error_ids] |> Enum.filter(& &1) |> Enum.join(" ")
    aria_describedby = if describedby_ids != "", do: describedby_ids

    assigns
    |> assign(:label_id, label_id)
    |> assign(:description_id, description_id)
    |> assign(:error_ids, error_ids)
    |> assign(:aria_describedby, aria_describedby)
  end

  # Gets the correct 'for' attribute for labels based on input type
  # Radio groups don't use 'for' since they're containers, not focusable elements
  defp get_label_for(field_id, type) do
    if type != "radio", do: field_id
  end

  # Gets the correct 'id' attribute for labels
  # Radio groups need an ID for aria-labelledby association
  defp get_label_id(field_id, type) do
    if type == "radio", do: "#{field_id}-label"
  end

  # Normalizes field properties from Phoenix.HTML.FormField
  defp normalize_field_props(assigns) do
    field = assigns.field

    field_id = assigns[:id] || field.id || Form.input_id(field.form, field.field)
    field_name = assigns[:name] || field.name || Form.input_name(field.form, field.field)
    field_value = assigns[:value] || field.value

    assigns
    |> assign(:field_id, field_id)
    |> assign(:field_name, field_name)
    |> assign(:field_value, field_value)
  end

  # Generates a human-readable label from field name if no label slot provided
  defp generate_label_if_missing(assigns) do
    if assigns[:label] == [] do
      generated_label = Phoenix.Naming.humanize(assigns.field.field)

      assign(assigns, :generated_label, generated_label)
    else
      assign(assigns, :generated_label, nil)
    end
  end

  # Extracts errors from the Phoenix form field
  defp extract_field_errors(assigns) do
    field = assigns.field
    show_errors = assigns.show_errors

    field_errors =
      case show_errors do
        :never ->
          []

        :always ->
          if field && field.errors, do: Enum.map(field.errors, &translate_error/1), else: []

        :touched ->
          if field && field.errors && Phoenix.Component.used_input?(field) do
            Enum.map(field.errors, &translate_error/1)
          else
            []
          end
      end

    assigns
    |> assign(:field_errors, field_errors)
    |> assign(:has_errors, not Enum.empty?(field_errors))
  end

  # Determines if label should be displayed separately (above input) based on type
  defp has_label?(_label_slot, type) do
    # Show separate label for most types, but not for checkbox/switch which use inline labels
    type not in ~w(checkbox switch)
  end

  # Gets label size from slot attribute or falls back to field size
  defp get_label_size(label_slot, field_size) do
    case label_slot do
      [%{size: size}] when size != nil -> size
      _ -> field_size
    end
  end

  # Gets label class from slot attribute
  defp get_label_class(label_slot) do
    case label_slot do
      [%{class: class}] when class != nil -> class
      _ -> ""
    end
  end

  # Gets description class from slot attribute
  defp get_description_class(description_slot) do
    case description_slot do
      [%{class: class}] when class != nil -> class
      _ -> ""
    end
  end

  # Gets description color classes based on error state and field color
  defp get_description_color_class(has_errors, color) do
    effective_color = if has_errors, do: "danger", else: color
    color_class = @description_colors[effective_color] || @description_colors["neutral"]

    "text-sm #{color_class}"
  end

  # Gets inline label classes for checkbox/switch labels
  defp get_inline_label_classes(size, has_errors, color, custom_class) do
    size_class = @inline_label_sizes[size] || @inline_label_sizes["md"]
    effective_color = if has_errors, do: "danger", else: color
    color_class = @inline_label_colors[effective_color] || @inline_label_colors["neutral"]

    merge([
      @inline_label_base_classes,
      size_class,
      "leading-none",
      color_class,
      custom_class
    ])
  end

  # Simple error translation - in real apps this would use Gettext
  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp translate_error(msg) when is_binary(msg), do: msg
end
