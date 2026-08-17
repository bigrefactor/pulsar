defmodule Pulsar.DevApp.Keyboard.ComboboxLive do
  @moduledoc """
  Interaction-test fixture for `Pulsar.Components.Combobox`.

  Three comboboxes: one single-select inside a form with `phx-change`, one
  single-select standalone with no form at all, and one multi-select. Behavior
  comes from the `.PulsarCombobox` colocated hook.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Combobox

  @options [
    {"Alpha", "alpha"},
    {"Beta", "beta"},
    [key: "Gamma", value: "gamma", disabled: true],
    {"Betamax", "betamax"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(%{"owner" => ""}, as: :picked))
     |> assign(:received, "")}
  end

  def handle_event("validate", %{"picked" => %{"owner" => owner}}, socket) do
    {:noreply,
     socket
     |> assign(:received, owner)
     |> assign(:form, to_form(%{"owner" => owner}, as: :picked))}
  end

  def render(assigns) do
    assigns = assign(assigns, :options, @options)

    ~H"""
    <.fixture_page name="keyboard-combobox" title="Combobox interaction fixture">
      <.fixture_section name="form" title="Single-select inside a form">
        <.form for={@form} phx-change="validate">
          <Combobox.combobox
            id="kbd-form"
            field={@form[:owner]}
            label="Pick an owner"
            options={@options}
          />
        </.form>
        <p id="kbd-form-received">{@received}</p>
      </.fixture_section>

      <.fixture_section name="standalone" title="Single-select with no form">
        <Combobox.combobox id="kbd-solo" label="Pick a value" options={@options} />
      </.fixture_section>

      <.fixture_section name="multiple" title="Multi-select">
        <Combobox.combobox
          id="kbd-multi"
          name="tags[]"
          label="Pick tags"
          options={@options}
          multiple
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
