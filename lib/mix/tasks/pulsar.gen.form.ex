defmodule Mix.Tasks.Pulsar.Gen.Form do
  use Pulsar.Generator,
    component: :form,
    example: "mix pulsar.gen.form",
    long_doc: """
    Generates a form wrapper component with focus-on-error a11y behavior

    Wraps Phoenix's `<.form>` with a colocated hook that, after a failed
    form submission, moves keyboard focus to the first input with
    `aria-invalid="true"`. Implements the Phoenix form-error UX
    convention without requiring app-level JavaScript wiring.

    ## Example

    ```sh
    mix pulsar.gen.form

    # With custom module namespace
    mix pulsar.gen.form --components-module=MyAppWeb.UI
    ```

    ## Usage Examples

    ```elixir
    <.form
      :let={f}
      for={@form}
      phx-change="validate"
      phx-submit="submit"
    >
      <.field field={f[:name]} type="text">
        <:label>Name</:label>
      </.field>
    </.form>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
