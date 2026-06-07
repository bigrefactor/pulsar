defmodule Mix.Tasks.Pulsar.Gen.InputOtp do
  use Pulsar.Generator,
    component: :input_otp,
    example: "mix pulsar.gen.input_otp",
    long_doc: """
    Generates a one-time-code input for 2FA / MFA flows.

    Creates an accessible OTP input rendered as a row of single-character slots
    backed by one form value, with auto-advance, paste handling, and SMS /
    password-manager autofill. Plugs into the `field` wrapper as `type="otp"`.

    ## Example

    ```sh
    mix pulsar.gen.input_otp

    # With custom module namespace
    mix pulsar.gen.input_otp --components-module=MyAppWeb.UI
    ```

    ## Features

    - Variants: outline (default), solid, ghost
    - Configurable length and optional grouping with a separator
    - Numeric or alphanumeric character sets, optional masking
    - on_complete callback for auto-submitting a verification form
    - Single accessible input with one-time-code autofill; dark mode support

    ## Usage Examples

    ```elixir
    <.input_otp field={@form[:otp]} length={6} />
    <.field field={@form[:otp]} type="otp" length={6}>
      <:label>Verification code</:label>
    </.field>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
