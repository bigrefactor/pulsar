defmodule Mix.Tasks.Pulsar.Gen.Field do
  use Pulsar.Generator,
    component: :field,
    example: "mix pulsar.gen.field",
    long_doc: """
    Generates a composable field component that wraps inputs with labels and error handling

    Creates a unified field component that automatically handles labels, descriptions,
    error messages, and input rendering based on type. Provides a consistent,
    accessible interface for all form inputs with standardized spacing and layout.

    ## Example

    ```sh
    mix pulsar.gen.field

    # With custom module namespace
    mix pulsar.gen.field --components-module=MyAppWeb.UI
    ```

    ## Features

    - Type-based rendering (automatically uses the right Pulsar component)
    - Automatic label generation from field names
    - Error integration with Phoenix forms
    - Decorator support passed through to compatible inputs
    - Consistent layout and spacing
    - Accessibility with proper label association
    - Phoenix form and changeset integration

    ## Dependencies

    This component requires: checkbox, icon, input, label, radio_group, select, switch, textarea

    ## Usage Examples

    ```elixir
    # Basic text field with auto-generated label
    <.field field={@form[:email]} type="email" />

    # Field with custom label and description
    <.field field={@form[:username]} type="text" placeholder="Choose a username">
      <:label>Username</:label>
      <:description>This will be your public display name</:description>
    </.field>

    # Field with decorators
    <.field field={@form[:price]} type="number" step="0.01">
      <:label>Price</:label>
      <:start_decorator>$</:start_decorator>
      <:end_decorator>USD</:end_decorator>
    </.field>

    # Select field
    <.field field={@form[:country]} type="select" options={@countries}>
      <:label>Country</:label>
    </.field>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
