defmodule Pulsar.Components.InputOtp do
  @moduledoc """
  A one-time-code input for 2FA / MFA flows.

  Renders a row of single-character slots backed by one form value, with
  auto-advance and paste handling. Plugs into `Pulsar.Components.Field` for
  labels, errors, and ARIA wiring.

  ## Examples

      <.input_otp field={@form[:otp]} length={6} />

      # Auto-submit when the last digit is entered
      <.input_otp field={@form[:otp]} on_complete={JS.push("verify")} />

      # Grouped, masked, alphanumeric
      <.input_otp field={@form[:code]} length={6} groups={[3, 3]} mask mode="alphanumeric" />
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a one-time-code input.
  """
  @spec input_otp(map()) :: Rendered.t()

  attr(:field, FormField, default: nil, doc: "Phoenix form field")
  attr(:id, :string, default: nil, doc: "Input ID (auto-generated if omitted)")
  attr(:name, :string, default: nil, doc: "Input name (from field if not provided)")
  attr(:value, :any, default: nil, doc: "Input value (from field if not provided)")
  attr(:length, :integer, default: 6, doc: "Number of code characters")
  attr(:rest, :global, doc: "Additional attributes for the input")

  def input_otp(assigns) do
    assigns = normalize_field_props(assigns)

    ~H"""
    <div id={@wrapper_id} class="relative inline-flex items-center">
      <input
        type="text"
        id={@id}
        name={@name}
        value={@value}
        maxlength={@length}
        autocomplete="one-time-code"
        {@rest}
      />
    </div>
    """
  end

  defp normalize_field_props(assigns) do
    field = assigns[:field]
    id = assigns[:id] || (field && field.id) || "otp-#{System.unique_integer([:positive])}"

    assigns
    |> assign(:id, id)
    |> assign(:wrapper_id, "#{id}-otp")
    |> assign(:name, assigns[:name] || (field && field.name))
    |> assign(:value, assigns[:value] || (field && field.value))
  end
end
